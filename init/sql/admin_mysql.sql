-- ================================================================
--  admin_mysql.sql  — Schema ADMIN (convert từ Oracle → MySQL)
--  20 bảng cốt lõi, bỏ CLOB/BLOB và bảng nội bộ
-- ================================================================
CREATE DATABASE IF NOT EXISTS admin_db CHARACTER SET utf8mb4;
USE admin_db;

-- ── Group 1: Tổ chức hành chính ──────────────────────────────

CREATE TABLE IF NOT EXISTS adm_ministry (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  order_no        INT,
  ministry_code   VARCHAR(50)  NOT NULL UNIQUE,
  ministry_name   VARCHAR(255) NOT NULL,
  description     VARCHAR(500),
  is_active       TINYINT(1) DEFAULT 1,
  created_at      DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  version         INT DEFAULT 0,
  created_by      VARCHAR(50),
  updated_at      DATETIME(6),
  updated_by      VARCHAR(50),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS adm_department (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  ministry_code   VARCHAR(50)  NOT NULL,
  department_code VARCHAR(50)  NOT NULL,
  department_name VARCHAR(255) NOT NULL,
  is_active       TINYINT(1) DEFAULT 1,
  is_primary      TINYINT(1) DEFAULT 0,
  created_at      DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  version         INT DEFAULT 0,
  created_by      VARCHAR(50),
  updated_at      DATETIME(6),
  updated_by      VARCHAR(50),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS adm_branch (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  department_code VARCHAR(50)  NOT NULL,
  unit_code       VARCHAR(50)  NOT NULL,
  unit_name       VARCHAR(255) NOT NULL,
  is_active       TINYINT(1) DEFAULT 1,
  is_primary      TINYINT(1) DEFAULT 0,
  created_at      DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  version         INT DEFAULT 0,
  created_by      VARCHAR(50),
  updated_at      DATETIME(6),
  updated_by      VARCHAR(50),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS adm_procedure (
  id                 BIGINT NOT NULL AUTO_INCREMENT,
  ministry_code      VARCHAR(50)   NOT NULL,
  procedure_code     VARCHAR(100)  NOT NULL UNIQUE,
  procedure_name     VARCHAR(1000) NOT NULL,
  procedure_version  VARCHAR(20),
  is_active          TINYINT(1) DEFAULT 1,
  created_at         DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  version            INT DEFAULT 0,
  created_by         VARCHAR(50),
  updated_at         DATETIME(6),
  updated_by         VARCHAR(50),
  PRIMARY KEY (id)
);

-- ── Group 2: Doanh nghiệp ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS enterprise (
  tax_code         VARCHAR(50)  NOT NULL,
  enterprise_name  VARCHAR(255) NOT NULL,
  address          VARCHAR(500) NOT NULL,
  phone            VARCHAR(20)  NOT NULL,
  fax              VARCHAR(20),
  email            VARCHAR(100) NOT NULL,
  is_active        TINYINT(1) DEFAULT 1,
  created_at       DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  created_by       VARCHAR(50),
  updated_at       DATETIME(6),
  updated_by       VARCHAR(50),
  version          INT DEFAULT 0,
  PRIMARY KEY (tax_code)
);

-- ── Group 3: Hồ sơ hành chính ────────────────────────────────

CREATE TABLE IF NOT EXISTS dossiers (
  dossier_id           VARCHAR(50)  NOT NULL,
  dossier_no           VARCHAR(50),
  permit_code          VARCHAR(50),
  tax_code             VARCHAR(50)  NOT NULL,
  procedure_type       VARCHAR(20)  NOT NULL DEFAULT 'NOP_LAN_DAU',
  inspection_location  VARCHAR(500) NOT NULL,
  application_no       VARCHAR(50)  NOT NULL,
  technical_regulation VARCHAR(255) NOT NULL,
  declared_standard    VARCHAR(255) NOT NULL,
  application_date     DATE         NOT NULL DEFAULT (CURDATE()),
  submitted_at         DATETIME(6),
  permit_date          DATE,
  processed_at         DATETIME(6),
  status               VARCHAR(100) NOT NULL DEFAULT 'TAO_MOI',
  is_deleted           TINYINT(1)   NOT NULL DEFAULT 0,
  cancellation_reason  VARCHAR(1000),
  enterprise_name      VARCHAR(255),
  enterprise_phone     VARCHAR(20),
  contract_no          VARCHAR(100),
  invoice_no           VARCHAR(100),
  customs_declaration_no VARCHAR(50),
  created_at           DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  created_by           VARCHAR(50),
  updated_at           DATETIME(6),
  updated_by           VARCHAR(50),
  version              INT DEFAULT 0,
  PRIMARY KEY (dossier_id)
);

CREATE TABLE IF NOT EXISTS dossier_status_historys (
  id               BIGINT       NOT NULL AUTO_INCREMENT,
  dossier_id       VARCHAR(50)  NOT NULL,
  changed_by       VARCHAR(100) NOT NULL,
  changed_at       DATETIME(6)  DEFAULT CURRENT_TIMESTAMP(6),
  previous_status  VARCHAR(100),
  new_status       VARCHAR(100) NOT NULL,
  change_summary   VARCHAR(500) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS goods_declaration (
  id                      BIGINT       NOT NULL AUTO_INCREMENT,
  dossier_id              VARCHAR(50)  NOT NULL,
  goods_name              VARCHAR(500) NOT NULL,
  technical_specification VARCHAR(1000) NOT NULL,
  origin_manufacturer     VARCHAR(255) NOT NULL,
  quantity_weight         VARCHAR(100) NOT NULL,
  import_port             VARCHAR(255) NOT NULL,
  expected_import_date    DATE         NOT NULL,
  created_at              DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS processing_result (
  id                      BIGINT       NOT NULL AUTO_INCREMENT,
  dossier_id              VARCHAR(50)  NOT NULL,
  notice_no               VARCHAR(50)  NOT NULL,
  supervising_agency_name VARCHAR(255) NOT NULL,
  inspection_agency_name  VARCHAR(255) NOT NULL,
  signing_place           VARCHAR(255) NOT NULL,
  signed_date             DATE         NOT NULL,
  result_code             VARCHAR(50)  NOT NULL,
  rejection_reason        VARCHAR(2000),
  supplement_request      VARCHAR(1000),
  created_at              DATETIME(6)  DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

-- ── Group 4: Đăng ký ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registrations (
  id               VARCHAR(255) NOT NULL,
  amend_version    INT          NOT NULL DEFAULT 0,
  created_at       DATETIME(6)  NOT NULL,
  enterprise_id    VARCHAR(20)  NOT NULL,
  procedure_code   VARCHAR(20)  NOT NULL,
  received_at      DATETIME(6)  NOT NULL,
  registration_id  VARCHAR(20)  NOT NULL UNIQUE,
  request_id       VARCHAR(50)  NOT NULL UNIQUE,
  status           VARCHAR(20)  NOT NULL,
  cancel_reason    VARCHAR(500),
  cancelled_at     DATETIME(6),
  created_by       VARCHAR(50),
  updated_at       DATETIME(6),
  updated_by       VARCHAR(50),
  version          INT DEFAULT 0,
  procedure_name   VARCHAR(255),
  PRIMARY KEY (id)
);

-- ── Group 5: Cảnh báo + Log ───────────────────────────────────

CREATE TABLE IF NOT EXISTS alerts (
  alert_id     VARCHAR(20)   NOT NULL,
  alert_type   VARCHAR(255)  NOT NULL,
  created_at   DATETIME(6),
  message      VARCHAR(1000) NOT NULL,
  reference_id VARCHAR(255),
  severity     VARCHAR(50)   NOT NULL,
  source       VARCHAR(255)  NOT NULL,
  status       VARCHAR(50)   NOT NULL,
  updated_at   DATETIME(6),
  PRIMARY KEY (alert_id)
);

CREATE TABLE IF NOT EXISTS alert_audit_logs (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  alert_id   VARCHAR(20) NOT NULL,
  changed_at DATETIME(6),
  changed_by VARCHAR(255) NOT NULL,
  new_status VARCHAR(50)  NOT NULL,
  note       VARCHAR(500),
  old_status VARCHAR(50),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id            VARCHAR(50) NOT NULL,
  action        VARCHAR(50),
  created_at    DATETIME(6) NOT NULL,
  module        VARCHAR(50),
  reference_id  VARCHAR(100),
  error_message VARCHAR(1000),
  ip_address    VARCHAR(50),
  source_system VARCHAR(100),
  status        VARCHAR(20),
  request_time  DATETIME(6),
  PRIMARY KEY (id)
);

-- ── Group 6: Hóa đơn + Đơn hàng ─────────────────────────────

CREATE TABLE IF NOT EXISTS invoices (
  id             VARCHAR(255) NOT NULL,
  created_at     DATETIME(6)  NOT NULL,
  created_by     VARCHAR(50),
  updated_at     DATETIME(6),
  version        INT DEFAULT 0,
  amount         DECIMAL(18,2) NOT NULL,
  customer_name  VARCHAR(255)  NOT NULL,
  customer_phone VARCHAR(50),
  invoice_code   VARCHAR(255)  NOT NULL,
  status         VARCHAR(50)   NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS invoice_items (
  id         VARCHAR(255)  NOT NULL,
  item_name  VARCHAR(255)  NOT NULL,
  price      DECIMAL(18,2) NOT NULL,
  quantity   INT           NOT NULL,
  total      DECIMAL(18,2) NOT NULL,
  invoice_id VARCHAR(255)  NOT NULL,
  created_at DATETIME(6)   NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS orders (
  id           VARCHAR(255)  NOT NULL,
  created_at   DATETIME(6)   NOT NULL,
  created_by   VARCHAR(50),
  customer_id  VARCHAR(50)   NOT NULL,
  order_code   VARCHAR(50)   NOT NULL UNIQUE,
  order_date   DATETIME(6)   NOT NULL,
  status       VARCHAR(20)   NOT NULL,
  total_amount DECIMAL(18,2) NOT NULL,
  updated_at   DATETIME(6),
  note         VARCHAR(1000),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS order_items (
  id         VARCHAR(255)  NOT NULL,
  amount     DECIMAL(18,2) NOT NULL,
  price      DECIMAL(18,2) NOT NULL,
  product_id VARCHAR(50)   NOT NULL,
  quantity   INT           NOT NULL,
  order_id   VARCHAR(255)  NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS sync_sessions (
  sync_id        VARCHAR(36) NOT NULL,
  created_at     DATETIME(6) NOT NULL,
  data_type      VARCHAR(50) NOT NULL,
  end_time       DATETIME(6),
  message        VARCHAR(500),
  source_system  VARCHAR(50) NOT NULL,
  start_time     DATETIME(6) NOT NULL,
  status         VARCHAR(20) NOT NULL,
  sync_mode      VARCHAR(10) NOT NULL,
  failed_count   INT DEFAULT 0,
  max_retry      INT DEFAULT 3,
  retry_count    INT DEFAULT 0,
  success_count  INT DEFAULT 0,
  PRIMARY KEY (sync_id)
);
