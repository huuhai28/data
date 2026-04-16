#!/bin/bash
# =============================================================
#  setup_hrm.sh — HRM Pipeline (dùng pipeline_common.sh)
#  MySQL → Debezium → Kafka → Flink → Iceberg (Polaris) → Trino
#
#  Phần đặc thù HRM:
#    - MySQL schema: employees, attendance, leave_requests, payroll
#    - Debezium: capture 4 bang tren
#    - Flink SQL: 4 Iceberg sinks
#    - Trino: 5 analytics views (attendance_summary, department_stats,
#             late_ranking, leave_analysis, payroll_summary)
# =============================================================
set -e
export MYSQL_PWD=123

source "$(dirname "$0")/pipeline_common.sh"

PROJECT="hrm"
BUCKET="hrm"
CATALOG="hrm"
NAMESPACE="db_hrm"

echo "============================================"
echo "  HRM Pipeline: Cham cong Realtime"
echo "============================================"
echo ""

# ─── [1] JARs ─────────────────────────────────────────────────
common::download_jars
common::copy_jars_to_flink

# ─── [2] MYSQL SCHEMA + DATA ──────────────────────────────────
echo ">>> [2] Tao schema & seed data MySQL..."
common::wait_for_mysql

set +e
docker exec -i mysql mysql -uroot -p123 \
  --default-character-set=utf8mb4 \
  --init-command="SET NAMES utf8mb4" <<'SQLEOF'
CREATE DATABASE IF NOT EXISTS hrm;
USE hrm;

CREATE TABLE IF NOT EXISTS employees (
  emp_id     INT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  department VARCHAR(100) NOT NULL,
  salary     DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS attendance (
  id        INT PRIMARY KEY AUTO_INCREMENT,
  emp_id    INT NOT NULL,
  check_in  DATETIME,
  check_out DATETIME,
  status    VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS leave_requests (
  id         INT PRIMARY KEY AUTO_INCREMENT,
  emp_id     INT NOT NULL,
  leave_type VARCHAR(50),
  start_date DATE,
  end_date   DATE,
  days       INT,
  status     VARCHAR(20),
  reason     VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS payroll (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  emp_id      INT NOT NULL,
  month       VARCHAR(7),
  base_salary DECIMAL(12,2),
  deduction   DECIMAL(12,2),
  bonus       DECIMAL(12,2),
  net_salary  DECIMAL(12,2)
);

INSERT INTO employees VALUES
  (1,  'Nguyen Van A', 'Engineering', 25000000),
  (2,  'Tran Thi B',   'Marketing',   20000000),
  (3,  'Le Van C',     'Engineering', 28000000),
  (4,  'Pham Thi D',   'HR',          18000000),
  (5,  'Hoang Van E',  'Engineering', 30000000),
  (6,  'Nguyen Van F', 'HR',          22000000),
  (7,  'Tran Van G',   'Engineering', 27000000),
  (8,  'Le Thi H',     'Marketing',   21000000),
  (9,  'Pham Van I',   'Finance',     26000000),
  (10, 'Hoang Thi K',  'Engineering', 29000000)
ON DUPLICATE KEY UPDATE name=VALUES(name), department=VALUES(department), salary=VALUES(salary);

TRUNCATE TABLE attendance;
INSERT INTO attendance (emp_id, check_in, check_out, status) VALUES
  (1,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (2,  '2026-04-01 09:10:00', '2026-04-01 18:00:00', 'LATE'),
  (3,  '2026-04-01 08:05:00', '2026-04-01 17:30:00', 'ON_TIME'),
  (4,  '2026-04-01 08:20:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (5,  '2026-04-01 09:30:00', '2026-04-01 18:10:00', 'LATE'),
  (6,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (7,  '2026-04-01 08:15:00', '2026-04-01 16:30:00', 'EARLY_LEAVE'),
  (8,  '2026-04-01 09:00:00', '2026-04-01 18:00:00', 'LATE'),
  (9,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (10, '2026-04-01 08:40:00', '2026-04-01 17:30:00', 'ON_TIME'),

  (1,  '2026-04-02 08:10:00', '2026-04-02 17:10:00', 'ON_TIME'),
  (2,  '2026-04-02 09:20:00', '2026-04-02 18:00:00', 'LATE'),
  (3,  '2026-04-02 08:00:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (4,  '2026-04-02 08:25:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (5,  '2026-04-02 09:10:00', '2026-04-02 18:00:00', 'LATE'),
  (6,  '2026-04-02 08:05:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (7,  '2026-04-02 08:30:00', '2026-04-02 16:45:00', 'EARLY_LEAVE'),
  (8,  '2026-04-02 09:15:00', '2026-04-02 18:20:00', 'LATE'),
  (9,  '2026-04-02 08:00:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (10, '2026-04-02 08:50:00', '2026-04-02 17:40:00', 'ON_TIME'),

  (1,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (2,  '2026-04-03 09:30:00', '2026-04-03 18:10:00', 'LATE'),
  (3,  '2026-04-03 08:10:00', '2026-04-03 17:20:00', 'ON_TIME'),
  (4,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (5,  '2026-04-03 09:40:00', '2026-04-03 18:30:00', 'LATE'),
  (6,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (7,  '2026-04-03 08:20:00', '2026-04-03 16:40:00', 'EARLY_LEAVE'),
  (8,  '2026-04-03 09:25:00', '2026-04-03 18:15:00', 'LATE'),
  (9,  '2026-04-03 08:05:00', '2026-04-03 17:05:00', 'ON_TIME'),
  (10, '2026-04-03 08:45:00', '2026-04-03 17:30:00', 'ON_TIME'),

  (1,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (2,  '2026-04-04 09:15:00', '2026-04-04 18:00:00', 'LATE'),
  (3,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (4,  '2026-04-04 08:30:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (5,  '2026-04-04 09:20:00', '2026-04-04 18:10:00', 'LATE'),
  (6,  '2026-04-04 08:05:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (7,  '2026-04-04 08:25:00', '2026-04-04 16:50:00', 'EARLY_LEAVE'),
  (8,  '2026-04-04 09:35:00', '2026-04-04 18:30:00', 'LATE'),
  (9,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (10, '2026-04-04 08:55:00', '2026-04-04 17:45:00', 'ON_TIME'),

  (1,  '2026-04-05 08:10:00', '2026-04-05 17:10:00', 'ON_TIME'),
  (2,  '2026-04-05 09:25:00', '2026-04-05 18:10:00', 'LATE'),
  (3,  '2026-04-05 08:05:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (4,  '2026-04-05 08:15:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (5,  '2026-04-05 09:30:00', '2026-04-05 18:20:00', 'LATE'),
  (6,  '2026-04-05 08:00:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (7,  '2026-04-05 08:20:00', '2026-04-05 16:40:00', 'EARLY_LEAVE'),
  (8,  '2026-04-05 09:40:00', '2026-04-05 18:30:00', 'LATE'),
  (9,  '2026-04-05 08:00:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (10, '2026-04-05 08:50:00', '2026-04-05 17:30:00', 'ON_TIME')
ON DUPLICATE KEY UPDATE status=VALUES(status);

TRUNCATE TABLE leave_requests;
INSERT INTO leave_requests (emp_id, leave_type, start_date, end_date, days, status, reason) VALUES
  (1,  'annual', '2026-04-07', '2026-04-11', 5, 'pending',  'Nghi le gia dinh'),
  (2,  'sick',   '2026-04-03', '2026-04-04', 2, 'approved', 'Cam cum'),
  (3,  'sick',   '2026-04-08', '2026-04-09', 2, 'approved', 'Dau dau'),
  (4,  'annual', '2026-04-14', '2026-04-16', 3, 'approved', 'Du lich'),
  (5,  'sick',   '2026-04-02', '2026-04-02', 1, 'approved', 'Sot'),
  (6,  'sick',   '2026-04-10', '2026-04-10', 1, 'approved', 'Met moi'),
  (7,  'annual', '2026-04-21', '2026-04-22', 2, 'pending',  'Viec ca nhan'),
  (8,  'unpaid', '2026-04-15', '2026-04-15', 1, 'rejected', 'Ly do ca nhan'),
  (9,  'annual', '2026-04-14', '2026-04-16', 3, 'approved', 'Nghi duong'),
  (10, 'unpaid', '2026-04-21', '2026-04-22', 2, 'pending',  'Viec nha');

TRUNCATE TABLE payroll;
INSERT INTO payroll (emp_id, month, base_salary, deduction, bonus, net_salary) VALUES
  (1,  '2026-04', 25000000, 0,      500000, 25500000),
  (2,  '2026-04', 20000000, 250000, 0,      19750000),
  (3,  '2026-04', 28000000, 0,      500000, 28500000),
  (4,  '2026-04', 18000000, 0,      500000, 18500000),
  (5,  '2026-04', 30000000, 250000, 0,      29750000),
  (6,  '2026-04', 22000000, 0,      500000, 22500000),
  (7,  '2026-04', 27000000, 100000, 0,      26900000),
  (8,  '2026-04', 21000000, 250000, 0,      20750000),
  (9,  '2026-04', 26000000, 0,      500000, 26500000),
  (10, '2026-04', 29000000, 0,      500000, 29500000);
SQLEOF
set -e

echo "  ✅ MySQL: 4 bang hrm san sang (employees, attendance, leave_requests, payroll)."
echo ""

# ─── [3] POLARIS TOKEN ────────────────────────────────────────
common::get_polaris_token

# ─── [4] CLEANUP ──────────────────────────────────────────────
echo ">>> [4] Don dep data cu..."
common::cleanup_flink_jobs
common::cleanup_kafka_topics \
  "hrm.hrm.employees" "hrm.hrm.attendance" \
  "hrm.hrm.leave_requests" "hrm.hrm.payroll"
common::cleanup_schema_history "$PROJECT"
common::cleanup_iceberg_tables "$TOKEN" "$CATALOG" "$NAMESPACE" \
  "employees" "attendance_analytics" "leave_requests" "payroll"
common::cleanup_minio "$BUCKET"
common::cleanup_debezium_connectors "hrm-connector"
echo "  ✅ Don dep xong."
echo ""

# ─── [5] DEBEZIUM ─────────────────────────────────────────────
echo ">>> [5] Dang ky Debezium connector..."

DEBEZIUM_JSON='{
  "name": "hrm-connector-__ID__",
  "config": {
    "connector.class":  "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max":        "1",
    "database.hostname": "mysql",
    "database.port":    "3306",
    "database.user":    "root",
    "database.password": "123",
    "database.server.id": "__ID__",
    "snapshot.mode":    "initial",
    "topic.prefix":     "hrm",
    "database.include.list": "hrm",
    "table.include.list": "hrm.employees,hrm.attendance,hrm.leave_requests,hrm.payroll",
    "decimal.handling.mode": "double",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "schemahistory.hrm.__ID__"
  }
}'

common::register_debezium "$DEBEZIUM_JSON"
common::wait_for_kafka_topic "hrm.hrm.employees"

# ─── [6] POLARIS CATALOG + TRINO ──────────────────────────────
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" "8282"

# ─── [7] FLINK SQL ────────────────────────────────────────────
echo ">>> [7] Submit Flink SQL pipeline..."

cat > /tmp/hrm_pipeline.sql << EOF
SET 'execution.checkpointing.interval' = '60s';
SET 'table.exec.sink.upsert-materialize' = 'AUTO';

DROP CATALOG IF EXISTS hrm_catalog;
CREATE CATALOG hrm_catalog WITH (
  'type'                 = 'iceberg',
  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',
  'uri'                  = 'http://polaris:8181/api/catalog',
  'credential'           = '${CREDENTIAL}',
  'warehouse'            = 'hrm',
  'scope'                = 'PRINCIPAL_ROLE:ALL',
  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'          = 'http://minio:9000',
  's3.region'            = 'us-east-1',
  's3.path-style-access' = 'true',
  's3.access-key-id'     = 'admin',
  's3.secret-access-key' = 'password',
  'client.region'        = 'us-east-1'
);

USE CATALOG hrm_catalog;
CREATE DATABASE IF NOT EXISTS db_hrm;

-- ── Iceberg: employees ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.employees (
  emp_id INT, name STRING, department STRING, salary DOUBLE,
  PRIMARY KEY (emp_id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: attendance_analytics ────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.attendance_analytics (
  id             INT,
  emp_id         INT,
  check_in       BIGINT,
  check_out      BIGINT,
  work_hours     DOUBLE,
  status         STRING,
  is_late        BOOLEAN,
  overtime_hours DOUBLE,
  shift_label    STRING,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: leave_requests ───────────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.leave_requests (
  id INT, emp_id INT, leave_type STRING,
  start_date INT, end_date INT, days INT,
  status STRING, reason STRING,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: payroll ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.payroll (
  id            INT, emp_id INT, \`month\` STRING,
  base_salary   DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE,
  insurance_amt DOUBLE,
  tax_amount    DOUBLE,
  take_home     DOUBLE,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

USE CATALOG default_catalog;
USE default_database;

-- ── Kafka source: employees ───────────────────────────────────
DROP TABLE IF EXISTS employees_kafka;
CREATE TABLE employees_kafka (
  emp_id INT, name STRING, department STRING, salary DOUBLE,
  PRIMARY KEY (emp_id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'hrm.hrm.employees',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-hrm-emp',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: attendance ──────────────────────────────────
DROP TABLE IF EXISTS attendance_kafka;
CREATE TABLE attendance_kafka (
  id INT, emp_id INT, check_in BIGINT, check_out BIGINT, status STRING,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'hrm.hrm.attendance',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-hrm-att',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: leave_requests ─────────────────────────────
DROP TABLE IF EXISTS leave_requests_kafka;
CREATE TABLE leave_requests_kafka (
  id INT, emp_id INT, leave_type STRING,
  start_date INT, end_date INT, days INT,
  status STRING, reason STRING,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'hrm.hrm.leave_requests',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-hrm-lrq',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: payroll ────────────────────────────────────
DROP TABLE IF EXISTS payroll_kafka;
CREATE TABLE payroll_kafka (
  id INT, emp_id INT, \`month\` STRING,
  base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'hrm.hrm.payroll',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-hrm-pay',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── INSERT: employees → Iceberg ───────────────────────────────
INSERT INTO hrm_catalog.db_hrm.employees
SELECT emp_id, name, department, salary FROM employees_kafka;

-- ── INSERT: attendance_analytics (work_hours + is_late + overtime + shift) ──
INSERT INTO hrm_catalog.db_hrm.attendance_analytics
SELECT
  id, emp_id, check_in, check_out,
  -- work_hours
  CASE
    WHEN check_in IS NOT NULL AND check_out IS NOT NULL
    THEN CAST((check_out - check_in) / 3600000.0 AS DOUBLE)
    ELSE NULL
  END AS work_hours,
  -- status cuẩn hóa NULL
  CASE
    WHEN check_in IS NULL AND check_out IS NULL THEN 'MISSING_DATA'
    WHEN check_in IS NULL                       THEN 'NOT_CHECKED_IN'
    WHEN check_out IS NULL                      THEN 'NOT_CHECKED_OUT'
    ELSE status
  END AS status,
  -- is_late: check_in sau 9:00 giờ VN (UTC+7 = +25200000ms)
  CASE
    WHEN check_in IS NULL THEN FALSE
    WHEN ((check_in + 25200000) % 86400000) > 32400000 THEN TRUE
    ELSE FALSE
  END AS is_late,
  -- overtime_hours: số giờ OT sau 8 tiếng
  CASE
    WHEN check_in IS NOT NULL AND check_out IS NOT NULL
      AND CAST((check_out - check_in) / 3600000.0 AS DOUBLE) > 8.0
    THEN CAST((check_out - check_in) / 3600000.0 - 8.0 AS DOUBLE)
    ELSE 0.0
  END AS overtime_hours,
  -- shift_label: ca làm việc theo giờ vào (giờ VN)
  CASE
    WHEN check_in IS NULL THEN 'UNKNOWN'
    WHEN ((check_in + 25200000) % 86400000) < 43200000 THEN 'MORNING'
    WHEN ((check_in + 25200000) % 86400000) < 64800000 THEN 'AFTERNOON'
    ELSE 'EVENING'
  END AS shift_label
FROM attendance_kafka
WHERE emp_id IS NOT NULL;

-- ── INSERT: leave_requests → Iceberg ─────────────────────────
INSERT INTO hrm_catalog.db_hrm.leave_requests
SELECT id, emp_id, leave_type, start_date, end_date, days, status, reason
FROM leave_requests_kafka
WHERE emp_id IS NOT NULL;

-- ── INSERT: payroll → Iceberg (bảo hiểm + thuế TNCN + tiền thực lĩnh) ────
INSERT INTO hrm_catalog.db_hrm.payroll
SELECT
  id, emp_id, \`month\`, base_salary, deduction, bonus, net_salary,
  -- insurance_amt: BHXH 8% + BHYT 1.5% + BHTN 1% = 10.5% lương cơ sở
  CAST(base_salary * 0.105 AS DOUBLE) AS insurance_amt,
  -- tax_amount: thuế TNCN lũy tiến (giảm trừ cá nhân 11tr/tháng)
  CASE
    WHEN net_salary - 11000000 <= 0        THEN 0.0
    WHEN net_salary - 11000000 <= 5000000  THEN (net_salary - 11000000) * 0.05
    WHEN net_salary - 11000000 <= 10000000 THEN (net_salary - 11000000) * 0.10 - 250000
    WHEN net_salary - 11000000 <= 18000000 THEN (net_salary - 11000000) * 0.15 - 750000
    WHEN net_salary - 11000000 <= 32000000 THEN (net_salary - 11000000) * 0.20 - 1650000
    ELSE                                        (net_salary - 11000000) * 0.25 - 3250000
  END AS tax_amount,
  -- take_home: tiền thực lĩnh sau khi trừ bảo hiểm và thuế
  net_salary
    - CAST(base_salary * 0.105 AS DOUBLE)
    - CASE
        WHEN net_salary - 11000000 <= 0        THEN 0.0
        WHEN net_salary - 11000000 <= 5000000  THEN (net_salary - 11000000) * 0.05
        WHEN net_salary - 11000000 <= 10000000 THEN (net_salary - 11000000) * 0.10 - 250000
        WHEN net_salary - 11000000 <= 18000000 THEN (net_salary - 11000000) * 0.15 - 750000
        WHEN net_salary - 11000000 <= 32000000 THEN (net_salary - 11000000) * 0.20 - 1650000
        ELSE                                        (net_salary - 11000000) * 0.25 - 3250000
      END
  AS take_home
FROM payroll_kafka
WHERE emp_id IS NOT NULL;
EOF

common::submit_flink_sql /tmp/hrm_pipeline.sql

# ─── [8] TRINO TABLES & VIEWS ─────────────────────────────────
echo ">>> [8] Cho Flink checkpoint dau tien (90s)..."
sleep 90

echo ">>> [8b] Tao MinIO placeholder dirs..."
docker exec minio sh -c "
  for DIR in employees attendance_analytics leave_requests payroll; do
    echo '' | /tmp/mc pipe local/hrm/iceberg-data/db_hrm/\$DIR/data/.keep 2>/dev/null || true
  done
"

echo ">>> [8c] Tao Trino tables & views..."
docker exec trino trino --execute "
CREATE SCHEMA IF NOT EXISTS minio.db_hrm;

-- Don cu
DROP VIEW  IF EXISTS minio.db_hrm.overtime_report;
DROP VIEW  IF EXISTS minio.db_hrm.payroll_summary;
DROP VIEW  IF EXISTS minio.db_hrm.leave_analysis;
DROP VIEW  IF EXISTS minio.db_hrm.late_ranking;
DROP VIEW  IF EXISTS minio.db_hrm.department_stats;
DROP VIEW  IF EXISTS minio.db_hrm.attendance_summary;
DROP TABLE IF EXISTS minio.db_hrm.payroll_raw;
DROP TABLE IF EXISTS minio.db_hrm.leave_requests_raw;
DROP TABLE IF EXISTS minio.db_hrm.attendance_raw;
DROP TABLE IF EXISTS minio.db_hrm.employees;

-- Raw tables
CREATE TABLE minio.db_hrm.employees (
  emp_id INTEGER, name VARCHAR, department VARCHAR, salary DOUBLE
) WITH (
  external_location = 's3://hrm/iceberg-data/db_hrm/employees/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_hrm.attendance_raw (
  id INTEGER, emp_id INTEGER,
  check_in BIGINT, check_out BIGINT,
  work_hours DOUBLE, status VARCHAR,
  is_late BOOLEAN, overtime_hours DOUBLE, shift_label VARCHAR
) WITH (
  external_location = 's3://hrm/iceberg-data/db_hrm/attendance_analytics/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_hrm.leave_requests_raw (
  id INTEGER, emp_id INTEGER, leave_type VARCHAR,
  start_date INTEGER, end_date INTEGER, days INTEGER,
  status VARCHAR, reason VARCHAR
) WITH (
  external_location = 's3://hrm/iceberg-data/db_hrm/leave_requests/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_hrm.payroll_raw (
  id INTEGER, emp_id INTEGER, month VARCHAR,
  base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE,
  insurance_amt DOUBLE, tax_amount DOUBLE, take_home DOUBLE
) WITH (
  external_location = 's3://hrm/iceberg-data/db_hrm/payroll/data/',
  format = 'PARQUET'
);

-- View: attendance_summary
CREATE VIEW minio.db_hrm.attendance_summary AS
SELECT e.emp_id, e.name, e.department,
  a.status, a.work_hours, a.check_in, a.check_out
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
  AND e.name IS NOT NULL AND e.name <> '';

-- View: department_stats
CREATE VIEW minio.db_hrm.department_stats AS
SELECT e.department,
  COUNT(DISTINCT e.emp_id)                                     AS employee_count,
  COUNT(a.id)                                                  AS total_sessions,
  ROUND(AVG(a.work_hours), 2)                                  AS avg_work_hours,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END)   AS late_count,
  SUM(CASE WHEN a.status = 'ON_TIME'     THEN 1 ELSE 0 END)   AS on_time_count,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END)   AS early_leave_count
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
  AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.department
ORDER BY late_count DESC;

-- View: late_ranking
CREATE VIEW minio.db_hrm.late_ranking AS
SELECT e.emp_id, e.name, e.department,
  COUNT(*)                                                     AS total_days,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END)   AS late_days,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END)   AS early_leave_days,
  ROUND(AVG(a.work_hours), 2)                                  AS avg_work_hours,
  CASE
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 4 THEN 'CRITICAL'
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 2 THEN 'WARNING'
    ELSE 'GOOD'
  END AS discipline_tier
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
  AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department
ORDER BY late_days DESC;

-- View: leave_analysis
CREATE VIEW minio.db_hrm.leave_analysis AS
SELECT e.emp_id, e.name, e.department,
  COUNT(l.id)                                                       AS total_requests,
  SUM(CASE WHEN l.status = 'approved' THEN l.days ELSE 0 END)      AS approved_days,
  SUM(CASE WHEN l.leave_type = 'sick'   THEN 1 ELSE 0 END)         AS sick_requests,
  SUM(CASE WHEN l.leave_type = 'annual' THEN 1 ELSE 0 END)         AS annual_requests,
  SUM(CASE WHEN l.status = 'pending'  THEN 1 ELSE 0 END)           AS pending_requests
FROM minio.db_hrm.leave_requests_raw l
JOIN minio.db_hrm.employees e ON l.emp_id = e.emp_id
WHERE e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department
ORDER BY approved_days DESC;

-- View: payroll_summary (có bảo hiểm + thuế + tiền thực lĩnh)
CREATE VIEW minio.db_hrm.payroll_summary AS
SELECT e.department,
  ROUND(AVG(p.base_salary), 0)   AS avg_base_salary,
  ROUND(AVG(p.insurance_amt), 0) AS avg_insurance,
  ROUND(AVG(p.tax_amount), 0)    AS avg_tax,
  ROUND(AVG(p.net_salary), 0)    AS avg_net_salary,
  ROUND(AVG(p.take_home), 0)     AS avg_take_home,
  ROUND(SUM(p.take_home), 0)     AS total_take_home
FROM minio.db_hrm.payroll_raw p
JOIN minio.db_hrm.employees e ON p.emp_id = e.emp_id
WHERE e.name IS NOT NULL AND e.name <> ''
GROUP BY e.department
ORDER BY total_take_home DESC;

-- View: overtime_report (giờ OT + ca làm việc)
CREATE VIEW minio.db_hrm.overtime_report AS
SELECT e.emp_id, e.name, e.department,
  ROUND(SUM(a.overtime_hours), 2)                              AS total_ot_hours,
  COUNT(CASE WHEN a.overtime_hours > 0 THEN 1 END)             AS ot_days,
  COUNT(CASE WHEN a.is_late = TRUE THEN 1 END)                 AS late_by_flag,
  COUNT(CASE WHEN a.shift_label = 'MORNING'   THEN 1 END)      AS morning_days,
  COUNT(CASE WHEN a.shift_label = 'AFTERNOON' THEN 1 END)      AS afternoon_days
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
  AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department
ORDER BY total_ot_hours DESC;

-- Verify
SELECT 'employees'        AS tbl, COUNT(*) AS rows FROM minio.db_hrm.employees
UNION ALL
SELECT 'attendance_raw',           COUNT(*) FROM minio.db_hrm.attendance_raw
UNION ALL
SELECT 'leave_requests_raw',       COUNT(*) FROM minio.db_hrm.leave_requests_raw
UNION ALL
SELECT 'payroll_raw',              COUNT(*) FROM minio.db_hrm.payroll_raw;
" && echo "  ✅ Trino tables & views san sang." || echo "  ⚠️ Xem lai Trino."

echo ""
echo "============================================"
echo "  ✅ HRM Pipeline da khoi chay!"
echo "============================================"
echo "  Flink UI  : http://localhost:8081"
echo "  MinIO     : http://localhost:9001  (admin/password)"
echo "  Kafka UI  : http://localhost:8089"
echo "  Trino     : http://localhost:8080"
echo "  Superset  : http://localhost:8088"
echo ""
echo "  Superset URI: trino://admin@trino:8080/minio/db_hrm"
echo ""
echo "Kiem tra analytics:"
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_hrm.late_ranking\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_hrm.department_stats\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_hrm.leave_analysis\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_hrm.payroll_summary\""
echo ""
echo "Chay demo realtime: ./demo_hrm.sh"