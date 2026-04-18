#!/bin/bash
# =============================================================
#  deploy_platform.sh — Trình quản lý triển khai vạn năng
#  Cách dùng: ./deploy_platform.sh [Project_Name]
#  Ví dụ: ./deploy_platform.sh hrm
# =============================================================
set -e
source "$(dirname "$0")/pipeline_common.sh"

PROJECT_NAME=$1
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Lỗi: Cần tên Project (ví dụ: ./deploy_platform.sh hrm)"
    exit 1
fi

# ─── [1] CẤU HÌNH BIẾN THEO PROJECT ──────────────────────────
# Bạn chỉ cần khai báo một lần ở đâygit
case "$PROJECT_NAME" in
  "hrm")
    SQL_SOURCE="sql/hrm_mysql.sql" 
    CATALOG="catalog_hrm"
    NAMESPACE="db_hrm"
    TOPIC_PREFIX="hrm_mysql"
    BUCKET="hrm-lake"
    ;;
  "admin")
    SQL_SOURCE="sql/admin_schema.sql"
    CATALOG="catalog_admin"
    NAMESPACE="db_admin"
    TOPIC_PREFIX="admin_mysql"
    BUCKET="admin-lake"
    ;;
  *)
    echo "❌ Lỗi: Dự án '$PROJECT_NAME' chưa được khai báo cấu hình."
    exit 1
    ;;
esac

echo "============================================"
echo "  🚀 DEPLOYING PLATFORM PROJECT: $PROJECT_NAME"
echo "============================================"

# ─── [2] KHỞI TẠO INFRA DÙNG COMMON ─────────────────────────
echo ">>> [2] Lấy Polaris Token..."
common::get_polaris_token 

# ─── [3] TỰ ĐỘNG SINH CODE (AUTOMATION) ──────────────────────
echo ">>> [3] Đang sinh code Flink SQL tự động..."
python3 gen_platform_pipeline.py "$PROJECT_NAME" "$SQL_SOURCE" "$CATALOG" "$NAMESPACE" "$TOPIC_PREFIX" "$CREDENTIAL"

# ─── [4] TỔNG VỆ SINH (CLEANUP) ──────────────────────────────
echo ">>> [4] Đang tổng vệ sinh dữ liệu cũ (HARD RESET)..."
common::cleanup_flink_jobs
common::cleanup_minio "$BUCKET"
common::cleanup_debezium_connectors "$PROJECT_NAME"

# RESET CỨNG POLARIS: Xóa toàn bộ Catalog để làm sạch Metadata
echo "  🧹 Đang xóa Catalog cũ '$CATALOG' trong Polaris để reset metadata..."
curl -s -X DELETE "http://localhost:8181/api/management/v1/catalogs/${CATALOG}" \
     -H "X-Polaris-Realm: POLARIS" \
     -H "Authorization: Bearer $TOKEN" || true

# Xóa Kafka topics dựa trên danh sách bảng (nếu có)
if [ -f "generated/${PROJECT_NAME}/tables.list" ]; then
  TABLES=$(cat "generated/${PROJECT_NAME}/tables.list")
  for T in $TABLES; do
    common::cleanup_kafka_topics "${TOPIC_PREFIX}.${PROJECT_NAME}.${T}"
  done
fi

echo ">>> [4b] Đang tạo Catalog MỚI '$CATALOG' trong Polaris..."
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" 

# ─── [5] DEBEZIUM ─────────────────────────────────────────────
DEBEZIUM_JSON="{\"name\": \"${PROJECT_NAME}-connector\",\"config\": {\"connector.class\": \"io.debezium.connector.mysql.MySqlConnector\",\"database.hostname\": \"mysql\",\"database.port\": \"3306\",\"database.user\": \"root\",\"database.password\": \"123\",\"database.server.id\": \"$(shuf -i 1000-9999 -n 1)\",\"topic.prefix\": \"$TOPIC_PREFIX\",\"database.include.list\": \"$PROJECT_NAME\",\"table.include.list\": \"${PROJECT_NAME}.*\",\"decimal.handling.mode\": \"double\"}}"
common::register_debezium "$DEBEZIUM_JSON"

# ─── [6] SUBMIT FLINK JOB ────────────────────────────────────
echo ">>> [6] Submit Flink Job..."
common::submit_flink_sql "generated/${PROJECT_NAME}/pipeline.sql"

echo "============================================"
echo "  ✅ DỰ ÁN $PROJECT_NAME ĐÃ LÊN SÀN!"
echo "============================================"
