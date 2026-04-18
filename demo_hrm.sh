#!/bin/bash
# =============================================================
#  demo_hrm.sh — Bản Demo HRM nhỏ gọn dùng pipeline_common.sh
# =============================================================
set -e
source "$(dirname "$0")/pipeline_common.sh" # Gọi bộ khung dùng chung

# 1. Cấu hình nhanh cho bản Demo
PROJECT="hrm_demo"
BUCKET="hrm-demo-bucket"
CATALOG="hrm_demo_catalog"
NAMESPACE="db_demo"

echo ">>> [STEP 1] Chuẩn bị môi trường..."
common::download_jars
common::copy_jars_to_flink
common::cleanup_debezium_connectors "hrm-demo" || true
common::cleanup_minio "$BUCKET" || true

echo ">>> [STEP 2] Khởi tạo Postgres Demo..."
docker exec -i postgres psql -U root -d postgres -c "DROP DATABASE IF EXISTS hrm_demo; CREATE DATABASE hrm_demo;"
docker exec -i postgres psql -U root -d hrm_demo <<'SQLEOF'
  CREATE TABLE employees (id INT PRIMARY KEY, name VARCHAR(100), salary NUMERIC(15,2));
  INSERT INTO employees VALUES (1, 'Demo User 1', 15000000), (2, 'Demo User 2', 18000000);
SQLEOF

echo ">>> [STEP 3] Đăng ký Debezium (Dùng hàm trong common)..."
DEBEZIUM_JSON='{
  "name": "hrm-demo-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.user": "root",
    "database.password": "123",
    "database.dbname": "hrm_demo",
    "topic.prefix": "hrm_demo",
    "plugin.name": "pgoutput",
    "decimal.handling.mode": "double"
  }
}'
common::register_debezium "$DEBEZIUM_JSON"

echo ">>> [STEP 4] Thiết lập Polaris & Trino..."
common::get_polaris_token
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" "8282"

echo ">>> [STEP 5] Chạy Flink SQL (Hút dữ liệu thực tế)..."
# Chỗ này bạn nạp script Flink SQL đơn giản để demo
cat > /tmp/demo_flink.sql << EOF
CREATE CATALOG ${CATALOG} WITH (
  'type'='iceberg', 'uri'='http://polaris:8181/api/catalog', 'credential'='${CREDENTIAL}', 
  'warehouse'='${CATALOG}', 's3.endpoint'='http://minio:9000', 's3.access-key-id'='admin', 's3.secret-access-key'='password'
);
USE CATALOG ${CATALOG};
CREATE DATABASE IF NOT EXISTS ${NAMESPACE};
CREATE TABLE IF NOT EXISTS ${NAMESPACE}.employees (id INT, name STRING, salary DOUBLE, PRIMARY KEY (id) NOT ENFORCED) WITH ('format-version'='2');

USE CATALOG default_catalog;
CREATE TABLE employees_k (id INT, name STRING, salary DOUBLE, PRIMARY KEY (id) NOT ENFORCED) WITH ('connector'='kafka','topic'='hrm_demo.public.employees','properties.bootstrap.servers'='kafka:9092','format'='debezium-json');
INSERT INTO ${CATALOG}.${NAMESPACE}.employees SELECT * FROM employees_k;
EOF

common::submit_flink_sql /tmp/demo_flink.sql

echo "✅ Bản Demo HRM đã khởi chạy thành công!"
echo "👉 Truy vấn tại Trino: SELECT * FROM minio.${NAMESPACE}.employees"
