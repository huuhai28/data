#!/bin/bash
# =============================================================
#  pipeline_common.sh — Boilerplate dùng chung cho mọi pipeline
#  Source file này từ setup_<project>.sh:
#    source "$(dirname "$0")/pipeline_common.sh"
# =============================================================

# ─── JARs ─────────────────────────────────────────────────────
common::download_jars() {
  echo ">>> [JAR] Tải JARs cần thiết..."
  wget -q -nc https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.5.0/iceberg-aws-bundle-1.5.0.jar
  wget -q -nc https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
  wget -q -nc https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.18/1.5.0/iceberg-flink-runtime-1.18-1.5.0.jar
  echo "  ✅ JARs đã tải xong."
}

common::copy_jars_to_flink() {
  echo ">>> [JAR] Copy vào Flink containers..."
  local JARS=("iceberg-flink-runtime-1.18-1.5.0.jar" "iceberg-aws-bundle-1.5.0.jar" "flink-shaded-hadoop-2-uber-2.8.3-10.0.jar")
  for CONTAINER in flink-jobmanager flink-taskmanager flink-sql-client; do
    for JAR in "${JARS[@]}"; do
      docker cp "$JAR" "$CONTAINER:/opt/flink/lib/" 2>/dev/null || true
    done
  done
  echo "  ✅ JARs sẵn sàng trong Flink."
}

# ─── MYSQL ────────────────────────────────────────────────────
common::wait_for_mysql() {
  echo ">>> [MySQL] Đợi MySQL sẵn sàng..."
  until docker exec mysql mysqladmin ping -h localhost -p123 --silent 2>/dev/null; do
    echo -n "."; sleep 2
  done
  echo " OK!"
}

# ─── KAFKA ────────────────────────────────────────────────────
common::wait_for_kafka() {
  echo ">>> [Kafka] Đợi Kafka sẵn sàng..."
  until docker exec kafka kafka-topics \
    --bootstrap-server kafka:9092 --list > /dev/null 2>&1; do
    echo -n "."; sleep 2
  done
  echo " OK!"
}

common::wait_for_kafka_connect() {
  echo ">>> [Kafka Connect] Đợi Kafka Connect sẵn sàng..."
  until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
    echo -n "."; sleep 2
  done
  echo " OK!"
}

# ─── FLINK ────────────────────────────────────────────────────
common::wait_for_flink() {
  echo ">>> [Flink] Đợi Flink sẵn sàng..."
  until curl -s http://localhost:8081/overview > /dev/null 2>&1; do
    echo -n "."; sleep 2
  done
  echo " OK!"
}

# ─── TRINO ────────────────────────────────────────────────────
common::wait_for_trino() {
  echo ">>> [Trino] Đợi Trino sẵn sàng..."
  until docker exec trino trino --execute "SELECT 1" > /dev/null 2>&1; do
    echo -n "."; sleep 3
  done
  echo " OK!"
}

# ─── POLARIS ──────────────────────────────────────────────────
# Sau khi gọi hàm này, $TOKEN và $CREDENTIAL sẽ được export ra ngoài
common::get_polaris_token() {
  echo ">>> [Polaris] Chờ Polaris khởi động..."
  for i in $(seq 1 2); do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
      http://localhost:8181/api/catalog/v1/oauth/tokens 2>/dev/null || true)
    if [[ "$HTTP" == "400" || "$HTTP" == "401" || "$HTTP" == "200" ]]; then
      echo "  ✅ Polaris sẵn sàng."; break
    fi
    echo "  ... chờ Polaris (lần $i/20)..."; sleep 5
  done

  CREDENTIAL=$(docker logs polaris 2>&1 | grep -a "principal credentials" | tail -1 \
    | grep -oP '[0-9a-f]{16}:[0-9a-f]{32}' | tail -1)
  if [ -z "$CREDENTIAL" ]; then echo "❌ Không tìm được credential."; exit 1; fi
  echo "  Credential: $CREDENTIAL"

  TOKEN=$(curl -s -X POST \
    -H "X-Polaris-Realm: POLARIS" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -u "$CREDENTIAL" \
    -d "grant_type=client_credentials&scope=PRINCIPAL_ROLE:ALL" \
    "http://localhost:8181/api/catalog/v1/oauth/tokens" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
  export CREDENTIAL TOKEN
  echo "  ✅ Token lấy thành công."
}

# ─── CLEANUP ──────────────────────────────────────────────────
common::cleanup_flink_jobs() {
  echo ">>> [Cleanup] Cancel Flink jobs đang chạy..."
  local JOBS
  JOBS=$(docker exec flink-jobmanager curl -s http://localhost:8081/jobs \
    | python3 -c "import sys,json; [print(j['id']) for j in json.load(sys.stdin)['jobs'] if j['status'] in ('RUNNING', 'CREATED', 'RESTARTING', 'FAILING')]" 2>/dev/null || true)
  for JOB_ID in $JOBS; do
    docker exec flink-jobmanager curl -s -X PATCH \
      "http://localhost:8081/jobs/${JOB_ID}?mode=cancel" > /dev/null
    echo "  ❌ Đã cancel job: $JOB_ID"
  done
  [ -n "$JOBS" ] && sleep 5 || true
}

# common::cleanup_kafka_topics topic1 topic2 ...
common::cleanup_kafka_topics() {
  echo ">>> [Cleanup] Xóa Kafka topics..."
  for TOPIC in "$@"; do
    docker exec kafka kafka-topics \
      --bootstrap-server kafka:9092 \
      --delete --topic "$TOPIC" 2>/dev/null && \
      echo "  🗑️  Đã xóa: $TOPIC" || \
      echo "  ℹ️  Topic $TOPIC chưa tồn tại."
  done
  sleep 3
}

# common::cleanup_schema_history <project_name>
common::cleanup_schema_history() {
  local PROJECT_NAME="$1"
  echo ">>> [Cleanup] Xóa schema history topics của '$PROJECT_NAME'..."
  docker exec kafka kafka-topics --bootstrap-server kafka:9092 --list \
    | grep "schemahistory\.$PROJECT_NAME\." \
    | xargs -I {} docker exec kafka kafka-topics --bootstrap-server kafka:9092 --delete --topic {} 2>/dev/null || true
}

# common::cleanup_iceberg_tables <token> <catalog> <namespace> table1 table2 ...
common::cleanup_iceberg_tables() {
  local TOKEN_ARG="$1"
  local CATALOG="$2"
  local NAMESPACE="$3"
  shift 3
  echo ">>> [Cleanup] Xóa Iceberg tables trong ${CATALOG}.${NAMESPACE}..."
  for TABLE in "$@"; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      "http://localhost:8181/api/catalog/v1/${CATALOG}/namespaces/${NAMESPACE}/tables/${TABLE}" \
      -H "Authorization: Bearer $TOKEN_ARG" -H "X-Polaris-Realm: POLARIS")
    [ "$HTTP" = "204" ] && echo "  🗑️  Đã xóa: ${NAMESPACE}.${TABLE}" || \
      echo "  ℹ️  ${NAMESPACE}.${TABLE} chưa tồn tại."
  done
}

# common::cleanup_minio <bucket_name>
common::cleanup_minio() {
  local BUCKET="$1"
  echo ">>> [Cleanup] Dọn MinIO bucket: $BUCKET..."
  wget -q -nc https://dl.min.io/client/mc/release/linux-amd64/mc
  chmod +x mc
  docker cp mc minio:/tmp/mc
  docker exec minio sh -c "
    /tmp/mc alias set local http://localhost:9000 admin password --api S3v4 2>/dev/null
    /tmp/mc rm --recursive --force local/$BUCKET/ 2>/dev/null || true
    /tmp/mc mb local/$BUCKET --ignore-existing 2>/dev/null
  "
  echo "  ✅ MinIO bucket '$BUCKET' sẵn sàng."
}

# common::cleanup_debezium_connectors <keyword_in_name>
common::cleanup_debezium_connectors() {
  local KEYWORD="$1"
  echo ">>> [Cleanup] Xóa Debezium connectors chứa '$KEYWORD'..."
  local OLD_CONNECTORS
  OLD_CONNECTORS=$(curl -s http://localhost:8083/connectors \
    | python3 -c "import sys,json; [print(i) for i in json.load(sys.stdin) if '$KEYWORD' in i]" 2>/dev/null || true)
  for c in $OLD_CONNECTORS; do
    curl -s -X DELETE "http://localhost:8083/connectors/$c" > /dev/null
    echo "  🗑️  Đã xóa connector: $c"
  done
  sleep 2
}

# ─── DEBEZIUM ─────────────────────────────────────────────────
# common::register_debezium <json_template>
# Trong json_template, dùng placeholder __ID__ cho server.id, connector name, history topic.
# Sau khi gọi, $LAST_DEBEZIUM_ID chứa ID đã dùng.
common::register_debezium() {
  local JSON_TEMPLATE="$1"
  local RANDOM_ID=$((184000 + RANDOM % 1000))
  local FINAL_JSON="${JSON_TEMPLATE//__ID__/$RANDOM_ID}"

  echo ">>> [Debezium] Đăng ký connector (server.id=$RANDOM_ID)..."
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://localhost:8083/connectors/" \
    -H "Content-Type: application/json" \
    -d "$FINAL_JSON")
  [ "$HTTP" = "201" ] && echo "  ✅ Connector đã đăng ký (HTTP $HTTP)." || \
    echo "  ⚠️  HTTP $HTTP khi đăng ký connector."
  export LAST_DEBEZIUM_ID="$RANDOM_ID"
}

# common::wait_for_kafka_topic <topic_name>
common::wait_for_kafka_topic() {
  local TOPIC="$1"
  echo "  ⏳ Chờ Kafka topic '$TOPIC' xuất hiện..."
  until docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -q "$TOPIC"; do
    echo -n "."; sleep 2
  done
  echo " OK!"
}

# ─── POLARIS CATALOG ──────────────────────────────────────────
# common::create_polaris_catalog <token> <catalog_name> <s3_base_location>
# Ví dụ: common::create_polaris_catalog "$TOKEN" "crm" "s3://crm/"
common::create_polaris_catalog() {
  local TOKEN_ARG="$1"
  local CATALOG_NAME="$2"
  local S3_LOCATION="$3"
  echo ">>> [Polaris] Tạo catalog '$CATALOG_NAME'..."

  # Xoá catalog cũ nếu tồn tại để nạp lại đúng cấu hình Minio Endpoint
  curl -s -X DELETE "http://localhost:8181/api/management/v1/catalogs/$CATALOG_NAME" \
    -H "X-Polaris-Realm: POLARIS" \
    -H "Authorization: Bearer $TOKEN_ARG" > /dev/null || true

  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://localhost:8181/api/management/v1/catalogs" \
    -H "X-Polaris-Realm: POLARIS" \
    -H "Authorization: Bearer $TOKEN_ARG" \
    -H "Content-Type: application/json" \
    -d "{\"catalog\":{\"type\":\"INTERNAL\",\"name\":\"$CATALOG_NAME\",\"storageConfigInfo\":{\"storageType\":\"S3\",\"allowedLocations\":[\"$S3_LOCATION\"],\"pathStyleAccess\":true},\"properties\":{\"default-base-location\":\"${S3_LOCATION}iceberg-data\",\"s3.endpoint\":\"http://minio:9000\",\"s3.path-style-access\":\"true\",\"s3.access-key-id\":\"admin\",\"s3.secret-access-key\":\"password\",\"client.region\":\"us-east-1\"}}}")
  case "$HTTP" in
    201) echo "  ✅ Catalog '$CATALOG_NAME' đã được tạo." ;;
    409) echo "  ✅ Catalog '$CATALOG_NAME' đã tồn tại (409)." ;;
    400) echo "  ✅ Catalog '$CATALOG_NAME' đã tồn tại (400)." ;;
    *)   echo "  ⚠️  HTTP $HTTP khi tạo catalog." ;;
  esac
}

# ─── TRINO ────────────────────────────────────────────────────
# common::update_trino_token <token> [polaris_proxy_port=8282]
common::update_trino_token() {
  local TOKEN_ARG="$1"
  local PROXY_PORT="${2:-8282}"
  echo ">>> [Trino] Cập nhật iceberg.properties + restart..."
  mkdir -p trino-conf
  printf 'connector.name=iceberg\n' > trino-conf/iceberg.properties
  printf 'iceberg.catalog.type=rest\n' >> trino-conf/iceberg.properties
  printf "iceberg.rest-catalog.uri=http://polaris-proxy:%s/api/catalog\n" "$PROXY_PORT" >> trino-conf/iceberg.properties
  printf 'iceberg.rest-catalog.security=OAUTH2\n' >> trino-conf/iceberg.properties
  printf "iceberg.rest-catalog.oauth2.token=%s\n" "$TOKEN_ARG" >> trino-conf/iceberg.properties
  printf 'hive.s3.endpoint=http://minio:9000\n' >> trino-conf/iceberg.properties
  printf 'hive.s3.aws-access-key=admin\n' >> trino-conf/iceberg.properties
  printf 'hive.s3.aws-secret-key=password\n' >> trino-conf/iceberg.properties
  printf 'hive.s3.path-style-access=true\n' >> trino-conf/iceberg.properties
  printf 'hive.s3.ssl.enabled=false\n' >> trino-conf/iceberg.properties
  printf 'hive.s3.region=us-east-1\n' >> trino-conf/iceberg.properties
  docker restart trino > /dev/null 2>&1
  echo "  ✅ Trino đã được cập nhật và restart."
}

# ─── FLINK ────────────────────────────────────────────────────
# common::submit_flink_sql <local_sql_file_path>
common::submit_flink_sql() {
  local SQL_FILE="$1"
  local REMOTE_PATH="/tmp/$(basename "$SQL_FILE")"
  echo ">>> [Flink] Submit SQL: $(basename "$SQL_FILE")..."
  docker cp "$SQL_FILE" "flink-sql-client:$REMOTE_PATH"
  docker exec -i flink-sql-client ./bin/sql-client.sh \
    -Djobmanager.rpc.address=flink-jobmanager \
    -Djobmanager.rpc.port=6123 \
    -Drest.address=flink-jobmanager \
    -Drest.port=8081 \
    -f "$REMOTE_PATH"
  echo "  ✅ Flink SQL đã submit."
}