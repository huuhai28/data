-- ================================================================
--  admin_remaining_tables.sql — 71 bảng còn lại từ Oracle ADMIN
--  (Convert Oracle → MySQL, bỏ CLOB/BLOB thay bằng LONGTEXT)
-- ================================================================
USE admin_db;

-- ── ADMIN_* group ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS admin_procedures (
  id             BIGINT NOT NULL AUTO_INCREMENT,
  code           VARCHAR(100) NOT NULL UNIQUE,
  created_at     DATETIME(6),
  name           VARCHAR(255) NOT NULL,
  status         VARCHAR(20),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_document_definitions (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  code        VARCHAR(100) NOT NULL UNIQUE,
  created_at  DATETIME(6),
  description VARCHAR(2000),
  name        VARCHAR(255) NOT NULL,
  status      VARCHAR(20)  NOT NULL,
  updated_at  DATETIME(6),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_doc_def_versions (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  created_at               DATETIME(6),
  is_active                TINYINT(1) NOT NULL,
  schema_content           LONGTEXT,
  version                  VARCHAR(50) NOT NULL,
  document_definition_id   BIGINT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_procedure_documents (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  is_required              TINYINT(1) NOT NULL,
  document_definition_id   BIGINT NOT NULL,
  procedure_id             BIGINT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_applications (
  id               BIGINT NOT NULL AUTO_INCREMENT,
  application_code VARCHAR(100) UNIQUE,
  created_at       DATETIME(6),
  status           VARCHAR(50) NOT NULL,
  procedure_id     BIGINT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_app_documents (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  data_content             LONGTEXT NOT NULL,
  document_definition_id   BIGINT NOT NULL,
  version_id               BIGINT,
  application_id           BIGINT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS admin_app_logs (
  id             BIGINT NOT NULL AUTO_INCREMENT,
  created_at     DATETIME(6),
  message        VARCHAR(2000),
  status         VARCHAR(50),
  step           VARCHAR(100),
  application_id BIGINT NOT NULL,
  PRIMARY KEY (id)
);

-- ── ADM_BRANCH ───────────────────────────────────────────────────

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

-- ── APPLICATIONS (legacy) ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS applications (
  id               BIGINT NOT NULL AUTO_INCREMENT,
  application_code VARCHAR(100) UNIQUE,
  created_at       DATETIME(6),
  status           VARCHAR(50) NOT NULL,
  procedure_id     BIGINT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS application_documents (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  data_content             LONGBLOB,
  document_definition_id   BIGINT NOT NULL,
  version_id               BIGINT,
  application_id           BIGINT NOT NULL,
  PRIMARY KEY (id)
);

-- ── APP_USER ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS app_user (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  password            VARCHAR(255) NOT NULL,
  role                VARCHAR(255),
  username            VARCHAR(255) NOT NULL UNIQUE,
  enterprise_tax_code VARCHAR(50),
  PRIMARY KEY (id)
);

-- ── ASSET ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS asset (
  id         VARCHAR(36)  NOT NULL,
  created_at DATETIME(6)  NOT NULL,
  iot        VARCHAR(255),
  name       VARCHAR(255) NOT NULL,
  project_id VARCHAR(36)  NOT NULL,
  status     INT,
  updated_at DATETIME(6),
  uuids      VARCHAR(255),
  PRIMARY KEY (id)
);

-- ── ATTACHMENT / ATTACHMENTS ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS attachment (
  attachment_id VARCHAR(255) NOT NULL,
  checksum      VARCHAR(200),
  document_type VARCHAR(100),
  file_name     VARCHAR(500),
  file_path     VARCHAR(1000),
  file_size     BIGINT,
  file_type     VARCHAR(100),
  uploaded_at   DATETIME(6) NOT NULL,
  version_id    VARCHAR(255) NOT NULL,
  PRIMARY KEY (attachment_id)
);

CREATE TABLE IF NOT EXISTS attachments (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  dossier_id      VARCHAR(50) NOT NULL,
  attachment_type VARCHAR(50) NOT NULL,
  file_name       VARCHAR(255) NOT NULL,
  file_path       VARCHAR(500) NOT NULL,
  file_format     VARCHAR(100),
  file_size_kb    DECIMAL(10,2),
  is_required     TINYINT(1) DEFAULT 0,
  uploaded_at     DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  label           VARCHAR(255),
  PRIMARY KEY (id)
);

-- ── AUTH_CONFIG ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS auth_config (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  auth_type   VARCHAR(255) NOT NULL,
  config_json LONGTEXT,
  is_active   TINYINT(1) NOT NULL,
  PRIMARY KEY (id)
);

-- ── DN_* group (Kiểm định) ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS dn_enterprise (
  id         BIGINT NOT NULL AUTO_INCREMENT,
  tax_code   VARCHAR(20)  NOT NULL,
  name       VARCHAR(255) NOT NULL,
  address    VARCHAR(500) NOT NULL,
  phone      VARCHAR(20)  NOT NULL,
  fax        VARCHAR(20),
  created_at DATETIME(6)  NOT NULL,
  created_by VARCHAR(50),
  updated_at DATETIME(6),
  updated_by VARCHAR(50),
  version    INT,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_inspection_dossier (
  id                            BIGINT NOT NULL AUTO_INCREMENT,
  enterprise_id                 BIGINT NOT NULL,
  dossier_id                    VARCHAR(50) NOT NULL,
  produce_type                  VARCHAR(50) NOT NULL,
  submission_date               DATE NOT NULL,
  application_number            VARCHAR(50),
  collection_point              VARCHAR(255) NOT NULL,
  contract_number               VARCHAR(100) NOT NULL,
  goods_description             VARCHAR(1000) NOT NULL,
  invoice_number                VARCHAR(100) NOT NULL,
  tracking_number               VARCHAR(100) NOT NULL,
  import_declaration_number     VARCHAR(100) NOT NULL,
  co_number                     VARCHAR(100),
  cfs_number                    VARCHAR(100),
  qms_certificate_number        VARCHAR(100),
  conformity_certificate_number VARCHAR(100),
  created_at                    DATETIME(6) NOT NULL,
  created_by                    VARCHAR(50),
  updated_at                    DATETIME(6),
  updated_by                    VARCHAR(50),
  version                       INT,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_documents (
  id                    BIGINT NOT NULL AUTO_INCREMENT,
  inspection_dossier_id BIGINT NOT NULL,
  document_name         VARCHAR(255) NOT NULL,
  document_type         VARCHAR(50),
  document_path         VARCHAR(500) NOT NULL,
  file_size             BIGINT,
  mime_type             VARCHAR(100),
  uploaded_time         DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_dossier_history (
  id                    BIGINT NOT NULL AUTO_INCREMENT,
  inspection_dossier_id BIGINT NOT NULL,
  sequence_no           INT NOT NULL,
  change_time           DATETIME(6) NOT NULL,
  change_content        VARCHAR(500) NOT NULL,
  dossier_status        VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_inspection_result (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  inspection_dossier_id   BIGINT NOT NULL,
  parent_agency_name      VARCHAR(255) NOT NULL,
  inspection_agency_name  VARCHAR(255) NOT NULL,
  notification_no         VARCHAR(50)  NOT NULL,
  signing_place           VARCHAR(255) NOT NULL,
  signing_date            DATE NOT NULL,
  result_content          VARCHAR(50)  NOT NULL,
  result_description      VARCHAR(2000),
  received_time           DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_inspection_result_document (
  id                   BIGINT NOT NULL AUTO_INCREMENT,
  inspection_result_id BIGINT NOT NULL,
  document_name        VARCHAR(255) NOT NULL,
  document_type        VARCHAR(50),
  document_path        VARCHAR(500) NOT NULL,
  file_size            BIGINT,
  mime_type            VARCHAR(100),
  uploaded_time        DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_products (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  inspection_dossier_id   BIGINT NOT NULL,
  product_name            VARCHAR(255) NOT NULL,
  technical_specifications VARCHAR(1000) NOT NULL,
  origin_manufacturer     VARCHAR(255) NOT NULL,
  weight_or_quantity      VARCHAR(100) NOT NULL,
  entry_port              VARCHAR(100) NOT NULL,
  expected_entry_date     DATE NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dn_signatures (
  id                    BIGINT NOT NULL AUTO_INCREMENT,
  inspection_dossier_id BIGINT NOT NULL,
  signed_by             VARCHAR(255) NOT NULL,
  signer_position       VARCHAR(100) NOT NULL,
  signing_location      VARCHAR(100) NOT NULL,
  signing_date          DATE DEFAULT (CURDATE()) NOT NULL,
  agreement_checked     TINYINT(1) DEFAULT 0 NOT NULL,
  PRIMARY KEY (id)
);

-- ── DOCUMENT_DEFINITION_VERSIONS ─────────────────────────────────

CREATE TABLE IF NOT EXISTS document_definition_versions (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  created_at               DATETIME(6),
  is_active                TINYINT(1) NOT NULL,
  schema_content           LONGBLOB,
  version                  VARCHAR(50) NOT NULL,
  document_definition_id   BIGINT NOT NULL,
  PRIMARY KEY (id)
);

-- ── DOSSIER (legacy) ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS dossier_legacy (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  business_code       VARCHAR(50)  NOT NULL,
  business_name       VARCHAR(255) NOT NULL,
  certificate_serial  VARCHAR(100) NOT NULL,
  channel             VARCHAR(20)  NOT NULL,
  contact_email       VARCHAR(255) NOT NULL,
  created_at          DATETIME(6)  NOT NULL,
  service_code        VARCHAR(50)  NOT NULL,
  service_version     VARCHAR(20)  NOT NULL,
  signature_method    VARCHAR(50)  NOT NULL,
  status              VARCHAR(30)  NOT NULL,
  submitted_at        DATETIME(6)  NOT NULL,
  transaction_code    VARCHAR(50)  NOT NULL UNIQUE,
  updated_at          DATETIME(6)  NOT NULL,
  dossier_id          VARCHAR(50)  NOT NULL UNIQUE,
  PRIMARY KEY (id)
);

-- ── DOSSIER_STATUS_HISTORY (legacy) ───────────────────────────────

CREATE TABLE IF NOT EXISTS dossier_status_history (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  dossier_id  VARCHAR(50) NOT NULL,
  new_status  VARCHAR(30) NOT NULL,
  old_status  VARCHAR(30) NOT NULL,
  updated_at  DATETIME(6) NOT NULL,
  updated_by  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

-- ── ENTERPRISES ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS enterprises (
  id         VARCHAR(20) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  name       VARCHAR(255) NOT NULL,
  status     VARCHAR(20)  NOT NULL,
  tax_code   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (id)
);

-- ── ENTERPRISE_RESPONSE ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS enterprise_response (
  id               BIGINT NOT NULL AUTO_INCREMENT,
  created_at       DATETIME(6),
  enterprise_id    VARCHAR(64) NOT NULL,
  registration_id  VARCHAR(64) NOT NULL,
  response_code    VARCHAR(32) NOT NULL,
  response_message VARCHAR(500),
  status           VARCHAR(32) NOT NULL,
  updated_at       DATETIME(6),
  PRIMARY KEY (id)
);

-- ── FILES + FILE_LINKS ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS files (
  id            VARCHAR(255) NOT NULL,
  created_at    DATETIME(6)  NOT NULL,
  file_name     VARCHAR(255) NOT NULL,
  file_path     VARCHAR(255) NOT NULL,
  file_size     BIGINT,
  mime_type     VARCHAR(255),
  original_name VARCHAR(255) NOT NULL,
  status        VARCHAR(255),
  created_by    VARCHAR(255),
  file_type     VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS file_links (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  entity_id   VARCHAR(255) NOT NULL,
  entity_type VARCHAR(255) NOT NULL,
  file_id     VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
);

-- ── GOODS_CERTIFICATE + GOODS_DECLARATION ────────────────────────

CREATE TABLE IF NOT EXISTS goods_certificate (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  dossier_id              VARCHAR(50)  NOT NULL,
  co_no                   VARCHAR(50),
  cfs_no                  VARCHAR(50),
  qms_certificate_no      VARCHAR(50),
  qms_issuer              VARCHAR(255),
  qms_issued_date         DATE,
  conformity_cert_no      VARCHAR(50),
  conformity_issuer       VARCHAR(255),
  conformity_issued_date  DATE,
  created_at              DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS goods_declaration (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  dossier_id              VARCHAR(50) NOT NULL,
  goods_name              VARCHAR(500) NOT NULL,
  technical_specification VARCHAR(1000) NOT NULL,
  origin_manufacturer     VARCHAR(255) NOT NULL,
  quantity_weight         VARCHAR(100) NOT NULL,
  import_port             VARCHAR(255) NOT NULL,
  expected_import_date    DATE NOT NULL,
  created_at              DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);

-- ── MESSAGES + MESSAGE_STORE ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS messages (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  created_at      DATETIME(6),
  message_id      VARCHAR(64) NOT NULL UNIQUE,
  parsed          TINYINT(1)  NOT NULL,
  parsed_content  LONGTEXT,
  raw_message     LONGTEXT    NOT NULL,
  status          VARCHAR(32),
  tenant_id       VARCHAR(64),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS message_store (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  created_at      DATETIME(6) NOT NULL,
  message_id      VARCHAR(50) NOT NULL UNIQUE,
  parsed_content  LONGTEXT,
  registration_id VARCHAR(50),
  request_id      VARCHAR(50),
  PRIMARY KEY (id)
);

-- ── PLANNING ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS planning (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  created_at      DATETIME(6),
  description     VARCHAR(2000),
  dossier_code    VARCHAR(64) NOT NULL UNIQUE,
  name            VARCHAR(255) NOT NULL,
  request_id      VARCHAR(64) NOT NULL UNIQUE,
  status          VARCHAR(32) NOT NULL,
  status_message  VARCHAR(500),
  updated_at      DATETIME(6),
  PRIMARY KEY (id)
);

-- ── PROCEDURES + PROCEDURE_DOCUMENTS ─────────────────────────────

CREATE TABLE IF NOT EXISTS procedures (
  code       VARCHAR(20)  NOT NULL,
  created_at DATETIME(6)  NOT NULL,
  name       VARCHAR(255) NOT NULL,
  status     VARCHAR(20)  NOT NULL,
  version    VARCHAR(10)  NOT NULL,
  id         BIGINT NOT NULL AUTO_INCREMENT UNIQUE,
  PRIMARY KEY (code)
);

CREATE TABLE IF NOT EXISTS procedure_documents (
  id                       BIGINT NOT NULL AUTO_INCREMENT,
  is_required              TINYINT(1) NOT NULL,
  document_definition_id   BIGINT NOT NULL,
  procedure_id             BIGINT NOT NULL,
  PRIMARY KEY (id)
);

-- ── PRODUCTS + PRODUCT_CATEGORIES ────────────────────────────────

CREATE TABLE IF NOT EXISTS product_categories (
  id          VARCHAR(255) NOT NULL,
  code        VARCHAR(50)  NOT NULL UNIQUE,
  created_at  DATETIME(6),
  created_by  VARCHAR(50),
  description LONGTEXT,
  is_active   TINYINT(1)   NOT NULL,
  name        VARCHAR(100) NOT NULL,
  updated_at  DATETIME(6),
  updated_by  VARCHAR(50),
  version     INT,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS products (
  id          VARCHAR(50)   NOT NULL,
  created_at  DATETIME(6),
  created_by  VARCHAR(50),
  description LONGTEXT,
  name        VARCHAR(200)  NOT NULL,
  price       DECIMAL(18,2) NOT NULL,
  status      VARCHAR(20)   NOT NULL,
  stock_qty   INT           NOT NULL,
  unit        VARCHAR(30)   NOT NULL,
  updated_at  DATETIME(6),
  updated_by  VARCHAR(50),
  version     INT,
  category_id VARCHAR(255)  NOT NULL,
  PRIMARY KEY (id)
);

-- ── QC_* group ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS qc_enterprise (
  id                   BIGINT NOT NULL AUTO_INCREMENT,
  address              VARCHAR(255),
  email                VARCHAR(255),
  fax                  VARCHAR(255),
  name                 VARCHAR(255),
  phone                VARCHAR(255),
  tax_code             VARCHAR(255),
  representative_name  VARCHAR(255),
  business_license_no  VARCHAR(255),
  license_issue_date   DATE,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application_status (
  id   BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(255),
  name VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application (
  id                    BIGINT NOT NULL AUTO_INCREMENT,
  application_code      VARCHAR(255),
  applied_standard      VARCHAR(255),
  commitment_checked    INT,
  enterprise_id         BIGINT,
  gathering_place       VARCHAR(255),
  is_deleted            INT,
  permit_code           VARCHAR(255),
  permit_date           DATE,
  procedure_type        VARCHAR(255),
  signer_date           DATE,
  signer_name           VARCHAR(255),
  signer_place          VARCHAR(255),
  signer_position       VARCHAR(255),
  status_id             BIGINT,
  submit_date           DATE,
  technical_regulation  VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application_attachments (
  id             BIGINT NOT NULL AUTO_INCREMENT,
  application_id BIGINT,
  file_path      VARCHAR(255),
  file_type      VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application_goods (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  application_id          BIGINT,
  import_date             DATE,
  import_port             VARCHAR(255),
  origin_manufacturer     VARCHAR(255),
  product_name            VARCHAR(255),
  quantity_or_weight      VARCHAR(255),
  technical_specification VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application_import_docs (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  application_id          BIGINT,
  bill_of_lading          VARCHAR(255),
  cfs_number              VARCHAR(255),
  co_number               VARCHAR(255),
  conformity_cert_date    DATE,
  conformity_cert_number  VARCHAR(255),
  conformity_cert_org     VARCHAR(255),
  contract_number         VARCHAR(255),
  customs_declaration_no  VARCHAR(255),
  invoice_number          VARCHAR(255),
  packing_list            VARCHAR(255),
  quality_cert_number     VARCHAR(255),
  quality_cert_org        VARCHAR(255),
  import_date             DATE,
  invoice_date            DATE,
  port_of_arrival         VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_application_status_history (
  id             BIGINT NOT NULL AUTO_INCREMENT,
  action_by      VARCHAR(255),
  action_time    DATETIME(6),
  application_id BIGINT,
  note           VARCHAR(255),
  status_id      BIGINT,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_audit_log (
  id            BIGINT NOT NULL AUTO_INCREMENT,
  action_name   VARCHAR(255),
  action_time   DATETIME(6),
  module_name   VARCHAR(255),
  payload       LONGTEXT,
  reference_id  VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_ministry (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  code        VARCHAR(50) NOT NULL UNIQUE,
  name        VARCHAR(500) NOT NULL,
  description VARCHAR(1000),
  is_deleted  TINYINT(1) DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS qc_procedure (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  code        VARCHAR(50) NOT NULL UNIQUE,
  name        VARCHAR(500) NOT NULL,
  description VARCHAR(1000),
  is_deleted  TINYINT(1) DEFAULT 0,
  PRIMARY KEY (id)
);

-- ── RECEIVED_RESPONSES ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS received_responses (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  payload         LONGTEXT,
  received_at     DATETIME(6),
  registration_id VARCHAR(50),
  response_id     VARCHAR(50),
  status          VARCHAR(50),
  PRIMARY KEY (id)
);

-- ── REGISTRATION_* group ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registration_statuses (
  code           VARCHAR(50)  NOT NULL,
  business_name  VARCHAR(255) NOT NULL,
  created_at     DATETIME(6),
  description    VARCHAR(1000),
  technical_name VARCHAR(255),
  PRIMARY KEY (code)
);

CREATE TABLE IF NOT EXISTS registration_audit_log (
  id              VARCHAR(255) NOT NULL,
  action          VARCHAR(255),
  created_at      DATETIME(6),
  enterprise_id   VARCHAR(255),
  request_id      VARCHAR(255),
  status          VARCHAR(255),
  performed_by    VARCHAR(50),
  ip_address      VARCHAR(50),
  user_agent      VARCHAR(255),
  account         VARCHAR(50),
  full_name       VARCHAR(255),
  unit            VARCHAR(255),
  procedure_code  VARCHAR(50),
  reason          VARCHAR(500),
  procedure_name  VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS registration_data (
  data_id    VARCHAR(255) NOT NULL,
  created_at DATETIME(6)  NOT NULL,
  data_json  LONGTEXT,
  version_id VARCHAR(255) NOT NULL UNIQUE,
  PRIMARY KEY (data_id)
);

CREATE TABLE IF NOT EXISTS registration_documents (
  id               VARCHAR(255) NOT NULL,
  content          LONGTEXT,
  created_at       DATETIME(6)  NOT NULL,
  document_type    VARCHAR(20)  NOT NULL,
  registration_id  VARCHAR(255) NOT NULL,
  amend_version    INT          NOT NULL,
  status           VARCHAR(20)  NOT NULL,
  file_id          VARCHAR(100),
  file_name        VARCHAR(255),
  created_by       VARCHAR(50),
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS registration_history (
  id              VARCHAR(255) NOT NULL,
  created_at      DATETIME(6)  NOT NULL,
  created_by      VARCHAR(50),
  payload         LONGTEXT,
  registration_id VARCHAR(20)  NOT NULL,
  status          VARCHAR(20),
  version         INT          NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS registration_versions (
  id              VARCHAR(255) NOT NULL,
  amend_version   INT          NOT NULL,
  payload_xml     LONGTEXT,
  received_at     DATETIME(6)  NOT NULL,
  request_id      VARCHAR(50)  NOT NULL,
  registration_id VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
);

-- ── RESPONSE_PACKAGES ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS response_packages (
  id                 BIGINT NOT NULL AUTO_INCREMENT,
  created_at         DATETIME(6)  NOT NULL,
  processing_result  LONGTEXT,
  registration_id    VARCHAR(50)  NOT NULL UNIQUE,
  response_code      VARCHAR(50),
  response_id        VARCHAR(50)  NOT NULL UNIQUE,
  response_message   VARCHAR(500),
  status             VARCHAR(50),
  enterprise_id      VARCHAR(50),
  PRIMARY KEY (id)
);

-- ── RESULT_GOODS ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS result_goods (
  id                   BIGINT NOT NULL AUTO_INCREMENT,
  processing_result_id BIGINT NOT NULL,
  goods_name           VARCHAR(255) NOT NULL,
  origin_manufacturer  VARCHAR(255) NOT NULL,
  quantity_weight      VARCHAR(100) NOT NULL,
  unit                 VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id)
);

-- ── ROUTING_MESSAGES ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS routing_messages (
  id             BIGINT NOT NULL AUTO_INCREMENT,
  created_at     DATETIME(6),
  message_id     VARCHAR(50) NOT NULL UNIQUE,
  payload        LONGTEXT,
  procedure_code VARCHAR(50),
  status         VARCHAR(20) NOT NULL,
  updated_at     DATETIME(6),
  PRIMARY KEY (id)
);

-- ── SIGNATURES + SIGNATURE_INFO + SIGNATURE_VERIFICATION_LOG ─────

CREATE TABLE IF NOT EXISTS signatures (
  signature_id      VARCHAR(255) NOT NULL,
  cert_serial_number VARCHAR(255),
  cert_subject       VARCHAR(255),
  created_at         DATETIME(6),
  request_id         VARCHAR(255) NOT NULL,
  sign_time          DATETIME(6),
  signature_data     LONGTEXT,
  signed_data        LONGTEXT,
  verified           TINYINT(1),
  verified_at        DATETIME(6),
  PRIMARY KEY (signature_id)
);

CREATE TABLE IF NOT EXISTS signature_info (
  id                           BIGINT NOT NULL AUTO_INCREMENT,
  dossier_id                   VARCHAR(50)  NOT NULL,
  signer_name                  VARCHAR(100) NOT NULL,
  signer_title                 VARCHAR(100) NOT NULL,
  signing_place                VARCHAR(100) NOT NULL,
  signed_date                  DATE         NOT NULL DEFAULT (CURDATE()),
  legal_commitment_confirmed   TINYINT(1) DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS signature_verification_log (
  id         BIGINT NOT NULL AUTO_INCREMENT,
  created_at DATETIME(6),
  message    VARCHAR(255),
  request_id VARCHAR(255) NOT NULL UNIQUE,
  valid       TINYINT(1)  NOT NULL,
  PRIMARY KEY (id)
);

-- ── STATUS + STORAGE_CONFIG + SYNC_SESSIONS ───────────────────────

CREATE TABLE IF NOT EXISTS status_codes (
  code           VARCHAR(50)  NOT NULL,
  name           VARCHAR(255) NOT NULL,
  created_at     DATETIME(6),
  description    VARCHAR(1000),
  technical_name VARCHAR(255),
  PRIMARY KEY (code)
);

CREATE TABLE IF NOT EXISTS storage_config (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  config_json LONGTEXT NOT NULL,
  created_at  DATETIME(6)  NOT NULL,
  secret_enc  LONGTEXT,
  updated_at  DATETIME(6)  NOT NULL,
  user_id     VARCHAR(100),
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

-- ── SYSTEM_LIMITS + SYSTEM_LIMIT_AUDITS ──────────────────────────

CREATE TABLE IF NOT EXISTS system_limits (
  limit_id        VARCHAR(36)  NOT NULL,
  action_on_exceed VARCHAR(20) NOT NULL,
  created_at      DATETIME(6),
  limit_type      VARCHAR(50)  NOT NULL,
  max_value       DOUBLE       NOT NULL,
  status          VARCHAR(10)  NOT NULL,
  target          VARCHAR(50)  NOT NULL,
  time_window     VARCHAR(20)  NOT NULL,
  updated_at      DATETIME(6),
  PRIMARY KEY (limit_id),
  UNIQUE KEY uk_limit_target (limit_type, target)
);

CREATE TABLE IF NOT EXISTS system_limit_audits (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  action_by   VARCHAR(50)  NOT NULL,
  action_time DATETIME(6),
  limit_id    VARCHAR(36)  NOT NULL,
  new_value   VARCHAR(255) NOT NULL,
  note        VARCHAR(500),
  old_value   VARCHAR(255),
  PRIMARY KEY (id)
);

-- ── TEST + THEME_CONFIG ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS test_table (
  column1 VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS theme_config (
  id          BIGINT NOT NULL AUTO_INCREMENT,
  config_json LONGTEXT,
  created_at  DATETIME(6),
  status      VARCHAR(255),
  updated_at  DATETIME(6),
  PRIMARY KEY (id)
);

-- ── FLYWAY_SCHEMA_HISTORY ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS flyway_schema_history (
  installed_rank INT          NOT NULL,
  version        VARCHAR(50),
  description    VARCHAR(200) NOT NULL,
  type           VARCHAR(20)  NOT NULL,
  script         VARCHAR(1000) NOT NULL,
  checksum       INT,
  installed_by   VARCHAR(100) NOT NULL,
  installed_on   DATETIME(6)  DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  execution_time INT          NOT NULL,
  success        TINYINT(1)   NOT NULL,
  PRIMARY KEY (installed_rank)
);

-- ── PROCESSING_RESULT (if missing) ───────────────────────────────

CREATE TABLE IF NOT EXISTS processing_result_docs (
  id                   BIGINT NOT NULL AUTO_INCREMENT,
  processing_result_id BIGINT NOT NULL,
  dossier_id           VARCHAR(50) NOT NULL,
  notice_no            VARCHAR(50) NOT NULL,
  supervising_agency   VARCHAR(255) NOT NULL,
  inspection_agency    VARCHAR(255) NOT NULL,
  signing_place        VARCHAR(255) NOT NULL,
  signed_date          DATE NOT NULL,
  result_code          VARCHAR(50) NOT NULL,
  created_at           DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
);
