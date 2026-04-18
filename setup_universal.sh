#!/bin/bash
# =============================================================
#  setup_universal.sh — Hệ thống Pipeline HRM Vạn Năng (FULL)
#  Hỗ trợ: MySQL, Postgres
#  Logic: Tính lương, bảo hiểm, thuế, đi muộn, analytics...
# =============================================================
set -e
export PG_PWD=123

source "$(dirname "$0")/pipeline_common.sh"

DB_TYPE=$1
if [ -z "$DB_TYPE" ]; then
    echo "❌ Lỗi: Thiếu tham số DB_TYPE. Sử dụng: $0 [mysql|postgres]"
    exit 1
fi

# ─── [1] CẤU HÌNH BIẾN ĐỘNG ──────────────────────────────────
PROJECT="hrm${DB_TYPE}"
BUCKET="hrm${DB_TYPE}"
CATALOG="catalog${DB_TYPE}"
NAMESPACE="db_${DB_TYPE}"

case "$DB_TYPE" in
  "mysql")
    CONNECTOR_CLASS="io.debezium.connector.mysql.MySqlConnector"
    DB_HOST="mysql"; DB_PORT=3306; DB_USER="root"; DB_PASS="123"; DB_NAME="hrm"
    TOPIC_PREFIX="hrm_mysql"
    TABLE_LIST="hrm.employees,hrm.attendance,hrm.leave_requests,hrm.payroll"
    ;;
  "postgres")
    CONNECTOR_CLASS="io.debezium.connector.postgresql.PostgresConnector"
    DB_HOST="postgres"; DB_PORT=5432; DB_USER="root"; DB_PASS="123"; DB_NAME="hrm"
    TOPIC_PREFIX="hrm_pg"
    TABLE_LIST="public.employees,public.attendance,public.leave_requests,public.payroll"
    ;;
  *)
    echo "❌ Lỗi: DB_TYPE '$DB_TYPE' chưa được hỗ trợ!"
    exit 1
    ;;
esac

echo "============================================"
echo "  🚀 UNIVERSAL PIPELINE (FULL): $DB_TYPE"
echo "============================================"

# ─── [2] DỌN DẸP & JARs ──────────────────────────────────────
common::download_jars
common::copy_jars_to_flink
common::cleanup_debezium_connectors "hrm-universal" || true
common::cleanup_flink_jobs || true
common::cleanup_minio "$BUCKET" || true

# ─── [3] KHỞI TẠO DATA MẪU (FULL 4 BẢNG) ─────────────────────
echo ">>> [3] Khoi tao database mâu cho $DB_TYPE..."
if [ "$DB_TYPE" == "postgres" ]; then
  docker exec -i postgres psql -U root -d postgres -c "SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots WHERE database = 'hrm';" || true
  docker exec -i postgres psql -U root -d postgres -c "DROP DATABASE IF EXISTS hrm; CREATE DATABASE hrm;"
  docker exec -i postgres psql -U root -d hrm <<'SQLEOF'
    CREATE TABLE employees (emp_id INT PRIMARY KEY, name VARCHAR(100), department VARCHAR(100), salary NUMERIC(15,2));
    CREATE TABLE attendance (id SERIAL PRIMARY KEY, emp_id INT, check_in TIMESTAMP, check_out TIMESTAMP, status VARCHAR(50));
    CREATE TABLE leave_requests (id SERIAL PRIMARY KEY, emp_id INT, leave_type VARCHAR(50), start_date DATE, end_date DATE, days INT, status VARCHAR(20), reason VARCHAR(200));
    CREATE TABLE payroll (id SERIAL PRIMARY KEY, emp_id INT, month VARCHAR(7), base_salary NUMERIC(15,2), deduction NUMERIC(15,2), bonus NUMERIC(15,2), net_salary NUMERIC(15,2));
    
    INSERT INTO employees VALUES (1,'Nguyen Van A','Engineering',25000000),(2,'Tran Thi B','Marketing',20000000);
    INSERT INTO attendance (emp_id, check_in, check_out, status) VALUES (1,'2026-04-01 08:00:00','2026-04-01 17:00:00','ON_TIME'),(2,'2026-04-01 09:15:00','2026-04-01 18:00:00','LATE');
    INSERT INTO leave_requests (emp_id, leave_type, start_date, end_date, days, status) VALUES (1,'annual','2026-04-10','2026-04-12',3,'approved');
    INSERT INTO payroll (emp_id, month, base_salary, deduction, bonus, net_salary) VALUES (1,'2026-04',25000000,0,500000,25500000),(2,'2026-04',20000000,250000,0,19750000);
SQLEOF
elif [ "$DB_TYPE" == "mysql" ]; then
  docker exec -i mysql mysql -uroot -p123 -e "DROP DATABASE IF EXISTS hrm; CREATE DATABASE hrm;"
  docker exec -i mysql mysql -uroot -p123 hrm <<'SQLEOF'
    CREATE TABLE employees (emp_id INT PRIMARY KEY, name VARCHAR(100), department VARCHAR(100), salary DECIMAL(15,2));
    CREATE TABLE attendance (id INT AUTO_INCREMENT PRIMARY KEY, emp_id INT, check_in DATETIME, check_out DATETIME, status VARCHAR(50));
    CREATE TABLE leave_requests (id INT AUTO_INCREMENT PRIMARY KEY, emp_id INT, leave_type VARCHAR(50), start_date DATE, end_date DATE, days INT, status VARCHAR(20), reason VARCHAR(200));
    CREATE TABLE payroll (id INT AUTO_INCREMENT PRIMARY KEY, emp_id INT, month VARCHAR(7), base_salary DECIMAL(15,2), deduction DECIMAL(15,2), bonus DECIMAL(15,2), net_salary DECIMAL(15,2));
    
    INSERT INTO employees VALUES (1,'Nguyen Van A','Engineering',25000000),(2,'Tran Thi B','Marketing',20000000);
    INSERT INTO attendance (emp_id, check_in, check_out, status) VALUES (1,'2026-04-01 08:00:00','2026-04-01 17:00:00','ON_TIME'),(2,'2026-04-01 09:15:00','2026-04-01 18:00:00','LATE');
    INSERT INTO leave_requests (emp_id, leave_type, start_date, end_date, days, status) VALUES (1,'annual','2026-04-10','2026-04-12',3,'approved');
    INSERT INTO payroll (emp_id, month, base_salary, deduction, bonus, net_salary) VALUES (1,'2026-04',25000000,0,500000,25500000),(2,'2026-04',20000000,250000,0,19750000);
SQLEOF
fi

# ─── [4] ĐĂNG KÝ DEBEZIUM ────────────────────────────────────
DEBEZIUM_JSON="{
  \"name\": \"hrm-universal-connector-$(date +%s)\",
  \"config\": {
    \"connector.class\": \"$CONNECTOR_CLASS\",
    \"database.hostname\": \"$DB_HOST\", \"database.port\": \"$DB_PORT\",
    \"database.user\": \"$DB_USER\", \"database.password\": \"$DB_PASS\",
    \"database.dbname\": \"$DB_NAME\", \"database.server.id\": \"$(shuf -i 1000-9999 -n 1)\",
    \"topic.prefix\": \"$TOPIC_PREFIX\",
    \"table.include.list\": \"$TABLE_LIST\",
    \"decimal.handling.mode\": \"double\",
    \"plugin.name\": \"pgoutput\",
    \"snapshot.mode\": \"initial\"
  }
}"
common::register_debezium "$DEBEZIUM_JSON"

# ─── [5] POLARIS & TRINO TOKEN ──────────────────────────────
common::get_polaris_token
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" "8282"

# ─── [6] FLINK SQL PIPELINE (FULL COMPLEX LOGIC) ─────────────
echo ">>> [6] Submit Flink SQL pipeline..."
cat > /tmp/universal_pipeline.sql << EOF
SET 'table.exec.sink.upsert-materialize' = 'AUTO';

CREATE CATALOG ${CATALOG} WITH (
  'type'='iceberg','catalog-impl'='org.apache.iceberg.rest.RESTCatalog','uri'='http://polaris:8181/api/catalog','credential'='${CREDENTIAL}','warehouse'='${CATALOG}',
  'io-impl'='org.apache.iceberg.aws.s3.S3FileIO','s3.endpoint'='http://minio:9000','s3.region'='us-east-1','s3.path-style-access'='true','s3.access-key-id'='admin','s3.secret-access-key'='password'
);

USE CATALOG ${CATALOG};
CREATE DATABASE IF NOT EXISTS ${NAMESPACE};

-- Bảng Iceberg Chuẩn Hóa
CREATE TABLE IF NOT EXISTS ${NAMESPACE}.employees (emp_id INT, name STRING, department STRING, salary DOUBLE, PRIMARY KEY (emp_id) NOT ENFORCED) WITH ('write.upsert.enabled'='true','format-version'='2');
CREATE TABLE IF NOT EXISTS ${NAMESPACE}.attendance_analytics (id INT, emp_id INT, check_in BIGINT, check_out BIGINT, work_hours DOUBLE, status STRING, is_late BOOLEAN, PRIMARY KEY (id) NOT ENFORCED) WITH ('write.upsert.enabled'='true','format-version'='2');
CREATE TABLE IF NOT EXISTS ${NAMESPACE}.payroll_analytics (id INT, emp_id INT, \`month\` STRING, net_salary DOUBLE, insurance_amt DOUBLE, tax_amount DOUBLE, take_home DOUBLE, PRIMARY KEY (id) NOT ENFORCED) WITH ('write.upsert.enabled'='true','format-version'='2');

USE CATALOG default_catalog;
-- Kafka Sources (Động theo TOPIC_PREFIX)
CREATE TABLE employees_k (emp_id INT, name STRING, department STRING, salary DOUBLE, PRIMARY KEY (emp_id) NOT ENFORCED) WITH ('connector'='kafka','topic'='${TOPIC_PREFIX}.$( [ "$DB_TYPE" == "postgres" ] && echo "public" || echo "hrm" ).employees','properties.bootstrap.servers'='kafka:9092','format'='debezium-json');
CREATE TABLE attendance_k (id INT, emp_id INT, check_in BIGINT, check_out BIGINT, status STRING, PRIMARY KEY (id) NOT ENFORCED) WITH ('connector'='kafka','topic'='${TOPIC_PREFIX}.$( [ "$DB_TYPE" == "postgres" ] && echo "public" || echo "hrm" ).attendance','properties.bootstrap.servers'='kafka:9092','format'='debezium-json');
CREATE TABLE payroll_k (id INT, emp_id INT, \`month\` STRING, net_salary DOUBLE, base_salary DOUBLE, PRIMARY KEY (id) NOT ENFORCED) WITH ('connector'='kafka','topic'='${TOPIC_PREFIX}.$( [ "$DB_TYPE" == "postgres" ] && echo "public" || echo "hrm" ).payroll','properties.bootstrap.servers'='kafka:9092','format'='debezium-json');

-- Transformations
INSERT INTO ${CATALOG}.${NAMESPACE}.employees SELECT * FROM employees_k;

INSERT INTO ${CATALOG}.${NAMESPACE}.attendance_analytics
SELECT id, emp_id, check_in, check_out,
  CAST((check_out - check_in) / 3600000.0 AS DOUBLE),
  status,
  CASE WHEN ((check_in + 25200000) % 86400000) > 32400000 THEN TRUE ELSE FALSE END
FROM attendance_k;

INSERT INTO ${CATALOG}.${NAMESPACE}.payroll_analytics
SELECT id, emp_id, \`month\`, net_salary,
  CAST(base_salary * 0.105 AS DOUBLE),
  CASE WHEN net_salary > 11000000 THEN (net_salary - 11000000) * 0.05 ELSE 0.0 END,
  net_salary - (base_salary * 0.105) - (CASE WHEN net_salary > 11000000 THEN (net_salary - 11000000) * 0.05 ELSE 0.0 END)
FROM payroll_k;
EOF
common::submit_flink_sql /tmp/universal_pipeline.sql

# ─── [7] TRINO VIEWS ──────────────────────────────────────────
echo ">>> [7] Cho Flink (60s)..."
sleep 60
docker exec trino trino --execute "
CREATE SCHEMA IF NOT EXISTS minio.${NAMESPACE};
CREATE VIEW IF NOT EXISTS minio.${NAMESPACE}.late_ranking AS
SELECT e.name, e.department, COUNT(*) as late_days
FROM minio.${NAMESPACE}.attendance_analytics a
JOIN minio.${NAMESPACE}.employees e ON a.emp_id = e.emp_id
WHERE a.is_late = TRUE
GROUP BY e.name, e.department;

CREATE VIEW IF NOT EXISTS minio.${NAMESPACE}.payroll_summary AS
SELECT e.department, ROUND(AVG(p.take_home), 0) as avg_income
FROM minio.${NAMESPACE}.payroll_analytics p
JOIN minio.${NAMESPACE}.employees e ON p.emp_id = e.emp_id
GROUP BY e.department;
" && echo "✅ Trino Analytics đã sẵn sàng!" || echo "⚠️ Trino View error (Chờ dữ liệu...)"

echo "============================================"
echo "  ✅ PIPELINE VẠN NĂNG ($DB_TYPE) HOÀN TẤT!"
echo "============================================"
