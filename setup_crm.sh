#!/bin/bash
# =============================================================
#  setup_crm.sh — CRM Pipeline (dùng pipeline_common.sh)
#  MySQL → Debezium → Kafka → Flink → Iceberg (Polaris) → Trino → Superset
#
#  Phần đặc thù CRM:
#    - MySQL schema: customers, orders, products, order_items, customer_events
#    - Debezium: capture 5 bảng trên
#    - Flink SQL: 4 Iceberg sinks (customers, order_summary, product_catalog, order_items)
#    - Trino: 5 analytics views (order_summary, regional_summary,
#             category_revenue, top_products, customer_rfm)
# =============================================================
set -e
export MYSQL_PWD=123  # tránh warning "insecure password" gây exit

source "$(dirname "$0")/pipeline_common.sh"

PROJECT="crm"
BUCKET="crm"
CATALOG="crm"
NAMESPACE="db_crm"

echo "============================================"
echo "  CRM Pipeline: Customer & Order Realtime"
echo "============================================"
echo ""

# ─── [1] JARs ─────────────────────────────────────────────────
common::download_jars
common::copy_jars_to_flink

# ─── [2] MYSQL SCHEMA + DATA ──────────────────────────────────
echo ">>> [2] Tạo schema & seed data MySQL..."
common::wait_for_mysql

# set +e để tránh script chết vì warning/exit code không quan trọng của MySQL
set +e
docker exec -i mysql mysql -uroot -p123 \
  --default-character-set=utf8mb4 \
  --init-command="SET NAMES utf8mb4" <<'SQLEOF'
CREATE DATABASE IF NOT EXISTS crm;
USE crm;

CREATE TABLE IF NOT EXISTS customers (
  cus_id            INT PRIMARY KEY,
  name              VARCHAR(100) NOT NULL,
  email             VARCHAR(100) NOT NULL,
  create_at         DATE NOT NULL,
  region            VARCHAR(50),
  segment           VARCHAR(50),
  registered_channel VARCHAR(50)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orders (
  id       INT PRIMARY KEY AUTO_INCREMENT,
  cus_id   INT NOT NULL,
  amount   INT NOT NULL,
  order_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
  product_id INT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  category   VARCHAR(50)  NOT NULL,
  price      INT          NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS order_items (
  item_id    INT PRIMARY KEY AUTO_INCREMENT,
  order_id   INT NOT NULL,
  product_id INT NOT NULL,
  quantity   INT NOT NULL,
  unit_price INT NOT NULL
);

CREATE TABLE IF NOT EXISTS customer_events (
  event_id   INT PRIMARY KEY AUTO_INCREMENT,
  cus_id     INT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (cus_id, name, email, create_at, region, segment, registered_channel) VALUES
  (1,  'Nguyen Van A',  'nva@example.com', '2024-01-10', 'Bac',   'Premium',  'web'),
  (2,  'Tran Thi B',    'ttb@example.com', '2024-01-15', 'Nam',   'Standard', 'app'),
  (3,  'Le Van C',      'lvc@example.com', '2024-02-01', 'Trung', 'Premium',  'store'),
  (4,  'Pham Thi D',    'ptd@example.com', '2024-02-20', 'Nam',   'Budget',   'web'),
  (5,  'Hoang Van E',   'hve@example.com', '2024-03-05', 'Bac',   'Premium',  'app'),
  (6,  'Nguyen Van F',  'nvf@example.com', '2024-03-18', 'Trung', 'Standard', 'web'),
  (7,  'Tran Van G',    'tvg@example.com', '2024-04-02', 'Bac',   'Standard', 'store'),
  (8,  'Le Thi H',      'lth@example.com', '2024-04-10', 'Nam',   'Budget',   'app'),
  (9,  'Pham Van I',    'pvi@example.com', '2024-05-01', 'Trung', 'Premium',  'web'),
  (10, 'Hoang Thi K',   'htk@example.com', '2024-05-20', 'Bac',   'Standard', 'web'),
  (11, 'Do Minh L',     'dml@example.com', '2024-06-01', 'Nam',   'Premium',  'app'),
  (12, 'Vu Thi M',      'vtm@example.com', '2024-06-15', 'Bac',   'Budget',   'store'),
  (13, 'Bui Van N',     'bvn@example.com', '2024-07-01', 'Trung', 'Standard', 'web'),
  (14, 'Dang Thi O',    'dto@example.com', '2024-07-20', 'Nam',   'Premium',  'app'),
  (15, 'Nguyen Thi P',  'ntp@example.com', '2024-08-05', 'Bac',   'Budget',   'web')
ON DUPLICATE KEY UPDATE
  region=VALUES(region), segment=VALUES(segment),
  registered_channel=VALUES(registered_channel);

INSERT INTO products (product_id, name, category, price) VALUES
  (1,  'iPhone 15 Pro',         'Electronics', 30000000),
  (2,  'Samsung Galaxy S24',    'Electronics', 25000000),
  (3,  'Laptop Dell XPS',       'Electronics', 45000000),
  (4,  'Ao thun Premium',       'Fashion',        350000),
  (5,  'Quan Jean Levi',        'Fashion',        890000),
  (6,  'Giay Nike Air',         'Fashion',       2500000),
  (7,  'Bo noi inox 5 mon',     'Home',          1200000),
  (8,  'May loc khong khi',     'Home',          3500000),
  (9,  'Ca phe Arabica 500g',   'Food',           250000),
  (10, 'Chocolate Lindt hop',   'Food',           450000),
  (11, 'Tai nghe Sony WH-1000', 'Electronics',   8500000),
  (12, 'Dong ho Casio',         'Fashion',       1800000),
  (13, 'Robot hut bui',         'Home',          5000000),
  (14, 'Mat ong nguyen chat',   'Food',           320000),
  (15, 'May anh Canon EOS',     'Electronics',  20000000)
ON DUPLICATE KEY UPDATE name=VALUES(name), category=VALUES(category), price=VALUES(price);

INSERT INTO orders (cus_id, amount, order_at) VALUES
  (1,  30350000, '2026-04-01 10:00:00'),
  (1,   9390000, '2026-04-02 11:30:00'),
  (2,   1200000, '2026-04-01 14:00:00'),
  (2,   3500000, '2026-04-03 16:00:00'),
  (3,  45000000, '2026-04-01 08:30:00'),
  (3,   8850000, '2026-04-04 10:00:00'),
  (4,    800000, '2026-04-02 13:00:00'),
  (4,    700000, '2026-04-05 15:00:00'),
  (5,  38500000, '2026-04-01 09:00:00'),
  (5,   8500000, '2026-04-03 11:00:00'),
  (6,   6700000, '2026-04-02 10:00:00'),
  (7,   4300000, '2026-04-01 12:00:00'),
  (7,   2000000, '2026-04-04 14:00:00'),
  (8,    900000, '2026-04-03 09:00:00'),
  (9,  53500000, '2026-04-02 11:00:00'),
  (9,   8500000, '2026-04-04 16:00:00'),
  (10, 31800000, '2026-04-01 10:30:00'),
  (10,  2000000, '2026-04-05 13:00:00'),
  (11, 30350000, '2026-04-01 09:00:00'),
  (11,   450000, '2026-04-03 14:00:00'),
  (12,   350000, '2026-04-02 11:00:00'),
  (13,  3500000, '2026-04-01 10:00:00'),
  (14, 55000000, '2026-04-02 09:00:00'),
  (15,   250000, '2026-04-03 15:00:00');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1,  1,  1, 30000000), (1,  10, 1,   350000),
  (2,  11, 1,  8500000), (2,  9,  1,   250000), (2,  14, 2, 320000),
  (3,  4,  2,   350000), (3,  9,  1,   250000),
  (4,  8,  1,  3500000),
  (5,  3,  1, 45000000),
  (6,  11, 1,  8500000), (6,  10, 1,   350000),
  (7,  5,  1,   800000),
  (8,  9,  2,   250000), (8,  14, 1,   200000),
  (9,  1,  1, 30000000), (9,  11, 1,  8500000),
  (10, 11, 1,  8500000),
  (11, 13, 1,  5000000), (11, 8,  1,  1700000),
  (12, 7,  2,  1200000), (12, 14, 2,   320000),
  (13, 12, 1,  2000000),
  (14, 7,  1,  1200000),
  (15, 3,  1, 45000000), (15, 15, 1,  8500000),
  (16, 11, 1,  8500000),
  (17, 15, 1, 20000000), (17, 1,  1, 11800000),
  (18, 8,  1,  2000000),
  (19, 1,  1, 30000000), (19, 10, 1,   350000),
  (20, 10, 1,   450000),
  (21, 4,  1,   350000),
  (22, 13, 1,  3500000),
  (23, 3,  1, 45000000), (23, 1,  1, 10000000),
  (24, 9,  1,   250000);

INSERT INTO customer_events (cus_id, event_type, event_at) VALUES
  (1, 'login',        '2026-04-01 09:00:00'),
  (1, 'view_product', '2026-04-01 09:05:00'),
  (1, 'add_to_cart',  '2026-04-01 09:10:00'),
  (1, 'purchase',     '2026-04-01 10:00:00'),
  (2, 'login',        '2026-04-01 13:00:00'),
  (2, 'view_product', '2026-04-01 13:30:00'),
  (2, 'purchase',     '2026-04-01 14:00:00'),
  (3, 'login',        '2026-04-01 08:00:00'),
  (3, 'view_product', '2026-04-01 08:15:00'),
  (3, 'add_to_cart',  '2026-04-01 08:20:00'),
  (3, 'purchase',     '2026-04-01 08:30:00'),
  (4, 'login',        '2026-04-02 12:00:00'),
  (4, 'view_product', '2026-04-02 12:30:00'),
  (4, 'purchase',     '2026-04-02 13:00:00'),
  (5, 'login',        '2026-04-01 08:30:00'),
  (5, 'view_product', '2026-04-01 08:45:00'),
  (5, 'add_to_cart',  '2026-04-01 08:50:00'),
  (5, 'purchase',     '2026-04-01 09:00:00'),
  (6, 'login',        '2026-04-02 09:30:00'),
  (6, 'view_product', '2026-04-02 09:45:00'),
  (6, 'purchase',     '2026-04-02 10:00:00'),
  (7, 'login',        '2026-04-01 11:00:00'),
  (7, 'view_product', '2026-04-01 11:30:00'),
  (7, 'purchase',     '2026-04-01 12:00:00'),
  (8, 'login',        '2026-04-03 08:30:00'),
  (8, 'view_product', '2026-04-03 08:45:00'),
  (8, 'purchase',     '2026-04-03 09:00:00'),
  (9, 'login',        '2026-04-02 10:00:00'),
  (9, 'view_product', '2026-04-02 10:15:00'),
  (9, 'add_to_cart',  '2026-04-02 10:45:00'),
  (9, 'purchase',     '2026-04-02 11:00:00'),
  (10,'login',        '2026-04-01 10:00:00'),
  (10,'view_product', '2026-04-01 10:15:00'),
  (10,'purchase',     '2026-04-01 10:30:00'),
  (1, 'login',        '2026-04-05 09:00:00'),
  (1, 'view_product', '2026-04-05 09:10:00'),
  (14,'login',        '2026-04-02 08:30:00'),
  (14,'view_product', '2026-04-02 08:45:00'),
  (14,'add_to_cart',  '2026-04-02 08:55:00'),
  (14,'purchase',     '2026-04-02 09:00:00');
SQLEOF
set -e

echo "  ✅ MySQL: CRM schema & seed data sẵn sàng."
echo ""

# ─── [3] POLARIS TOKEN ────────────────────────────────────────
common::get_polaris_token

# ─── [4] CLEANUP ──────────────────────────────────────────────
echo ">>> [4] Dọn dẹp data cũ..."
common::cleanup_flink_jobs
common::cleanup_kafka_topics \
  "crm.crm.customers" "crm.crm.orders" \
  "crm.crm.products"  "crm.crm.order_items" "crm.crm.customer_events"
common::cleanup_schema_history "$PROJECT"
common::cleanup_iceberg_tables "$TOKEN" "$CATALOG" "$NAMESPACE" \
  "customers" "order_summary" "product_catalog" "order_items"
common::cleanup_minio "$BUCKET"
common::cleanup_debezium_connectors "crm-connector"
echo "  ✅ Dọn dẹp xong."
echo ""

# ─── [5] DEBEZIUM ─────────────────────────────────────────────
echo ">>> [5] Đăng ký Debezium connector..."

DEBEZIUM_JSON='{
  "name": "crm-connector-__ID__",
  "config": {
    "connector.class":  "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max":        "1",
    "database.hostname": "mysql",
    "database.port":    "3306",
    "database.user":    "root",
    "database.password":"123",
    "database.server.id": "__ID__",
    "snapshot.mode":    "initial",
    "topic.prefix":     "crm",
    "database.include.list": "crm",
    "table.include.list": "crm.customers,crm.orders,crm.products,crm.order_items,crm.customer_events",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "schemahistory.crm.__ID__"
  }
}'

common::register_debezium "$DEBEZIUM_JSON"
common::wait_for_kafka_topic "crm.crm.customers"

# ─── [6] POLARIS CATALOG + TRINO ──────────────────────────────
common::create_polaris_catalog "$TOKEN" "$CATALOG" "s3://$BUCKET/"
common::update_trino_token "$TOKEN" "8282"

# ─── [7] FLINK SQL ────────────────────────────────────────────
echo ">>> [7] Submit Flink SQL pipeline..."

cat > /tmp/crm_pipeline.sql << EOF
SET 'execution.checkpointing.interval' = '60s';
SET 'table.exec.sink.upsert-materialize' = 'AUTO';

DROP CATALOG IF EXISTS crm_catalog;
CREATE CATALOG crm_catalog WITH (
  'type'                 = 'iceberg',
  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',
  'uri'                  = 'http://polaris:8181/api/catalog',
  'credential'           = '${CREDENTIAL}',
  'warehouse'            = 'crm',
  'scope'                = 'PRINCIPAL_ROLE:ALL',
  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint'          = 'http://minio:9000',
  's3.region'            = 'us-east-1',
  's3.path-style-access' = 'true',
  's3.access-key-id'     = 'admin',
  's3.secret-access-key' = 'password',
  'client.region'        = 'us-east-1'
);

USE CATALOG crm_catalog;
CREATE DATABASE IF NOT EXISTS db_crm;

-- ── Iceberg: customers ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_crm.customers (
  cus_id INT, name STRING, email STRING, create_at INT,
  region STRING, segment STRING, registered_channel STRING,
  PRIMARY KEY (cus_id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: order_summary ────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_crm.order_summary (
  cus_id INT, total_amount BIGINT, order_count BIGINT,
  status STRING, last_order_at BIGINT,
  PRIMARY KEY (cus_id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: product_catalog ──────────────────────────────────
CREATE TABLE IF NOT EXISTS db_crm.product_catalog (
  product_id INT, name STRING, category STRING, price INT,
  PRIMARY KEY (product_id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

-- ── Iceberg: order_items ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS db_crm.order_items (
  item_id INT, order_id INT, product_id INT, quantity INT, unit_price INT,
  PRIMARY KEY (item_id) NOT ENFORCED
) WITH (
  'write.upsert.enabled'             = 'true',
  'format-version'                   = '2',
  'write.parquet.column-ids-enabled' = 'false'
);

USE CATALOG default_catalog;
USE default_database;

-- ── Kafka source: customers ───────────────────────────────────
DROP TABLE IF EXISTS customers_kafka;
CREATE TABLE customers_kafka (
  cus_id INT, name STRING, email STRING, create_at INT,
  region STRING, segment STRING, registered_channel STRING,
  PRIMARY KEY (cus_id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'crm.crm.customers',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-crm-customers',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: orders ──────────────────────────────────────
DROP TABLE IF EXISTS orders_kafka;
CREATE TABLE orders_kafka (
  id INT, cus_id INT, amount INT, order_at BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'crm.crm.orders',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-crm-orders',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: products ────────────────────────────────────
DROP TABLE IF EXISTS products_kafka;
CREATE TABLE products_kafka (
  product_id INT, name STRING, category STRING, price INT,
  PRIMARY KEY (product_id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'crm.crm.products',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-crm-products',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── Kafka source: order_items ─────────────────────────────────
DROP TABLE IF EXISTS order_items_kafka;
CREATE TABLE order_items_kafka (
  item_id INT, order_id INT, product_id INT, quantity INT, unit_price INT,
  PRIMARY KEY (item_id) NOT ENFORCED
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'crm.crm.order_items',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-crm-order-items',
  'scan.startup.mode'            = 'earliest-offset',
  'format'                       = 'debezium-json',
  'debezium-json.schema-include' = 'true'
);

-- ── INSERT: customers → Iceberg ───────────────────────────────
INSERT INTO crm_catalog.db_crm.customers
SELECT cus_id, name, email, create_at, region, segment, registered_channel
FROM customers_kafka;

-- ── INSERT: order_summary (aggregated) ───────────────────────
INSERT INTO crm_catalog.db_crm.order_summary
SELECT
  cus_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count,
  CASE
    WHEN SUM(amount) >= 50000000 THEN 'VIP'
    WHEN SUM(amount) >= 10000000 THEN 'HIGH_VALUE'
    ELSE 'NORMAL'
  END          AS status,
  MAX(order_at) AS last_order_at
FROM orders_kafka
WHERE cus_id IS NOT NULL AND amount IS NOT NULL
GROUP BY cus_id;

-- ── INSERT: products → Iceberg ────────────────────────────────
INSERT INTO crm_catalog.db_crm.product_catalog
SELECT product_id, name, category, price
FROM products_kafka;

-- ── INSERT: order_items → Iceberg ────────────────────────────
INSERT INTO crm_catalog.db_crm.order_items
SELECT item_id, order_id, product_id, quantity, unit_price
FROM order_items_kafka;
EOF

common::submit_flink_sql /tmp/crm_pipeline.sql

# ─── [8] TRINO TABLES & VIEWS ─────────────────────────────────
echo ">>> [8] Chờ Flink checkpoint đầu tiên (90s)..."
sleep 90

echo ">>> [8b] Tạo MinIO placeholder dirs..."
docker exec minio sh -c "
  for DIR in customers order_summary product_catalog order_items; do
    echo '' | /tmp/mc pipe local/crm/iceberg-data/db_crm/\$DIR/data/.keep 2>/dev/null || true
  done
"

echo ">>> [8c] Tạo Trino tables & views..."
docker exec trino trino --execute "
CREATE SCHEMA IF NOT EXISTS minio.db_crm;

-- Dọn cũ
DROP VIEW  IF EXISTS minio.db_crm.customer_rfm;
DROP VIEW  IF EXISTS minio.db_crm.top_products;
DROP VIEW  IF EXISTS minio.db_crm.category_revenue;
DROP VIEW  IF EXISTS minio.db_crm.regional_summary;
DROP VIEW  IF EXISTS minio.db_crm.order_summary;
DROP TABLE IF EXISTS minio.db_crm.order_items_raw;
DROP TABLE IF EXISTS minio.db_crm.product_catalog;
DROP TABLE IF EXISTS minio.db_crm.order_summary_raw;
DROP TABLE IF EXISTS minio.db_crm.customers;

-- ── Raw tables (đọc trực tiếp từ Parquet trên MinIO) ─────────
CREATE TABLE minio.db_crm.customers (
  cus_id INTEGER, name VARCHAR, email VARCHAR, create_at INTEGER,
  region VARCHAR, segment VARCHAR, registered_channel VARCHAR
) WITH (
  external_location = 's3://crm/iceberg-data/db_crm/customers/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_crm.order_summary_raw (
  cus_id INTEGER, total_amount BIGINT, order_count BIGINT,
  status VARCHAR, last_order_at BIGINT
) WITH (
  external_location = 's3://crm/iceberg-data/db_crm/order_summary/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_crm.product_catalog (
  product_id INTEGER, name VARCHAR, category VARCHAR, price INTEGER
) WITH (
  external_location = 's3://crm/iceberg-data/db_crm/product_catalog/data/',
  format = 'PARQUET'
);

CREATE TABLE minio.db_crm.order_items_raw (
  item_id INTEGER, order_id INTEGER, product_id INTEGER,
  quantity INTEGER, unit_price INTEGER
) WITH (
  external_location = 's3://crm/iceberg-data/db_crm/order_items/data/',
  format = 'PARQUET'
);

-- ── View: order_summary (dedup bởi MAX) ──────────────────────
CREATE VIEW minio.db_crm.order_summary AS
SELECT cus_id,
       MAX(total_amount)  AS total_amount,
       MAX(order_count)   AS order_count,
       MAX(status)        AS status,
       MAX(last_order_at) AS last_order_at
FROM minio.db_crm.order_summary_raw
WHERE cus_id IS NOT NULL AND total_amount IS NOT NULL
GROUP BY cus_id;

-- ── View: regional_summary ────────────────────────────────────
CREATE VIEW minio.db_crm.regional_summary AS
SELECT c.region,
       COUNT(DISTINCT c.cus_id) AS customer_count,
       SUM(o.total_amount)      AS total_revenue,
       SUM(o.order_count)       AS total_orders
FROM minio.db_crm.customers c
JOIN minio.db_crm.order_summary o ON c.cus_id = o.cus_id
WHERE c.region IS NOT NULL
GROUP BY c.region
ORDER BY total_revenue DESC;

-- ── View: category_revenue ────────────────────────────────────
CREATE VIEW minio.db_crm.category_revenue AS
SELECT p.category,
       SUM(oi.quantity * oi.unit_price) AS total_revenue,
       COUNT(DISTINCT oi.order_id)      AS order_count,
       SUM(oi.quantity)                 AS total_qty
FROM minio.db_crm.order_items_raw oi
JOIN minio.db_crm.product_catalog p ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ── View: top_products ────────────────────────────────────────
CREATE VIEW minio.db_crm.top_products AS
SELECT p.product_id, p.name, p.category, p.price,
       SUM(oi.quantity * oi.unit_price) AS total_revenue,
       SUM(oi.quantity)                 AS total_qty,
       COUNT(DISTINCT oi.order_id)      AS order_count
FROM minio.db_crm.order_items_raw oi
JOIN minio.db_crm.product_catalog p ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL
GROUP BY p.product_id, p.name, p.category, p.price
ORDER BY total_revenue DESC;

-- ── View: customer_rfm ────────────────────────────────────────
CREATE VIEW minio.db_crm.customer_rfm AS
SELECT
  c.cus_id, c.name, c.region, c.segment, c.registered_channel,
  o.order_count  AS frequency,
  o.total_amount AS monetary,
  o.status,
  CASE
    WHEN o.order_count >= 3 AND o.total_amount >= 10000000 THEN 'Champions'
    WHEN o.order_count >= 2 AND o.total_amount >= 5000000  THEN 'Loyal'
    WHEN o.order_count = 1  AND o.total_amount >= 10000000 THEN 'Big Spender'
    WHEN o.order_count = 1                                  THEN 'New Customer'
    ELSE 'At Risk'
  END AS rfm_tier
FROM minio.db_crm.customers c
JOIN minio.db_crm.order_summary o ON c.cus_id = o.cus_id;

-- ── Verify ────────────────────────────────────────────────────
SELECT 'customers'      AS tbl, COUNT(*) AS rows FROM minio.db_crm.customers
UNION ALL
SELECT 'order_summary',          COUNT(*) FROM minio.db_crm.order_summary
UNION ALL
SELECT 'product_catalog',        COUNT(*) FROM minio.db_crm.product_catalog
UNION ALL
SELECT 'order_items_raw',        COUNT(*) FROM minio.db_crm.order_items_raw;
" && echo "  ✅ Trino tables & views sẵn sàng." || echo "  ⚠️ Xem lại Trino."

echo ""
echo "============================================"
echo "  ✅ CRM Pipeline đã khởi chạy!"
echo "============================================"
echo "  Flink UI  : http://localhost:8081"
echo "  MinIO     : http://localhost:9001  (admin/password)"
echo "  Kafka UI  : http://localhost:8089"
echo "  Trino     : http://localhost:8080"
echo "  Superset  : http://localhost:8088"
echo ""
echo "  Superset URI: trino://admin@trino:8080/minio/db_crm"
echo ""
echo "Kiểm tra analytics:"
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_crm.customer_rfm ORDER BY monetary DESC\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_crm.category_revenue\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_crm.regional_summary\""
echo "  docker exec trino trino --execute \"SELECT * FROM minio.db_crm.top_products LIMIT 5\""
echo ""
echo "Chạy demo realtime: ./demo_crm.sh"
