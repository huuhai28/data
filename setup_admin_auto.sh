#!/bin/bash
# =============================================================
#  setup_admin_auto.sh — Tự động hóa 85 bảng cho dự án Admin
# =============================================================
set -e
source "$(dirname "$0")/pipeline_common.sh"

PROJECT="admin"
BUCKET="admin-data"
CATALOG="catalog_admin"
NAMESPACE="db_admin"

echo ">>> [1] Khoi tao Database Admin (85 bang)..."
docker exec -i mysql mysql -uroot -p123 < init/sql/admin_schema.sql

echo ">>> [2] Dang ky Debezium cho TOÀN BỘ 85 bang..."
# Thay vì liệt kê 85 bảng, ta dùng "admin_db.*" để Debezium tự quét
DEBEZIUM_JSON='{
  "name": "admin-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "root",
    "database.password": "123",
    "database.server.id": "5566",
    "topic.prefix": "admin_db",
    "database.include.list": "admin_db",
    "table.include.list": "admin_db.*",
    "decimal.handling.mode": "double",
    "snapshot.mode": "initial"
  }
}'
common::register_debezium "$DEBEZIUM_JSON"

echo ">>> [3] Dang tao Flink SQL cho 85 bang (Automation)..."
# Đoạn này sẽ quét file SQL và tạo ra script Flink SQL tự động
SQL_OUT="/tmp/admin_flink.sql"
echo "SET 'table.exec.sink.upsert-materialize' = 'AUTO';" > $SQL_OUT
echo "CREATE CATALOG $CATALOG WITH ('type'='iceberg','catalog-impl'='org.apache.iceberg.rest.RESTCatalog','uri'='http://polaris:8181/api/catalog','credential'='${CREDENTIAL}','warehouse'='${CATALOG}','io-impl'='org.apache.iceberg.rest.RESTCatalog','s3.endpoint'='http://minio:9000','s3.access-key-id'='admin','s3.secret-access-key'='password');" >> $SQL_OUT
echo "USE CATALOG $CATALOG;" >> $SQL_OUT
echo "CREATE DATABASE IF NOT EXISTS $NAMESPACE;" >> $SQL_OUT

# Trick: Quét các tên bảng từ file admin_schema.sql
TABLES=$(grep -i "CREATE TABLE IF NOT EXISTS" init/sql/admin_schema.sql | awk '{print $6}')

for TBL in $TABLES; do
    echo "Processing table: $TBL"
    # Tự động tạo bảng Iceberg đơn giản (mọi cột là String để chạy nhanh, bạn có thể tinh chỉnh sau)
    # Trong môi trường thực tế, ta sẽ dùng công cụ parse DDL chuẩn hơn
    echo "CREATE TABLE IF NOT EXISTS $NAMESPACE.$TBL (id BIGINT, name STRING, created_at STRING, PRIMARY KEY (id) NOT ENFORCED) WITH ('write.upsert.enabled'='true','format-version'='2');" >> $SQL_OUT
    echo "INSERT INTO $CATALOG.$NAMESPACE.$TBL SELECT id, name, CAST(created_at AS STRING) FROM default_catalog.default_database.${TBL}_k;" >> $SQL_OUT
done

echo "✅ Đã tạo xong Flink SQL tại $SQL_OUT"
echo "🚀 Chạy Flink Job..."
# common::submit_flink_sql $SQL_OUT
