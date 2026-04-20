#!/bin/bash
# =============================================================
#  setup_hrm.sh — HRM Pipeline (all-in-one)
#  MySQL → Debezium → Kafka → Flink → Iceberg (Polaris) → Trino
# =============================================================
set -e
export MYSQL_PWD=123

PROJECT="hrm"
BUCKET="hrm"
CATALOG="hrm"
NAMESPACE="db_hrm"

echo "============================================"
echo "  HRM Pipeline: Cham cong Realtime"
echo "============================================"
echo ""

# ─── [1] JARs ─────────────────────────────────────────────────
echo ">>> [1] Tai JARs can thiet..."
wget -q -nc https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.5.0/iceberg-aws-bundle-1.5.0.jar
wget -q -nc https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
wget -q -nc https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.18/1.5.0/iceberg-flink-runtime-1.18-1.5.0.jar
echo "  ✅ JARs da tai xong."

echo ">>> [1b] Copy JARs vao Flink containers..."
for CONTAINER in flink-jobmanager flink-taskmanager flink-sql-client; do
  for JAR in iceberg-flink-runtime-1.18-1.5.0.jar iceberg-aws-bundle-1.5.0.jar flink-shaded-hadoop-2-uber-2.8.3-10.0.jar; do
    docker cp "$JAR" "$CONTAINER:/opt/flink/lib/" 2>/dev/null || true
  done
done
echo "  ✅ JARs san sang trong Flink."

# ─── [2] MYSQL SCHEMA + DATA ──────────────────────────────────
echo ">>> [2] Doi MySQL san sang..."
until docker exec mysql mysqladmin ping -h localhost -p123 --silent 2>/dev/null; do
  echo -n "."; sleep 2
done
echo " OK!"

echo ">>> [2b] Tao schema & seed data MySQL..."
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
echo ">>> [3] Cho Polaris khoi dong..."
for i in $(seq 1 2); do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:8181/api/catalog/v1/oauth/tokens 2>/dev/null || true)
  if [[ "$HTTP" == "400" || "$HTTP" == "401" || "$HTTP" == "200" ]]; then
    echo "  ✅ Polaris san sang."; break
  fi
  echo "  ... cho Polaris (lan $i/20)..."; sleep 5
done

CREDENTIAL=$(docker logs polaris 2>&1 | grep -a "principal credentials" | tail -1 \
  | grep -oP '[0-9a-f]{16}:[0-9a-f]{32}' | tail -1)
if [ -z "$CREDENTIAL" ]; then echo "❌ Khong tim duoc credential."; exit 1; fi
echo "  Credential: $CREDENTIAL"

TOKEN=$(curl -s -X POST \
  -H "X-Polaris-Realm: POLARIS" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$CREDENTIAL" \
  -d "grant_type=client_credentials&scope=PRINCIPAL_ROLE:ALL" \
  "http://localhost:8181/api/catalog/v1/oauth/tokens" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
export CREDENTIAL TOKEN
echo "  ✅ Token lay thanh cong."

# ─── [4] CLEANUP ──────────────────────────────────────────────
echo ">>> [4] Don dep data cu..."

echo "  [Flink] Cancel jobs dang chay..."
JOBS=$(docker exec flink-jobmanager curl -s http://localhost:8081/jobs \
  | python3 -c "import sys,json; [print(j['id']) for j in json.load(sys.stdin)['jobs'] if j['status'] in ('RUNNING','CREATED','RESTARTING','FAILING')]" 2>/dev/null || true)
for JOB_ID in $JOBS; do
  docker exec flink-jobmanager curl -s -X PATCH \
    "http://localhost:8081/jobs/${JOB_ID}?mode=cancel" > /dev/null
  echo "    ❌ Da cancel job: $JOB_ID"
done
[ -n "$JOBS" ] && sleep 5 || true

echo "  [Kafka] Xoa topics..."
for TOPIC in "hrm.hrm.employees" "hrm.hrm.attendance" "hrm.hrm.leave_requests" "hrm.hrm.payroll"; do
  docker exec kafka kafka-topics --bootstrap-server kafka:9092 \
    --delete --topic "$TOPIC" 2>/dev/null && \
    echo "    🗑️  Da xoa: $TOPIC" || echo "    ℹ️  $TOPIC chua ton tai."
done
sleep 3

echo "  [Kafka] Xoa schema history topics..."
docker exec kafka kafka-topics --bootstrap-server kafka:9092 --list \
  | grep "schemahistory\.hrm\." \
  | xargs -I {} docker exec kafka kafka-topics --bootstrap-server kafka:9092 --delete --topic {} 2>/dev/null || true

echo "  [Polaris] Xoa Iceberg tables..."
for TABLE in employees attendance_analytics leave_requests payroll; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
    "http://localhost:8181/api/catalog/v1/${CATALOG}/namespaces/${NAMESPACE}/tables/${TABLE}" \
    -H "Authorization: Bearer $TOKEN" -H "X-Polaris-Realm: POLARIS")
  [ "$HTTP" = "204" ] && echo "    🗑️  Da xoa: ${NAMESPACE}.${TABLE}" || \
    echo "    ℹ️  ${NAMESPACE}.${TABLE} chua ton tai."
done

echo "  [MinIO] Don bucket hrm..."
wget -q -nc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
docker cp mc minio:/tmp/mc
docker exec minio sh -c "
  /tmp/mc alias set local http://localhost:9000 admin password --api S3v4 2>/dev/null
  /tmp/mc rm --recursive --force local/hrm/ 2>/dev/null || true
  /tmp/mc mb local/hrm --ignore-existing 2>/dev/null
"
echo "    ✅ MinIO bucket 'hrm' san sang."

echo "  [Debezium] Xoa connectors cu..."
OLD_CONNECTORS=$(curl -s http://localhost:8083/connectors \
  | python3 -c "import sys,json; [print(i) for i in json.load(sys.stdin) if 'hrm-connector' in i]" 2>/dev/null || true)
for c in $OLD_CONNECTORS; do
  curl -s -X DELETE "http://localhost:8083/connectors/$c" > /dev/null
  echo "    🗑️  Da xoa connector: $c"
done
sleep 2

echo "  ✅ Don dep xong."
echo ""

# ─── [5] DEBEZIUM ─────────────────────────────────────────────
echo ">>> [5] Doi Kafka Connect san sang..."
until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
  echo -n "."; sleep 2
done
echo " OK!"

RANDOM_ID=$((184000 + RANDOM % 1000))
echo ">>> [5b] Dang ky Debezium connector (server.id=$RANDOM_ID)..."
HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "http://localhost:8083/connectors/" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"hrm-connector-${RANDOM_ID}\",
    \"config\": {
      \"connector.class\":  \"io.debezium.connector.mysql.MySqlConnector\",
      \"tasks.max\":        \"1\",
      \"database.hostname\": \"mysql\",
      \"database.port\":    \"3306\",
      \"database.user\":    \"root\",
      \"database.password\": \"123\",
      \"database.server.id\": \"${RANDOM_ID}\",
      \"snapshot.mode\":    \"initial\",
      \"topic.prefix\":     \"hrm\",
      \"database.include.list\": \"hrm\",
      \"table.include.list\": \"hrm.employees,hrm.attendance,hrm.leave_requests,hrm.payroll\",
      \"decimal.handling.mode\": \"double\",
      \"schema.history.internal.kafka.bootstrap.servers\": \"kafka:9092\",
      \"schema.history.internal.kafka.topic\": \"schemahistory.hrm.${RANDOM_ID}\"
    }
  }")
[ "$HTTP" = "201" ] && echo "  ✅ Connector da dang ky (HTTP $HTTP)." || \
  echo "  ⚠️  HTTP $HTTP khi dang ky connector."

echo "  ⏳ Cho Kafka topic 'hrm.hrm.employees' xuat hien..."
until docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -q "hrm.hrm.employees"; do
  echo -n "."; sleep 2
done
echo " OK!"

# ─── [6] POLARIS CATALOG ──────────────────────────────────────
echo ">>> [6] Tao Polaris catalog '${CATALOG}'..."
curl -s -X DELETE "http://localhost:8181/api/management/v1/catalogs/${CATALOG}" \
  -H "X-Polaris-Realm: POLARIS" -H "Authorization: Bearer $TOKEN" > /dev/null || true

HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "http://localhost:8181/api/management/v1/catalogs" \
  -H "X-Polaris-Realm: POLARIS" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"catalog\":{\"type\":\"INTERNAL\",\"name\":\"${CATALOG}\",\"storageConfigInfo\":{\"storageType\":\"S3\",\"allowedLocations\":[\"s3://${BUCKET}/\"],\"pathStyleAccess\":true},\"properties\":{\"default-base-location\":\"s3://${BUCKET}/iceberg-data\",\"s3.endpoint\":\"http://minio:9000\",\"s3.path-style-access\":\"true\",\"s3.access-key-id\":\"admin\",\"s3.secret-access-key\":\"password\",\"client.region\":\"us-east-1\"}}}")
case "$HTTP" in
  201|400|409) echo "  ✅ Catalog '${CATALOG}' san sang." ;;
  *) echo "  ⚠️  HTTP $HTTP khi tao catalog." ;;
esac

# ─── [6b] TRINO ───────────────────────────────────────────────
echo ">>> [6b] Cap nhat Trino iceberg.properties + restart..."
mkdir -p trino-conf
cat > trino-conf/iceberg.properties << TRINOEOF
connector.name=iceberg
iceberg.catalog.type=rest
iceberg.rest-catalog.uri=http://polaris-proxy:8282/api/catalog
iceberg.rest-catalog.security=OAUTH2
iceberg.rest-catalog.oauth2.token=${TOKEN}
hive.s3.endpoint=http://minio:9000
hive.s3.aws-access-key=admin
hive.s3.aws-secret-key=password
hive.s3.path-style-access=true
hive.s3.ssl.enabled=false
hive.s3.region=us-east-1
TRINOEOF
docker restart trino > /dev/null 2>&1
echo "  ✅ Trino da restart."

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

-- ── Iceberg: attendance_analytics ─────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.attendance_analytics (
  id INT, emp_id INT, check_in BIGINT, check_out BIGINT,
  work_hours DOUBLE, status STRING, is_late BOOLEAN,
  overtime_hours DOUBLE, shift_label STRING,
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

-- ── Iceberg: payroll ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_hrm.payroll (
  id INT, emp_id INT, \`month\` STRING,
  base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE,
  insurance_amt DOUBLE, tax_amount DOUBLE, take_home DOUBLE,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

USE CATALOG default_catalog;
USE default_database;

-- ── Kafka sources ─────────────────────────────────────────────
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

-- ── INSERTs ───────────────────────────────────────────────────
INSERT INTO hrm_catalog.db_hrm.employees
SELECT emp_id, name, department, salary FROM employees_kafka;

INSERT INTO hrm_catalog.db_hrm.attendance_analytics
SELECT
  id, emp_id, check_in, check_out,
  CASE
    WHEN check_in IS NOT NULL AND check_out IS NOT NULL
    THEN CAST((check_out - check_in) / 3600000.0 AS DOUBLE)
    ELSE NULL
  END AS work_hours,
  CASE
    WHEN check_in IS NULL AND check_out IS NULL THEN 'MISSING_DATA'
    WHEN check_in IS NULL                       THEN 'NOT_CHECKED_IN'
    WHEN check_out IS NULL                      THEN 'NOT_CHECKED_OUT'
    ELSE status
  END AS status,
  CASE
    WHEN check_in IS NULL THEN FALSE
    WHEN ((check_in + 25200000) % 86400000) > 32400000 THEN TRUE
    ELSE FALSE
  END AS is_late,
  CASE
    WHEN check_in IS NOT NULL AND check_out IS NOT NULL
      AND CAST((check_out - check_in) / 3600000.0 AS DOUBLE) > 8.0
    THEN CAST((check_out - check_in) / 3600000.0 - 8.0 AS DOUBLE)
    ELSE 0.0
  END AS overtime_hours,
  CASE
    WHEN check_in IS NULL THEN 'UNKNOWN'
    WHEN ((check_in + 25200000) % 86400000) < 43200000 THEN 'MORNING'
    WHEN ((check_in + 25200000) % 86400000) < 64800000 THEN 'AFTERNOON'
    ELSE 'EVENING'
  END AS shift_label
FROM attendance_kafka
WHERE emp_id IS NOT NULL;

INSERT INTO hrm_catalog.db_hrm.leave_requests
SELECT id, emp_id, leave_type, start_date, end_date, days, status, reason
FROM leave_requests_kafka
WHERE emp_id IS NOT NULL;

INSERT INTO hrm_catalog.db_hrm.payroll
SELECT
  id, emp_id, \`month\`, base_salary, deduction, bonus, net_salary,
  CAST(base_salary * 0.105 AS DOUBLE) AS insurance_amt,
  CASE
    WHEN net_salary - 11000000 <= 0        THEN 0.0
    WHEN net_salary - 11000000 <= 5000000  THEN (net_salary - 11000000) * 0.05
    WHEN net_salary - 11000000 <= 10000000 THEN (net_salary - 11000000) * 0.10 - 250000
    WHEN net_salary - 11000000 <= 18000000 THEN (net_salary - 11000000) * 0.15 - 750000
    WHEN net_salary - 11000000 <= 32000000 THEN (net_salary - 11000000) * 0.20 - 1650000
    ELSE                                        (net_salary - 11000000) * 0.25 - 3250000
  END AS tax_amount,
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

docker cp /tmp/hrm_pipeline.sql flink-sql-client:/tmp/hrm_pipeline.sql
docker exec -i flink-sql-client ./bin/sql-client.sh \
  -Djobmanager.rpc.address=flink-jobmanager \
  -Djobmanager.rpc.port=6123 \
  -Drest.address=flink-jobmanager \
  -Drest.port=8081 \
  -f /tmp/hrm_pipeline.sql
echo "  ✅ Flink SQL da submit."

# ─── [8] TRINO TABLES & VIEWS ─────────────────────────────────
echo ">>> [8] Cho Flink checkpoint dau tien (90s)..."
sleep 90

echo ">>> [8b] Tao MinIO placeholder dirs..."
docker exec minio sh -c "
  for DIR in employees attendance_analytics leave_requests payroll; do
    echo '' | /tmp/mc pipe local/hrm/iceberg-data/db_hrm/\$DIR/data/.keep 2>/dev/null || true
  done
"

echo ">>> [8c] Doi Trino san sang..."
until docker exec trino trino --user admin --execute "SELECT 1" > /dev/null 2>&1; do
  echo -n "."; sleep 3
done
echo " OK!"

echo ">>> [8d] Tao Trino tables & views..."
docker exec trino trino --user admin --execute "
CREATE SCHEMA IF NOT EXISTS minio.db_hrm;

DROP VIEW  IF EXISTS minio.db_hrm.overtime_report;
DROP VIEW  IF EXISTS minio.db_hrm.payroll_summary;
DROP VIEW  IF EXISTS minio.db_hrm.leave_analysis;
DROP VIEW  IF EXISTS minio.db_hrm.late_ranking;
DROP VIEW  IF EXISTS minio.db_hrm.department_stats;
DROP VIEW  IF EXISTS minio.db_hrm.attendance_summary;
DROP TABLE IF EXISTS minio.db_hrm.payroll;
DROP TABLE IF EXISTS minio.db_hrm.leave_requests;
DROP TABLE IF EXISTS minio.db_hrm.attendance;
DROP TABLE IF EXISTS minio.db_hrm.employees;

CREATE TABLE minio.db_hrm.employees (
  emp_id INTEGER, name VARCHAR, department VARCHAR, salary DOUBLE
) WITH (external_location = 's3://hrm/iceberg-data/db_hrm/employees/data/', format = 'PARQUET');

CREATE TABLE minio.db_hrm.attendance (
  id INTEGER, emp_id INTEGER, check_in BIGINT, check_out BIGINT,
  work_hours DOUBLE, status VARCHAR, is_late BOOLEAN, overtime_hours DOUBLE, shift_label VARCHAR
) WITH (external_location = 's3://hrm/iceberg-data/db_hrm/attendance_analytics/data/', format = 'PARQUET');

CREATE TABLE minio.db_hrm.leave_requests (
  id INTEGER, emp_id INTEGER, leave_type VARCHAR,
  start_date INTEGER, end_date INTEGER, days INTEGER, status VARCHAR, reason VARCHAR
) WITH (external_location = 's3://hrm/iceberg-data/db_hrm/leave_requests/data/', format = 'PARQUET');

CREATE TABLE minio.db_hrm.payroll (
  id INTEGER, emp_id INTEGER, month VARCHAR,
  base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE,
  insurance_amt DOUBLE, tax_amount DOUBLE, take_home DOUBLE
) WITH (external_location = 's3://hrm/iceberg-data/db_hrm/payroll/data/', format = 'PARQUET');

CREATE VIEW minio.db_hrm.attendance_summary AS
SELECT e.emp_id, e.name, e.department, a.status, a.work_hours, a.check_in, a.check_out
FROM minio.db_hrm.attendance a JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL AND e.name IS NOT NULL AND e.name <> '';

CREATE VIEW minio.db_hrm.department_stats AS
SELECT e.department,
  COUNT(DISTINCT e.emp_id)                                   AS employee_count,
  COUNT(a.id)                                                AS total_sessions,
  ROUND(AVG(a.work_hours), 2)                                AS avg_work_hours,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END) AS late_count,
  SUM(CASE WHEN a.status = 'ON_TIME'     THEN 1 ELSE 0 END) AS on_time_count,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END) AS early_leave_count
FROM minio.db_hrm.attendance a JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.department ORDER BY late_count DESC;

CREATE VIEW minio.db_hrm.late_ranking AS
SELECT e.emp_id, e.name, e.department,
  COUNT(*)                                                   AS total_days,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END) AS late_days,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END) AS early_leave_days,
  ROUND(AVG(a.work_hours), 2)                                AS avg_work_hours,
  CASE
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 4 THEN 'CRITICAL'
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 2 THEN 'WARNING'
    ELSE 'GOOD'
  END AS discipline_tier
FROM minio.db_hrm.attendance a JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department ORDER BY late_days DESC;

CREATE VIEW minio.db_hrm.leave_analysis AS
SELECT e.emp_id, e.name, e.department,
  COUNT(l.id)                                                  AS total_requests,
  SUM(CASE WHEN l.status = 'approved' THEN l.days ELSE 0 END) AS approved_days,
  SUM(CASE WHEN l.leave_type = 'sick'   THEN 1 ELSE 0 END)    AS sick_requests,
  SUM(CASE WHEN l.leave_type = 'annual' THEN 1 ELSE 0 END)    AS annual_requests,
  SUM(CASE WHEN l.status = 'pending'  THEN 1 ELSE 0 END)      AS pending_requests
FROM minio.db_hrm.leave_requests l JOIN minio.db_hrm.employees e ON l.emp_id = e.emp_id
WHERE e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department ORDER BY approved_days DESC;

CREATE VIEW minio.db_hrm.payroll_summary AS
SELECT e.department,
  ROUND(AVG(p.base_salary), 0)   AS avg_base_salary,
  ROUND(AVG(p.insurance_amt), 0) AS avg_insurance,
  ROUND(AVG(p.tax_amount), 0)    AS avg_tax,
  ROUND(AVG(p.net_salary), 0)    AS avg_net_salary,
  ROUND(AVG(p.take_home), 0)     AS avg_take_home,
  ROUND(SUM(p.take_home), 0)     AS total_take_home
FROM minio.db_hrm.payroll p JOIN minio.db_hrm.employees e ON p.emp_id = e.emp_id
WHERE e.name IS NOT NULL AND e.name <> ''
GROUP BY e.department ORDER BY total_take_home DESC;

CREATE VIEW minio.db_hrm.overtime_report AS
SELECT e.emp_id, e.name, e.department,
  ROUND(SUM(a.overtime_hours), 2)                         AS total_ot_hours,
  COUNT(CASE WHEN a.overtime_hours > 0 THEN 1 END)        AS ot_days,
  COUNT(CASE WHEN a.is_late = TRUE THEN 1 END)            AS late_by_flag,
  COUNT(CASE WHEN a.shift_label = 'MORNING'   THEN 1 END) AS morning_days,
  COUNT(CASE WHEN a.shift_label = 'AFTERNOON' THEN 1 END) AS afternoon_days
FROM minio.db_hrm.attendance a JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL AND e.name IS NOT NULL AND e.name <> ''
GROUP BY e.emp_id, e.name, e.department ORDER BY total_ot_hours DESC;

SELECT 'employees'        AS tbl, COUNT(*) AS rows FROM minio.db_hrm.employees
UNION ALL SELECT 'attendance_raw',     COUNT(*) FROM minio.db_hrm.attendance
UNION ALL SELECT 'leave_requests_raw', COUNT(*) FROM minio.db_hrm.leave_requests
UNION ALL SELECT 'payroll_raw',        COUNT(*) FROM minio.db_hrm.payroll;
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
echo "  docker exec trino trino --user admin --execute \"SELECT * FROM minio.db_hrm.late_ranking\""
echo "  docker exec trino trino --user admin --execute \"SELECT * FROM minio.db_hrm.department_stats\""
echo "  docker exec trino trino --user admin --execute \"SELECT * FROM minio.db_hrm.leave_analysis\""
echo "  docker exec trino trino --user admin --execute \"SELECT * FROM minio.db_hrm.payroll_summary\""
echo ""
echo "Chay demo realtime: ./demo_hrm.sh"