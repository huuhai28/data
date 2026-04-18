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
# Bạn chỉ cần khai báo một lần ở đây
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
echo ">>> [2] Chuẩn bị hạ tầng (Polaris Token, MinIO)..."
common::get_polaris_token # Phải lấy Token trước để có CREDENTIAL

# ─── [3] TỰ ĐỘNG SINH CODE (AUTOMATION) ──────────────────────
echo ">>> [3] Đang sinh code Flink SQL tự động..."
python3 gen_platform_pipeline.py "$PROJECT_NAME" "$SQL_SOURCE" "$CATALOG" "$NAMESPACE" "$TOPIC_PREFIX" "$CREDENTIAL"

# ─── [4] CẤU HÌNH TIẾP ───────────────────────────────────────
common::download_jars
common::copy_jars_to_flink
common::cleanup_minio "$BUCKET"
common::cleanup_debezium_connectors "$PROJECT_NAME"

# Đăng ký Debezium (Dùng Wildcard cho hàng ngàn bảng)
DEBEZIUM_JSON="{
  \"name\": \"${PROJECT_NAME}-connector\",
  \"config\": {
    \"connector.class\": \"io.debezium.connector.mysql.MySqlConnector\",
    \"database.hostname\": \"mysql\",
    \"database.port\": \"3306\",
    \"database.user\": \"root\",
    \"database.password\": \"123\",
    \"database.server.id\": \"$(shuf -i 1000-9999 -n 1)\",
    \"topic.prefix\": \"$TOPIC_PREFIX\",
    \"database.include.list\": \"$PROJECT_NAME\",
    \"table.include.list\": \"${PROJECT_NAME}.*\",
    \"decimal.handling.mode\": \"double\"
  }
}"
common::register_debezium "$DEBEZIUM_JSON"

# ─── [4] SUBMIT FLINK JOB ────────────────────────────────────
echo ">>> [4] Đang gửi Job lên Flink..."
common::submit_flink_sql "generated/${PROJECT_NAME}/pipeline.sql"

echo "============================================"
echo "  ✅ DỰ ÁN $PROJECT_NAME ĐÃ LÊN SÀN!"
echo "============================================"
