#!/bin/bash
# =============================================================
#  setup_hrm.sh — HRM Pipeline (Config-driven)
#  MySQL → Debezium → Kafka → Flink → Iceberg (Polaris) → Trino
#
#  ✅ Thêm bảng mới: CHỈ sửa conf/hrm_tables.sh
#     Script này tự động loop qua TABLES_REGISTRY
# =============================================================
set -e
export MYSQL_PWD=123

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/pipeline_common.sh"
source "$SCRIPT_DIR/conf/hrm_tables.sh"

PROJECT="hrm"
BUCKET="hrm"
CATALOG="hrm"
NAMESPACE="db_hrm"
TOPIC_PREFIX="hrm"
DB_NAME="hrm"
FLINK_SQL="/tmp/${PROJECT}_pipeline.sql"

echo "============================================"
echo "  HRM Pipeline: Cham cong Realtime"
echo "  So bang: ${#TABLES_REGISTRY[@]}"
echo "============================================"
echo ""

# ── [1] JARs ──────────────────────────────────────────────────
common::download_jars
common::copy_jars_to_flink

# ── [2] MySQL ─────────────────────────────────────────────────
echo ">>> [2] Tao schema & seed data MySQL..."
common::wait_for_mysql
docker exec -i mysql mysql -uroot -p123 \
  --default-character-set=utf8mb4 \
  --init-command="SET NAMES utf8mb4" \
  < "$SCRIPT_DIR/sql/hrm_mysql.sql"
echo "  ✅ MySQL: ${#TABLES_REGISTRY[@]} bang san sang."
echo ""

# ── [3] Polaris Token ──────────────────────────────────────────
common::get_polaris_token

# ── [4] Cleanup ────────────────────────────────────────────────
echo ">>> [4] Don dep data cu..."
common::cleanup_flink_jobs

# Auto-build danh sách Kafka topics từ TABLES_REGISTRY
KAFKA_TOPICS=()
for entry in "${TABLES_REGISTRY[@]}"; do
  MYSQL_TABLE="${entry%%|*}"
  KAFKA_TOPICS+=("${TOPIC_PREFIX}.${DB_NAME}.${MYSQL_TABLE}")
done
common::cleanup_kafka_topics "${KAFKA_TOPICS[@]}"
common::cleanup_schema_history "$PROJECT"
common::cleanup_iceberg_tables "$TOKEN" "$CATALOG" "$NAMESPACE" "${ICEBERG_CLEANUP[@]}"
common::cleanup_minio "$BUCKET"
common::cleanup_debezium_connectors "hrm-connector"
echo "  ✅ Don dep xong."
echo ""

# ── [5] Debezium ───────────────────────────────────────────────
echo ">>> [5] Dang ky Debezium connector..."

# Auto-build table.include.list từ TABLES_REGISTRY
TABLE_INCLUDE_LIST=""
for entry in "${TABLES_REGISTRY[@]}"; do
  MYSQL_TABLE="${entry%%|*}"
  TABLE_INCLUDE_LIST+="${DB_NAME}.${MYSQL_TABLE},"
done
TABLE_INCLUDE_LIST="${TABLE_INCLUDE_LIST%,}"  # bỏ dấu phẩy cuối

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
    "topic.prefix":     "'"$TOPIC_PREFIX"'",
    "database.include.list": "'"$DB_NAME"'",
    "table.include.list": "'"$TABLE_INCLUDE_LIST"'",
    "decimal.handling.mode": "double",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "schemahistory.hrm.__ID__"
  }
}'

common::register_debezium "$DEBEZIUM_JSON"
common::wait_for_kafka_topic "${TOPIC_PREFIX}.${DB_NAME}.employees"

# ── [6] Polaris Catalog + Trino Token ─────────────────────────
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" "8282"

# ── [7] Flink SQL (auto-generated) ────────────────────────────
echo ">>> [7] Sinh & Submit Flink SQL pipeline..."

# Header: catalog + checkpoint config
cat > "$FLINK_SQL" <<EOF
SET 'execution.checkpointing.interval' = '60s';
SET 'table.exec.sink.upsert-materialize' = 'AUTO';

DROP CATALOG IF EXISTS ${CATALOG}_catalog;
CREATE CATALOG ${CATALOG}_catalog WITH (
  'type'                 = 'iceberg',
  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',
  'uri'                  = 'http://polaris:8181/api/catalog',
  'credential'           = '${CREDENTIAL}',
  'warehouse'            = '${CATALOG}',
  'scope'                = 'PRINCIPAL_ROLE:ALL',
  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'          = 'http://minio:9000',
  's3.region'            = 'us-east-1',
  's3.path-style-access' = 'true',
  's3.access-key-id'     = 'admin',
  's3.secret-access-key' = 'password',
  'client.region'        = 'us-east-1'
);

USE CATALOG ${CATALOG}_catalog;
CREATE DATABASE IF NOT EXISTS ${NAMESPACE};
EOF

# Loop 1: Tạo tất cả Iceberg sink tables
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r MYSQL_TABLE ICEBERG_TABLE PK KAFKA_GROUP TRANSFORM <<< "$entry"
  ICEBERG_COLS_VAR="ICEBERG_COLS_${ICEBERG_TABLE}"
  common::gen_iceberg_to_file "$FLINK_SQL" \
    "${CATALOG}_catalog" "$NAMESPACE" "$ICEBERG_TABLE" "$PK" "${!ICEBERG_COLS_VAR}"
done

# Switch sang default catalog để tạo Kafka sources
cat >> "$FLINK_SQL" <<'EOF'

USE CATALOG default_catalog;
USE default_database;
EOF

# Loop 2: Tạo tất cả Kafka source tables
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r MYSQL_TABLE ICEBERG_TABLE PK KAFKA_GROUP TRANSFORM <<< "$entry"
  KAFKA_COLS_VAR="KAFKA_COLS_${MYSQL_TABLE}"
  TOPIC="${TOPIC_PREFIX}.${DB_NAME}.${MYSQL_TABLE}"
  common::gen_kafka_to_file "$FLINK_SQL" \
    "$MYSQL_TABLE" "$TOPIC" "$KAFKA_GROUP" "$PK" "${!KAFKA_COLS_VAR}"
done

# Loop 3: Tạo INSERT statements
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r MYSQL_TABLE ICEBERG_TABLE PK KAFKA_GROUP TRANSFORM <<< "$entry"

  if [ "$TRANSFORM" = "passthrough" ]; then
    # Auto-gen: SELECT trực tiếp từ kafka → iceberg
    SELECT_COLS_VAR="SELECT_COLS_${MYSQL_TABLE}"
    cat >> "$FLINK_SQL" <<SQL

-- INSERT: ${MYSQL_TABLE} → ${ICEBERG_TABLE} (passthrough)
INSERT INTO ${CATALOG}_catalog.${NAMESPACE}.${ICEBERG_TABLE}
SELECT ${!SELECT_COLS_VAR} FROM ${MYSQL_TABLE}_kafka;
SQL
  else
    # Custom transform: đọc từ file sql/flink_custom_<iceberg_table>.sql
    CUSTOM_FILE="$SCRIPT_DIR/sql/flink_custom_${ICEBERG_TABLE}.sql"
    if [ -f "$CUSTOM_FILE" ]; then
      # Thay __CATALOG__ bằng tên catalog thực
      sed "s/__CATALOG__/${CATALOG}_catalog/g" "$CUSTOM_FILE" >> "$FLINK_SQL"
    else
      echo "  ⚠️  Không tìm thấy: $CUSTOM_FILE — bỏ qua."
    fi
  fi
done

common::submit_flink_sql "$FLINK_SQL"

# ── [8] Trino Tables & Views ───────────────────────────────────
echo ">>> [8] Cho Flink checkpoint dau tien (90s)..."
sleep 90

echo ">>> [8b] Tao MinIO placeholder dirs..."
ICEBERG_DIRS="${ICEBERG_CLEANUP[*]}"
docker exec minio sh -c "
  for DIR in $ICEBERG_DIRS; do
    echo '' | /tmp/mc pipe local/$BUCKET/iceberg-data/$NAMESPACE/\$DIR/data/.keep 2>/dev/null || true
  done
"

echo ">>> [8c] Tao Trino tables & views..."

# Build Trino SQL: cleanup cũ
TRINO_SQL="CREATE SCHEMA IF NOT EXISTS minio.${NAMESPACE};"
for v in "${TRINO_VIEWS_CLEANUP[@]}"; do
  TRINO_SQL+=" DROP VIEW  IF EXISTS minio.${NAMESPACE}.${v};"
done
for t in "${TRINO_TABLES_CLEANUP[@]}"; do
  TRINO_SQL+=" DROP TABLE IF EXISTS minio.${NAMESPACE}.${t};"
done

# Loop: tạo Trino raw tables từ TABLES_REGISTRY
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r MYSQL_TABLE ICEBERG_TABLE PK KAFKA_GROUP TRANSFORM <<< "$entry"
  TRINO_COLS_VAR="TRINO_COLS_${ICEBERG_TABLE}"
  TRINO_TABLE_VAR="TRINO_TABLE_${ICEBERG_TABLE}"
  TRINO_TBL="${!TRINO_TABLE_VAR}"
  S3_LOC="s3://${BUCKET}/iceberg-data/${NAMESPACE}/${ICEBERG_TABLE}/data/"

  # Dùng temp file để gen DDL sạch rồi đọc vào TRINO_SQL
  TMP_DDL="$(mktemp)"
  common::gen_trino_raw_to_file "$TMP_DDL" "$NAMESPACE" "$TRINO_TBL" "$S3_LOC" "${!TRINO_COLS_VAR}"
  TRINO_SQL+=" $(cat "$TMP_DDL")"
  rm -f "$TMP_DDL"
done

# Append analytics views (luôn là logic nghiệp vụ riêng)
TRINO_SQL+=" $(cat "$SCRIPT_DIR/sql/hrm_trino_views.sql")"

# Verify row counts
TRINO_SQL+="
SELECT 'employees'          AS tbl, COUNT(*) AS rows FROM minio.${NAMESPACE}.employees
UNION ALL SELECT 'attendance_raw',      COUNT(*) FROM minio.${NAMESPACE}.attendance_raw
UNION ALL SELECT 'leave_requests_raw',  COUNT(*) FROM minio.${NAMESPACE}.leave_requests_raw
UNION ALL SELECT 'payroll_raw',         COUNT(*) FROM minio.${NAMESPACE}.payroll_raw;"

docker exec trino trino --execute "$TRINO_SQL" \
  && echo "  ✅ Trino tables & views san sang." \
  || echo "  ⚠️ Xem lai Trino."

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
