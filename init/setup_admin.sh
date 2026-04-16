#!/bin/bash
# =============================================================
#  setup_admin.sh — Admin Pipeline (85 bảng)
#  MySQL → Debezium → Kafka → Flink → Iceberg → Trino
# =============================================================
set -e
export MYSQL_PWD=123

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/pipeline_common.sh"
source "$SCRIPT_DIR/../conf/admin_tables.sh"

DB="admin_db"
CATALOG="admin"
BUCKET="admin"
NAMESPACE="db_admin"
CONNECTOR_NAME="admin-mysql-connector"
TOPIC_PREFIX="admin_db"

echo "============================================"
echo "  Admin Pipeline: 85 bang | CDC | Iceberg"
echo "============================================"

# ─── [1] JARs ─────────────────────────────────────────────────
common::download_jars
common::copy_jars_to_flink

# ─── [2] CLEANUP ──────────────────────────────────────────────
echo ">>> [2] Cleanup..."
common::cleanup_flink_jobs
common::cleanup_debezium_connectors "$CONNECTOR_NAME"
# common::get_polaris_token
# common::cleanup_iceberg_tables "$TOKEN" "$CATALOG" "$NAMESPACE" \
#  "${ICEBERG_TABLES_CLEANUP[@]}"
# common::cleanup_minio "$BUCKET"
echo "  OK (Skipped Iceberg/MinIO cleanup for fast resume!)"

# ─── [3] MYSQL SCHEMA ─────────────────────────────────────────
echo ">>> [3] MySQL schema (85 bang)..."
common::wait_for_mysql
set +e
docker exec -i mysql mysql -uroot -p123 \
  --default-character-set=utf8mb4 \
  < "$SCRIPT_DIR/sql/admin_schema.sql"
docker exec -i mysql mysql -uroot -p123 \
  --default-character-set=utf8mb4 \
  < "$SCRIPT_DIR/sql/admin_seed.sql"
set -e
echo "  OK"

# ─── [4] POLARIS CATALOG ──────────────────────────────────────
echo ">>> [4] Polaris catalog..."
common::get_polaris_token
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://${BUCKET}/"

curl -s -X PUT \
  "http://localhost:8181/api/management/v1/catalogs/${CATALOG}/namespaces" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Polaris-Realm: POLARIS" \
  -H "Content-Type: application/json" \
  -d "{\"namespace\":[\"${NAMESPACE}\"],\"properties\":{}}" > /dev/null || true

common::update_trino_token "$TOKEN"
echo "  OK"

# ─── [5] KAFKA TOPICS ─────────────────────────────────────────
echo ">>> [5] Kafka topics..."
common::wait_for_kafka
echo "  (Bỏ qua tạo thủ công, Kafka sẽ tự động tạo topic qua Debezium auto.create.topics.enable=true để tiết kiệm thời gian)"
echo "  OK"

# ─── [6] DEBEZIUM ─────────────────────────────────────────────
echo ">>> [6] Debezium connector..."
common::wait_for_kafka_connect
TABLE_LIST=""
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r mysql_tbl _ _ _ _ <<< "$entry"
  [ -n "$TABLE_LIST" ] && TABLE_LIST+=","
  TABLE_LIST+="${DB}.${mysql_tbl}"
done

common::register_debezium "{
  \"name\": \"${CONNECTOR_NAME}\",
  \"config\": {
    \"connector.class\": \"io.debezium.connector.mysql.MySqlConnector\",
    \"tasks.max\": \"1\",
    \"database.hostname\": \"mysql\",
    \"database.port\": \"3306\",
    \"database.user\": \"root\",
    \"database.password\": \"123\",
    \"database.server.id\": \"__ID__\",
    \"topic.prefix\": \"${TOPIC_PREFIX}\",
    \"database.include.list\": \"${DB}\",
    \"table.include.list\": \"${TABLE_LIST}\",
    \"schema.history.internal.kafka.bootstrap.servers\": \"kafka:9092\",
    \"schema.history.internal.kafka.topic\": \"${TOPIC_PREFIX}.schema-history\",
    \"include.schema.changes\": \"false\",
    \"decimal.handling.mode\": \"double\",
    \"snapshot.mode\": \"initial\"
  }
}"
sleep 10
echo "  OK"

# ─── [7] FLINK SQL ────────────────────────────────────────────
echo ">>> [7] Generate & submit Flink SQL..."
common::wait_for_flink

FLINK_SQL="/tmp/admin_flink.sql"
FLINK_REMOTE="/tmp/admin_flink.sql"
FLINK_JARS="/opt/flink/lib/iceberg-flink-runtime-1.18-1.5.0.jar /opt/flink/lib/iceberg-aws-bundle-1.5.0.jar /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar"

cat > "$FLINK_SQL" << HEADER
SET 'execution.checkpointing.interval' = '60s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'table.exec.sink.upsert-materialize' = 'NONE';

CREATE CATALOG admin_catalog WITH (
  'type'                 = 'iceberg',
  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',
  'uri'                  = 'http://polaris:8181/api/catalog',
  'credential'           = '${CREDENTIAL}',
  'warehouse'            = 'admin',
  'scope'                = 'PRINCIPAL_ROLE:ALL',
  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'          = 'http://minio:9000',
  's3.region'            = 'us-east-1',
  's3.path-style-access' = 'true',
  's3.access-key-id'     = 'admin',
  's3.secret-access-key' = 'password',
  'client.region'        = 'us-east-1'
);
SET 'execution.checkpointing.interval' = '60s';
SET 'table.exec.sink.upsert-materialize' = 'AUTO';
SET 'table.exec.resource.default-parallelism' = '1';
USE CATALOG admin_catalog;
CREATE DATABASE IF NOT EXISTS db_admin;
USE db_admin;
HEADER

for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r mysql_tbl iceberg_tbl pk kgroup _ <<< "$entry"

  var="KAFKA_COLS_${mysql_tbl}"
  kafka_cols="${!var}"
  [ -z "$kafka_cols" ] && { echo "  SKIP $mysql_tbl: no KAFKA_COLS"; continue; }

  TOPIC="${TOPIC_PREFIX}.${DB}.${mysql_tbl}"

  # Extract and escape column names for Flink (`col` TYPE)
  escaped_kafka_cols=$(python3 -c "
cols = '''${kafka_cols}'''.split(',')
print(', '.join(['\`' + c.strip().split()[0] + '\` ' + c.strip().split()[1] for c in cols if c.strip()]))
")

  cat >> "$FLINK_SQL" << SQL

-- DDL: ${mysql_tbl}
CREATE TABLE IF NOT EXISTS default_catalog.default_database.kafka_${mysql_tbl} (
  ${escaped_kafka_cols}
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = '${TOPIC}',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = '${kgroup}',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);
CREATE TABLE IF NOT EXISTS admin_catalog.db_admin.\`${iceberg_tbl}\` (
  ${escaped_kafka_cols},
  PRIMARY KEY (\`${pk}\`) NOT ENFORCED
) WITH (
  'write.upsert.enabled' = 'true',
  'format-version'       = '2'
);
SQL
done

cat >> "$FLINK_SQL" << SQL

-- ========================================================
-- CHIA NHỎ THÀNH TỪNG JOB (5 BẢNG) ĐỂ TRÁNH QUÁ TẢI MEMORY SLOT
-- ========================================================
SQL

COUNT=0
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r mysql_tbl iceberg_tbl pk _ _ <<< "$entry"
  var="KAFKA_COLS_${mysql_tbl}"
  kafka_cols="${!var}"
  [ -z "$kafka_cols" ] && continue

  if [ $((COUNT % 5)) -eq 0 ]; then
    if [ $COUNT -ne 0 ]; then
      cat >> "$FLINK_SQL" << SQL
END;
SQL
    fi
    cat >> "$FLINK_SQL" << SQL
EXECUTE STATEMENT SET
BEGIN
SQL
  fi

  col_names=$(python3 -c "
cols = '''${kafka_cols}'''.split(',')
print(', '.join(['\`' + c.strip().split()[0] + '\`' for c in cols if c.strip()]))
")

  cat >> "$FLINK_SQL" << SQL
INSERT INTO admin_catalog.db_admin.\`${iceberg_tbl}\` SELECT ${col_names} FROM default_catalog.default_database.kafka_${mysql_tbl} WHERE \`${pk}\` IS NOT NULL;
SQL

  COUNT=$((COUNT + 1))
done

if [ $COUNT -ne 0 ]; then
  cat >> "$FLINK_SQL" << SQL
END;
SQL
fi


# Copy JARs vào container rồi submit
FLINK_CONTAINER="flink-sql-client"
JAR1="iceberg-flink-runtime-1.18-1.5.0.jar"
JAR2="iceberg-aws-bundle-1.5.0.jar"
JAR3="flink-shaded-hadoop-2-uber-2.8.3-10.0.jar"

echo "  Copying JARs vao $FLINK_CONTAINER..."
docker cp "$JAR1" "${FLINK_CONTAINER}:/tmp/${JAR1}" 2>/dev/null || true
docker cp "$JAR2" "${FLINK_CONTAINER}:/tmp/${JAR2}" 2>/dev/null || true
docker cp "$JAR3" "${FLINK_CONTAINER}:/tmp/${JAR3}" 2>/dev/null || true
docker cp "$FLINK_SQL" "${FLINK_CONTAINER}:/tmp/admin_flink.sql"

docker exec -i "$FLINK_CONTAINER" ./bin/sql-client.sh \
  -Djobmanager.rpc.address=flink-jobmanager \
  -Djobmanager.rpc.port=6123 \
  -Drest.address=flink-jobmanager \
  -Drest.port=8081 \
  -f "/tmp/admin_flink.sql"
echo "  OK"

# ─── [8] TRINO RAW TABLES ─────────────────────────────────────
echo ">>> [8] Trino tables & views..."
# Trino vừa restart, cần doi them
echo "  Cho Trino ready sau restart (30s)..."
sleep 30
for i in $(seq 1 20); do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/info 2>/dev/null || echo "000")
  if [ "$HTTP" = "200" ]; then echo "  Trino OK!"; break; fi
  echo "  ... cho Trino (${i}/20)..."; sleep 5
done

TRINO_SQL="CREATE SCHEMA IF NOT EXISTS minio.db_admin;"

# Drop views
for view in "${TRINO_VIEWS_CLEANUP[@]}"; do
  TRINO_SQL+=" DROP VIEW IF EXISTS minio.db_admin.${view};"
done

# Drop & recreate raw tables
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r _ iceberg_tbl _ _ _ <<< "$entry"
  TRINO_SQL+=" DROP TABLE IF EXISTS minio.db_admin.${iceberg_tbl}_raw;"
done

MINIO_COMMANDS=""
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r mysql_tbl iceberg_tbl _ _ _ <<< "$entry"
  var="TRINO_COLS_${iceberg_tbl}"
  trino_cols="${!var}"
  [ -z "$trino_cols" ] && continue
  
  escaped_trino_cols=$(python3 -c "
cols = '''${trino_cols}'''.split(',')
print(', '.join(['\"' + c.strip().split()[0] + '\" ' + ' '.join(c.strip().split()[1:]) for c in cols if c.strip()]))
")

  TRINO_SQL+="
CREATE TABLE IF NOT EXISTS minio.db_admin.${iceberg_tbl}_raw (
  ${escaped_trino_cols}
) WITH (
  external_location = 's3a://${BUCKET}/iceberg-data/${NAMESPACE}/${iceberg_tbl}/data/',
  format = 'PARQUET'
);"

  if [ "$iceberg_tbl" = "sys_files" ]; then
      MC_TARGET="local/${BUCKET}/iceberg-data/${NAMESPACE}/sys_files/data/.keep"
  else
      MC_TARGET="local/${BUCKET}/iceberg-data/${NAMESPACE}/${iceberg_tbl}/data/.keep"
  fi
  MINIO_COMMANDS+="echo '' | /tmp/mc pipe $MC_TARGET 2>/dev/null || true; "
done

echo ">>> Tạo 85 thư mục data rỗng trên MinIO..."
docker exec minio sh -c "$MINIO_COMMANDS"

# Analytics views
TRINO_SQL+="
CREATE VIEW minio.db_admin.dossier_summary AS
SELECT status, procedure_type,
  COUNT(*) AS total,
  SUM(CASE WHEN is_deleted=0 THEN 1 ELSE 0 END) AS active,
  ROUND(AVG(CAST(processed_at - submitted_at AS DOUBLE)/86400000),2) AS avg_days
FROM minio.db_admin.dossiers_raw
WHERE dossier_id IS NOT NULL AND submitted_at IS NOT NULL
GROUP BY status, procedure_type ORDER BY total DESC;

CREATE VIEW minio.db_admin.alert_dashboard AS
SELECT severity, status, alert_type, COUNT(*) AS total,
  SUM(CASE WHEN status <> 'RESOLVED' THEN 1 ELSE 0 END) AS active_count
FROM minio.db_admin.alerts_raw
WHERE alert_id IS NOT NULL
GROUP BY severity, status, alert_type ORDER BY total DESC;

CREATE VIEW minio.db_admin.registration_stats AS
SELECT procedure_code, procedure_name, status, COUNT(*) AS total,
  SUM(CASE WHEN amend_version > 0 THEN 1 ELSE 0 END) AS amended
FROM minio.db_admin.registrations_raw
WHERE id IS NOT NULL
GROUP BY procedure_code, procedure_name, status ORDER BY total DESC;

CREATE VIEW minio.db_admin.invoice_revenue AS
SELECT status, COUNT(*) AS invoice_count,
  ROUND(SUM(amount),0) AS total_amount,
  ROUND(AVG(amount),0) AS avg_amount
FROM minio.db_admin.invoices_raw
WHERE id IS NOT NULL
GROUP BY status ORDER BY total_amount DESC;

CREATE VIEW minio.db_admin.enterprise_activity AS
SELECT e.tax_code, e.enterprise_name,
  COUNT(DISTINCT d.dossier_id) AS dossier_count,
  COUNT(DISTINCT r.id) AS registration_count
FROM minio.db_admin.enterprise_raw e
LEFT JOIN minio.db_admin.dossiers_raw d ON e.tax_code = d.tax_code
LEFT JOIN minio.db_admin.registrations_raw r ON e.tax_code = r.enterprise_id
GROUP BY e.tax_code, e.enterprise_name ORDER BY dossier_count DESC;

CREATE VIEW minio.db_admin.dn_inspection_stats AS
SELECT result_content, COUNT(*) AS total,
  COUNT(DISTINCT inspection_dossier_id) AS unique_dossiers
FROM minio.db_admin.dn_inspection_result_raw
WHERE id IS NOT NULL
GROUP BY result_content ORDER BY total DESC;"

echo "$TRINO_SQL" | docker exec -i trino trino
echo "  OK"

# ─── DONE ─────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  ADMIN Pipeline DONE!"
echo "============================================"
echo "  MySQL  : 85 bang admin_db"
echo "  Kafka  : 85 topics"
echo "  Flink  : 85 passthrough jobs"
echo "  Trino  : 85 raw tables + 6 views"
echo ""
echo "  Flink UI : http://localhost:8081"
echo "  MinIO    : http://localhost:9001"
echo "  Trino    : http://localhost:8080"
echo ""
echo "Kiem tra:"
echo "  docker exec trino trino --execute \"SHOW TABLES IN minio.db_admin\" | wc -l"
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_admin.dossier_summary\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_admin.alert_dashboard\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_admin.registration_stats\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_admin.invoice_revenue\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_admin.enterprise_activity\""
echo "============================================"
