#!/bin/bash
# conf/admin_tables.sh — Config 85 bảng ADMIN
# Format: "mysql_table|iceberg_table|pk_col|kafka_group|transform"

TABLES_REGISTRY=(
  # Tổ chức hành chính
  "adm_ministry|adm_ministry|id|flink-adm-ministry|passthrough"
  "adm_department|adm_department|id|flink-adm-dept|passthrough"
  "adm_branch|adm_branch|id|flink-adm-branch|passthrough"
  "adm_procedure|adm_procedure|id|flink-adm-proc|passthrough"

  # Admin thủ tục
  "admin_procedures|admin_procedures|id|flink-adm-aproc|passthrough"
  "admin_document_definitions|admin_document_definitions|id|flink-adm-docdef|passthrough"
  "admin_doc_def_versions|admin_doc_def_versions|id|flink-adm-docver|passthrough"
  "admin_procedure_documents|admin_procedure_documents|id|flink-adm-procdoc|passthrough"
  "admin_applications|admin_applications|id|flink-adm-aapp|passthrough"
  "admin_app_documents|admin_app_documents|id|flink-adm-appdoc|passthrough"
  "admin_app_logs|admin_app_logs|id|flink-adm-applog|passthrough"

  # Doanh nghiệp
  "enterprise|enterprise|tax_code|flink-adm-ent|passthrough"
  "enterprises|enterprises|id|flink-adm-ents|passthrough"
  "enterprise_response|enterprise_response|id|flink-adm-entres|passthrough"

  # Hồ sơ
  "dossiers|dossiers|dossier_id|flink-adm-dos|passthrough"
  "dossier_legacy|dossier_legacy|id|flink-adm-dosl|passthrough"
  "dossier_status_historys|dossier_status_historys|id|flink-adm-dsh|passthrough"
  "dossier_status_history|dossier_status_history|id|flink-adm-dshv|passthrough"
  "processing_result|processing_result|id|flink-adm-pres|passthrough"
  "result_goods|result_goods|id|flink-adm-rg|passthrough"

  # Hàng hóa
  "goods_declaration|goods_declaration|id|flink-adm-gd|passthrough"
  "goods_certificate|goods_certificate|id|flink-adm-gc|passthrough"

  # Kiểm định DN (dn_*)
  "dn_enterprise|dn_enterprise|id|flink-adm-dnent|passthrough"
  "dn_inspection_dossier|dn_inspection_dossier|id|flink-adm-dnid|passthrough"
  "dn_documents|dn_documents|id|flink-adm-dndoc|passthrough"
  "dn_dossier_history|dn_dossier_history|id|flink-adm-dndh|passthrough"
  "dn_inspection_result|dn_inspection_result|id|flink-adm-dnir|passthrough"
  "dn_inspection_result_document|dn_inspection_result_document|id|flink-adm-dnird|passthrough"
  "dn_products|dn_products|id|flink-adm-dnprod|passthrough"
  "dn_signatures|dn_signatures|id|flink-adm-dnsig|passthrough"

  # Đăng ký
  "registrations|registrations|id|flink-adm-reg|passthrough"
  "registration_statuses|registration_statuses|code|flink-adm-regst|passthrough"
  "registration_audit_log|registration_audit_log|id|flink-adm-regal|passthrough"
  "registration_data|registration_data|data_id|flink-adm-regdt|passthrough"
  "registration_documents|registration_documents|id|flink-adm-regdoc|passthrough"
  "registration_history|registration_history|id|flink-adm-regh|passthrough"
  "registration_versions|registration_versions|id|flink-adm-regv|passthrough"

  # Cảnh báo + Log
  "alerts|alerts|alert_id|flink-adm-alt|passthrough"
  "alert_audit_logs|alert_audit_logs|id|flink-adm-altlog|passthrough"
  "audit_logs|audit_logs|id|flink-adm-aulog|passthrough"

  # Hóa đơn + Đơn hàng
  "invoices|invoices|id|flink-adm-inv|passthrough"
  "invoice_items|invoice_items|id|flink-adm-invit|passthrough"
  "orders|orders|id|flink-adm-ord|passthrough"
  "order_items|order_items|id|flink-adm-ordit|passthrough"

  # Sản phẩm
  "products|products|id|flink-adm-prod|passthrough"
  "product_categories|product_categories|id|flink-adm-pcat|passthrough"

  # QC (Kiểm soát chất lượng)
  "qc_enterprise|qc_enterprise|id|flink-adm-qcent|passthrough"
  "qc_application|qc_application|id|flink-adm-qcapp|passthrough"
  "qc_application_status|qc_application_status|id|flink-adm-qcast|passthrough"
  "qc_application_status_history|qc_application_status_history|id|flink-adm-qcash|passthrough"
  "qc_application_goods|qc_application_goods|id|flink-adm-qcag|passthrough"
  "qc_application_attachments|qc_application_attachments|id|flink-adm-qcaa|passthrough"
  "qc_application_import_docs|qc_application_import_docs|id|flink-adm-qcaid|passthrough"
  "qc_audit_log|qc_audit_log|id|flink-adm-qcal|passthrough"
  "qc_ministry|qc_ministry|id|flink-adm-qcmin|passthrough"
  "qc_procedure|qc_procedure|id|flink-adm-qcpro|passthrough"

  # Tài liệu + File
  "applications|applications|id|flink-adm-apps|passthrough"
  "application_documents|application_documents|id|flink-adm-appdoc2|passthrough"
  "document_definition_versions|document_definition_versions|id|flink-adm-ddv|passthrough"
  "files|sys_files|id|flink-adm-files|passthrough"
  "file_links|file_links|id|flink-adm-flink|passthrough"
  "attachment|attachment|attachment_id|flink-adm-att|passthrough"
  "attachments|attachments|id|flink-adm-atts|passthrough"

  # Người dùng + Xác thực
  "app_user|app_user|id|flink-adm-usr|passthrough"
  "auth_config|auth_config|id|flink-adm-auth|passthrough"

  # Message + Routing
  "messages|messages|id|flink-adm-msg|passthrough"
  "message_store|message_store|id|flink-adm-msgst|passthrough"
  "routing_messages|routing_messages|id|flink-adm-rmsg|passthrough"
  "received_responses|received_responses|id|flink-adm-rres|passthrough"
  "response_packages|response_packages|id|flink-adm-rpkg|passthrough"

  # Chữ ký
  "signatures|signatures|signature_id|flink-adm-sig|passthrough"
  "signature_info|signature_info|id|flink-adm-siginfo|passthrough"
  "signature_verification_log|signature_verification_log|id|flink-adm-sigvl|passthrough"

  # Hệ thống
  "planning|planning|id|flink-adm-plan|passthrough"
  "procedures|procedures|code|flink-adm-procs|passthrough"
  "procedure_documents|procedure_documents|id|flink-adm-procd|passthrough"
  "sync_sessions|sync_sessions|sync_id|flink-adm-sync|passthrough"
  "system_limits|system_limits|limit_id|flink-adm-syslim|passthrough"
  "system_limit_audits|system_limit_audits|id|flink-adm-sysla|passthrough"
  "storage_config|storage_config|id|flink-adm-stcfg|passthrough"
  "theme_config|theme_config|id|flink-adm-thcfg|passthrough"
  "status_codes|status_codes|code|flink-adm-stcd|passthrough"
  "asset|asset|id|flink-adm-asset|passthrough"
  "flyway_schema_history|flyway_schema_history|installed_rank|flink-adm-fly|passthrough"
  "test_table|test_table|column1|flink-adm-test|passthrough"
)

# ── KAFKA_COLS_<mysql_table> (Flink types) ─────────────────────
# Bỏ CLOB/BLOB — dùng STRING thay thế
KAFKA_COLS_adm_ministry="id INT, order_no INT, ministry_code STRING, ministry_name STRING, description STRING, is_active INT, created_at BIGINT, version INT, created_by STRING, updated_at BIGINT, updated_by STRING"
KAFKA_COLS_adm_department="id INT, ministry_code STRING, department_code STRING, department_name STRING, is_active INT, is_primary INT, created_at BIGINT, version INT, created_by STRING, updated_at BIGINT, updated_by STRING"
KAFKA_COLS_adm_branch="id INT, department_code STRING, unit_code STRING, unit_name STRING, is_active INT, is_primary INT, created_at BIGINT, version INT, created_by STRING, updated_at BIGINT, updated_by STRING"
KAFKA_COLS_adm_procedure="id INT, ministry_code STRING, procedure_code STRING, procedure_name STRING, procedure_version STRING, is_active INT, created_at BIGINT, version INT, created_by STRING, updated_at BIGINT, updated_by STRING"

KAFKA_COLS_admin_procedures="id INT, code STRING, created_at BIGINT, name STRING, status STRING"
KAFKA_COLS_admin_document_definitions="id INT, code STRING, created_at BIGINT, description STRING, name STRING, status STRING, updated_at BIGINT"
KAFKA_COLS_admin_doc_def_versions="id INT, created_at BIGINT, is_active INT, schema_content STRING, version STRING, document_definition_id INT"
KAFKA_COLS_admin_procedure_documents="id INT, is_required INT, document_definition_id INT, procedure_id INT"
KAFKA_COLS_admin_applications="id INT, application_code STRING, created_at BIGINT, status STRING, procedure_id INT"
KAFKA_COLS_admin_app_documents="id INT, data_content STRING, document_definition_id INT, version_id INT, application_id INT"
KAFKA_COLS_admin_app_logs="id INT, created_at BIGINT, message STRING, status STRING, step STRING, application_id INT"

KAFKA_COLS_enterprise="tax_code STRING, enterprise_name STRING, address STRING, phone STRING, email STRING, is_active INT, created_at BIGINT, created_by STRING, updated_at BIGINT, updated_by STRING, version INT"
KAFKA_COLS_enterprises="id STRING, created_at BIGINT, name STRING, status STRING, tax_code STRING"
KAFKA_COLS_enterprise_response="id INT, created_at BIGINT, enterprise_id STRING, registration_id STRING, response_code STRING, response_message STRING, status STRING, updated_at BIGINT"

KAFKA_COLS_dossiers="dossier_id STRING, dossier_no STRING, tax_code STRING, procedure_type STRING, inspection_location STRING, application_no STRING, technical_regulation STRING, declared_standard STRING, application_date INT, submitted_at BIGINT, permit_date INT, processed_at BIGINT, status STRING, is_deleted INT, enterprise_name STRING, created_at BIGINT, created_by STRING, updated_at BIGINT, version INT"
KAFKA_COLS_dossier_legacy="id INT, business_code STRING, business_name STRING, certificate_serial STRING, channel STRING, contact_email STRING, created_at BIGINT, service_code STRING, service_version STRING, signature_method STRING, status STRING, submitted_at BIGINT, transaction_code STRING, updated_at BIGINT, dossier_id STRING"
KAFKA_COLS_dossier_status_historys="id INT, dossier_id STRING, changed_by STRING, changed_at BIGINT, previous_status STRING, new_status STRING, change_summary STRING"
KAFKA_COLS_dossier_status_history="id INT, dossier_id STRING, new_status STRING, old_status STRING, updated_at BIGINT, updated_by STRING"
KAFKA_COLS_processing_result="id INT, dossier_id STRING, notice_no STRING, inspection_agency_name STRING, signing_place STRING, signed_date INT, result_code STRING, rejection_reason STRING, created_at BIGINT"
KAFKA_COLS_result_goods="id INT, processing_result_id INT, goods_name STRING, origin_manufacturer STRING, quantity_weight STRING, unit STRING"

KAFKA_COLS_goods_declaration="id INT, dossier_id STRING, goods_name STRING, technical_specification STRING, origin_manufacturer STRING, quantity_weight STRING, import_port STRING, expected_import_date INT, created_at BIGINT"
KAFKA_COLS_goods_certificate="id INT, dossier_id STRING, co_no STRING, cfs_no STRING, qms_certificate_no STRING, qms_issuer STRING, qms_issued_date INT, conformity_cert_no STRING, conformity_issuer STRING, conformity_issued_date INT, created_at BIGINT"

KAFKA_COLS_dn_enterprise="id INT, tax_code STRING, name STRING, address STRING, phone STRING, fax STRING, created_at BIGINT, created_by STRING, updated_at BIGINT, updated_by STRING, version INT"
KAFKA_COLS_dn_inspection_dossier="id INT, enterprise_id INT, dossier_id STRING, produce_type STRING, submission_date INT, application_number STRING, collection_point STRING, contract_number STRING, goods_description STRING, invoice_number STRING, tracking_number STRING, import_declaration_number STRING, co_number STRING, cfs_number STRING, qms_certificate_number STRING, conformity_certificate_number STRING, created_at BIGINT, created_by STRING, updated_at BIGINT, updated_by STRING, version INT"
KAFKA_COLS_dn_documents="id INT, inspection_dossier_id INT, document_name STRING, document_type STRING, document_path STRING, file_size BIGINT, mime_type STRING, uploaded_time BIGINT"
KAFKA_COLS_dn_dossier_history="id INT, inspection_dossier_id INT, sequence_no INT, change_time BIGINT, change_content STRING, dossier_status STRING"
KAFKA_COLS_dn_inspection_result="id INT, inspection_dossier_id INT, parent_agency_name STRING, inspection_agency_name STRING, notification_no STRING, signing_place STRING, signing_date INT, result_content STRING, result_description STRING, received_time BIGINT"
KAFKA_COLS_dn_inspection_result_document="id INT, inspection_result_id INT, document_name STRING, document_type STRING, document_path STRING, file_size BIGINT, mime_type STRING, uploaded_time BIGINT"
KAFKA_COLS_dn_products="id INT, inspection_dossier_id INT, product_name STRING, technical_specifications STRING, origin_manufacturer STRING, weight_or_quantity STRING, entry_port STRING, expected_entry_date INT"
KAFKA_COLS_dn_signatures="id INT, inspection_dossier_id INT, signed_by STRING, signer_position STRING, signing_location STRING, signing_date INT, agreement_checked INT"

KAFKA_COLS_registrations="id STRING, amend_version INT, created_at BIGINT, enterprise_id STRING, procedure_code STRING, received_at BIGINT, registration_id STRING, status STRING, cancel_reason STRING, created_by STRING, updated_at BIGINT, version INT, procedure_name STRING"
KAFKA_COLS_registration_statuses="code STRING, business_name STRING, created_at BIGINT, description STRING, technical_name STRING"
KAFKA_COLS_registration_audit_log="id STRING, action STRING, created_at BIGINT, enterprise_id STRING, request_id STRING, status STRING, performed_by STRING, ip_address STRING, user_agent STRING, account STRING, full_name STRING, unit STRING, procedure_code STRING, reason STRING, procedure_name STRING"
KAFKA_COLS_registration_data="data_id STRING, created_at BIGINT, data_json STRING, version_id STRING"
KAFKA_COLS_registration_documents="id STRING, content STRING, created_at BIGINT, document_type STRING, registration_id STRING, amend_version INT, status STRING, file_id STRING, file_name STRING, created_by STRING"
KAFKA_COLS_registration_history="id STRING, created_at BIGINT, created_by STRING, payload STRING, registration_id STRING, status STRING, version INT"
KAFKA_COLS_registration_versions="id STRING, amend_version INT, payload_xml STRING, received_at BIGINT, request_id STRING, registration_id STRING"

KAFKA_COLS_alerts="alert_id STRING, alert_type STRING, created_at BIGINT, message STRING, reference_id STRING, severity STRING, source STRING, status STRING, updated_at BIGINT"
KAFKA_COLS_alert_audit_logs="id INT, alert_id STRING, changed_by STRING, changed_at BIGINT, previous_status STRING, new_status STRING, change_note STRING"
KAFKA_COLS_audit_logs="id STRING, action STRING, created_at BIGINT, module STRING, reference_id STRING, error_message STRING, ip_address STRING, source_system STRING, status STRING, request_time BIGINT"

KAFKA_COLS_invoices="id STRING, created_at BIGINT, amount DOUBLE, customer_name STRING, customer_phone STRING, invoice_code STRING, status STRING, created_by STRING, updated_at BIGINT, version INT"
KAFKA_COLS_invoice_items="id STRING, item_name STRING, price DOUBLE, quantity INT, total DOUBLE, invoice_id STRING, created_at BIGINT"
KAFKA_COLS_orders="id STRING, created_at BIGINT, customer_id STRING, order_code STRING, order_date BIGINT, status STRING, total_amount DOUBLE, updated_at BIGINT, note STRING"
KAFKA_COLS_order_items="id STRING, amount DOUBLE, price DOUBLE, product_id STRING, quantity INT, order_id STRING"

KAFKA_COLS_products="id STRING, created_at BIGINT, created_by STRING, description STRING, name STRING, price DOUBLE, status STRING, stock_qty INT, unit STRING, updated_at BIGINT, updated_by STRING, version INT, category_id STRING"
KAFKA_COLS_product_categories="id STRING, code STRING, created_at BIGINT, created_by STRING, description STRING, is_active INT, name STRING, updated_at BIGINT, updated_by STRING, version INT"

KAFKA_COLS_qc_enterprise="id INT, address STRING, email STRING, fax STRING, name STRING, phone STRING, tax_code STRING, representative_name STRING, business_license_no STRING, license_issue_date INT"
KAFKA_COLS_qc_application="id INT, application_code STRING, applied_standard STRING, commitment_checked INT, enterprise_id INT, gathering_place STRING, is_deleted INT, permit_code STRING, permit_date INT, procedure_type STRING, signer_date INT, signer_name STRING, signer_place STRING, signer_position STRING, status_id INT, submit_date INT, technical_regulation STRING"
KAFKA_COLS_qc_application_status="id INT, code STRING, name STRING"
KAFKA_COLS_qc_application_status_history="id INT, action_by STRING, action_time BIGINT, application_id INT, note STRING, status_id INT"
KAFKA_COLS_qc_application_goods="id INT, application_id INT, import_date INT, import_port STRING, origin_manufacturer STRING, product_name STRING, quantity_or_weight STRING, technical_specification STRING"
KAFKA_COLS_qc_application_attachments="id INT, application_id INT, file_path STRING, file_type STRING"
KAFKA_COLS_qc_application_import_docs="id INT, application_id INT, bill_of_lading STRING, cfs_number STRING, co_number STRING, conformity_cert_date INT, conformity_cert_number STRING, conformity_cert_org STRING, contract_number STRING, customs_declaration_no STRING, invoice_number STRING, packing_list STRING, quality_cert_number STRING, quality_cert_org STRING, import_date INT, invoice_date INT, port_of_arrival STRING"
KAFKA_COLS_qc_audit_log="id INT, action_name STRING, action_time BIGINT, module_name STRING, payload STRING, reference_id STRING"
KAFKA_COLS_qc_ministry="id INT, code STRING, name STRING, description STRING, is_deleted INT"
KAFKA_COLS_qc_procedure="id INT, code STRING, name STRING, description STRING, is_deleted INT"

KAFKA_COLS_applications="id INT, application_code STRING, created_at BIGINT, status STRING, procedure_id INT"
KAFKA_COLS_application_documents="id INT, data_content STRING, document_definition_id INT, version_id INT, application_id INT"
KAFKA_COLS_document_definition_versions="id INT, created_at BIGINT, is_active INT, schema_content STRING, version STRING, document_definition_id INT"
KAFKA_COLS_files="id STRING, created_at BIGINT, file_name STRING, file_path STRING, file_size BIGINT, mime_type STRING, original_name STRING, status STRING, created_by STRING, file_type STRING"
KAFKA_COLS_file_links="id INT, entity_id STRING, entity_type STRING, file_id STRING"
KAFKA_COLS_attachment="attachment_id STRING, checksum STRING, document_type STRING, file_name STRING, file_path STRING, file_size BIGINT, file_type STRING, uploaded_at BIGINT, version_id STRING"
KAFKA_COLS_attachments="id INT, dossier_id STRING, attachment_type STRING, file_name STRING, file_path STRING, file_format STRING, file_size_kb DOUBLE, is_required INT, uploaded_at BIGINT, label STRING"

KAFKA_COLS_app_user="id INT, password STRING, role STRING, username STRING, enterprise_tax_code STRING"
KAFKA_COLS_auth_config="id INT, auth_type STRING, config_json STRING, is_active INT"

KAFKA_COLS_messages="id INT, created_at BIGINT, message_id STRING, parsed INT, parsed_content STRING, raw_message STRING, status STRING, tenant_id STRING"
KAFKA_COLS_message_store="id INT, created_at BIGINT, message_id STRING, parsed_content STRING, registration_id STRING, request_id STRING"
KAFKA_COLS_routing_messages="id INT, created_at BIGINT, message_id STRING, payload STRING, procedure_code STRING, status STRING, updated_at BIGINT"
KAFKA_COLS_received_responses="id INT, payload STRING, received_at BIGINT, registration_id STRING, response_id STRING, status STRING"
KAFKA_COLS_response_packages="id INT, created_at BIGINT, processing_result STRING, registration_id STRING, response_code STRING, response_id STRING, response_message STRING, status STRING, enterprise_id STRING"

KAFKA_COLS_signatures="signature_id STRING, cert_serial_number STRING, cert_subject STRING, created_at BIGINT, request_id STRING, sign_time BIGINT, signature_data STRING, signed_data STRING, verified INT, verified_at BIGINT"
KAFKA_COLS_signature_info="id INT, dossier_id STRING, signer_name STRING, signer_title STRING, signing_place STRING, signed_date INT, legal_commitment_confirmed INT"
KAFKA_COLS_signature_verification_log="id INT, created_at BIGINT, message STRING, request_id STRING, valid INT"

KAFKA_COLS_planning="id INT, created_at BIGINT, description STRING, dossier_code STRING, name STRING, request_id STRING, status STRING, status_message STRING, updated_at BIGINT"
KAFKA_COLS_procedures="code STRING, created_at BIGINT, name STRING, status STRING, version STRING, id INT"
KAFKA_COLS_procedure_documents="id INT, is_required INT, document_definition_id INT, procedure_id INT"
KAFKA_COLS_sync_sessions="sync_id STRING, created_at BIGINT, data_type STRING, end_time BIGINT, message STRING, source_system STRING, start_time BIGINT, status STRING, sync_mode STRING, failed_count INT, max_retry INT, retry_count INT, success_count INT"
KAFKA_COLS_system_limits="limit_id STRING, action_on_exceed STRING, created_at BIGINT, limit_type STRING, max_value DOUBLE, status STRING, target STRING, time_window STRING, updated_at BIGINT"
KAFKA_COLS_system_limit_audits="id INT, action_by STRING, action_time BIGINT, limit_id STRING, new_value STRING, note STRING, old_value STRING"
KAFKA_COLS_storage_config="id INT, config_json STRING, created_at BIGINT, secret_enc STRING, updated_at BIGINT, user_id STRING"
KAFKA_COLS_theme_config="id INT, config_json STRING, created_at BIGINT, status STRING, updated_at BIGINT"
KAFKA_COLS_status_codes="code STRING, name STRING, created_at BIGINT, description STRING, technical_name STRING"
KAFKA_COLS_asset="id STRING, created_at BIGINT, iot STRING, name STRING, project_id STRING, status INT, updated_at BIGINT, uuids STRING"
KAFKA_COLS_flyway_schema_history="installed_rank INT, version STRING, description STRING, type STRING, script STRING, checksum INT, installed_by STRING, installed_on BIGINT, execution_time INT, success INT"
KAFKA_COLS_test_table="column1 STRING"

# ── TRINO_COLS_<iceberg_table> ─────────────────────────────────
TRINO_COLS_adm_ministry="id INTEGER, order_no INTEGER, ministry_code VARCHAR, ministry_name VARCHAR, description VARCHAR, is_active INTEGER, created_at BIGINT, version INTEGER, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR"
TRINO_COLS_adm_department="id INTEGER, ministry_code VARCHAR, department_code VARCHAR, department_name VARCHAR, is_active INTEGER, is_primary INTEGER, created_at BIGINT, version INTEGER, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR"
TRINO_COLS_adm_branch="id INTEGER, department_code VARCHAR, unit_code VARCHAR, unit_name VARCHAR, is_active INTEGER, is_primary INTEGER, created_at BIGINT, version INTEGER, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR"
TRINO_COLS_adm_procedure="id INTEGER, ministry_code VARCHAR, procedure_code VARCHAR, procedure_name VARCHAR, procedure_version VARCHAR, is_active INTEGER, created_at BIGINT, version INTEGER, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR"

TRINO_COLS_admin_procedures="id INTEGER, code VARCHAR, created_at BIGINT, name VARCHAR, status VARCHAR"
TRINO_COLS_admin_document_definitions="id INTEGER, code VARCHAR, created_at BIGINT, description VARCHAR, name VARCHAR, status VARCHAR, updated_at BIGINT"
TRINO_COLS_admin_doc_def_versions="id INTEGER, created_at BIGINT, is_active INTEGER, schema_content VARCHAR, version VARCHAR, document_definition_id INTEGER"
TRINO_COLS_admin_procedure_documents="id INTEGER, is_required INTEGER, document_definition_id INTEGER, procedure_id INTEGER"
TRINO_COLS_admin_applications="id INTEGER, application_code VARCHAR, created_at BIGINT, status VARCHAR, procedure_id INTEGER"
TRINO_COLS_admin_app_documents="id INTEGER, data_content VARCHAR, document_definition_id INTEGER, version_id INTEGER, application_id INTEGER"
TRINO_COLS_admin_app_logs="id INTEGER, created_at BIGINT, message VARCHAR, status VARCHAR, step VARCHAR, application_id INTEGER"

TRINO_COLS_enterprise="tax_code VARCHAR, enterprise_name VARCHAR, address VARCHAR, phone VARCHAR, email VARCHAR, is_active INTEGER, created_at BIGINT, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR, version INTEGER"
TRINO_COLS_enterprises="id VARCHAR, created_at BIGINT, name VARCHAR, status VARCHAR, tax_code VARCHAR"
TRINO_COLS_enterprise_response="id INTEGER, created_at BIGINT, enterprise_id VARCHAR, registration_id VARCHAR, response_code VARCHAR, response_message VARCHAR, status VARCHAR, updated_at BIGINT"

TRINO_COLS_dossiers="dossier_id VARCHAR, dossier_no VARCHAR, tax_code VARCHAR, procedure_type VARCHAR, inspection_location VARCHAR, application_no VARCHAR, technical_regulation VARCHAR, declared_standard VARCHAR, application_date INTEGER, submitted_at BIGINT, permit_date INTEGER, processed_at BIGINT, status VARCHAR, is_deleted INTEGER, enterprise_name VARCHAR, created_at BIGINT, created_by VARCHAR, updated_at BIGINT, version INTEGER"
TRINO_COLS_dossier_legacy="id INTEGER, business_code VARCHAR, business_name VARCHAR, certificate_serial VARCHAR, channel VARCHAR, contact_email VARCHAR, created_at BIGINT, service_code VARCHAR, service_version VARCHAR, signature_method VARCHAR, status VARCHAR, submitted_at BIGINT, transaction_code VARCHAR, updated_at BIGINT, dossier_id VARCHAR"
TRINO_COLS_dossier_status_historys="id INTEGER, dossier_id VARCHAR, changed_by VARCHAR, changed_at BIGINT, previous_status VARCHAR, new_status VARCHAR, change_summary VARCHAR"
TRINO_COLS_dossier_status_history="id INTEGER, dossier_id VARCHAR, new_status VARCHAR, old_status VARCHAR, updated_at BIGINT, updated_by VARCHAR"
TRINO_COLS_processing_result="id INTEGER, dossier_id VARCHAR, notice_no VARCHAR, inspection_agency_name VARCHAR, signing_place VARCHAR, signed_date INTEGER, result_code VARCHAR, rejection_reason VARCHAR, created_at BIGINT"
TRINO_COLS_result_goods="id INTEGER, processing_result_id INTEGER, goods_name VARCHAR, origin_manufacturer VARCHAR, quantity_weight VARCHAR, unit VARCHAR"

TRINO_COLS_goods_declaration="id INTEGER, dossier_id VARCHAR, goods_name VARCHAR, technical_specification VARCHAR, origin_manufacturer VARCHAR, quantity_weight VARCHAR, import_port VARCHAR, expected_import_date INTEGER, created_at BIGINT"
TRINO_COLS_goods_certificate="id INTEGER, dossier_id VARCHAR, co_no VARCHAR, cfs_no VARCHAR, qms_certificate_no VARCHAR, qms_issuer VARCHAR, qms_issued_date INTEGER, conformity_cert_no VARCHAR, conformity_issuer VARCHAR, conformity_issued_date INTEGER, created_at BIGINT"

TRINO_COLS_dn_enterprise="id INTEGER, tax_code VARCHAR, name VARCHAR, address VARCHAR, phone VARCHAR, fax VARCHAR, created_at BIGINT, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR, version INTEGER"
TRINO_COLS_dn_inspection_dossier="id INTEGER, enterprise_id INTEGER, dossier_id VARCHAR, produce_type VARCHAR, submission_date INTEGER, application_number VARCHAR, collection_point VARCHAR, contract_number VARCHAR, goods_description VARCHAR, invoice_number VARCHAR, tracking_number VARCHAR, import_declaration_number VARCHAR, co_number VARCHAR, cfs_number VARCHAR, qms_certificate_number VARCHAR, conformity_certificate_number VARCHAR, created_at BIGINT, created_by VARCHAR, updated_at BIGINT, updated_by VARCHAR, version INTEGER"
TRINO_COLS_dn_documents="id INTEGER, inspection_dossier_id INTEGER, document_name VARCHAR, document_type VARCHAR, document_path VARCHAR, file_size BIGINT, mime_type VARCHAR, uploaded_time BIGINT"
TRINO_COLS_dn_dossier_history="id INTEGER, inspection_dossier_id INTEGER, sequence_no INTEGER, change_time BIGINT, change_content VARCHAR, dossier_status VARCHAR"
TRINO_COLS_dn_inspection_result="id INTEGER, inspection_dossier_id INTEGER, parent_agency_name VARCHAR, inspection_agency_name VARCHAR, notification_no VARCHAR, signing_place VARCHAR, signing_date INTEGER, result_content VARCHAR, result_description VARCHAR, received_time BIGINT"
TRINO_COLS_dn_inspection_result_document="id INTEGER, inspection_result_id INTEGER, document_name VARCHAR, document_type VARCHAR, document_path VARCHAR, file_size BIGINT, mime_type VARCHAR, uploaded_time BIGINT"
TRINO_COLS_dn_products="id INTEGER, inspection_dossier_id INTEGER, product_name VARCHAR, technical_specifications VARCHAR, origin_manufacturer VARCHAR, weight_or_quantity VARCHAR, entry_port VARCHAR, expected_entry_date INTEGER"
TRINO_COLS_dn_signatures="id INTEGER, inspection_dossier_id INTEGER, signed_by VARCHAR, signer_position VARCHAR, signing_location VARCHAR, signing_date INTEGER, agreement_checked INTEGER"

TRINO_COLS_registrations="id VARCHAR, amend_version INTEGER, created_at BIGINT, enterprise_id VARCHAR, procedure_code VARCHAR, received_at BIGINT, registration_id VARCHAR, status VARCHAR, cancel_reason VARCHAR, created_by VARCHAR, updated_at BIGINT, version INTEGER, procedure_name VARCHAR"
TRINO_COLS_registration_statuses="code VARCHAR, business_name VARCHAR, created_at BIGINT, description VARCHAR, technical_name VARCHAR"
TRINO_COLS_registration_audit_log="id VARCHAR, action VARCHAR, created_at BIGINT, enterprise_id VARCHAR, request_id VARCHAR, status VARCHAR, performed_by VARCHAR, ip_address VARCHAR, user_agent VARCHAR, account VARCHAR, full_name VARCHAR, unit VARCHAR, procedure_code VARCHAR, reason VARCHAR, procedure_name VARCHAR"
TRINO_COLS_registration_data="data_id VARCHAR, created_at BIGINT, data_json VARCHAR, version_id VARCHAR"
TRINO_COLS_registration_documents="id VARCHAR, content VARCHAR, created_at BIGINT, document_type VARCHAR, registration_id VARCHAR, amend_version INTEGER, status VARCHAR, file_id VARCHAR, file_name VARCHAR, created_by VARCHAR"
TRINO_COLS_registration_history="id VARCHAR, created_at BIGINT, created_by VARCHAR, payload VARCHAR, registration_id VARCHAR, status VARCHAR, version INTEGER"
TRINO_COLS_registration_versions="id VARCHAR, amend_version INTEGER, payload_xml VARCHAR, received_at BIGINT, request_id VARCHAR, registration_id VARCHAR"

TRINO_COLS_alerts="alert_id VARCHAR, alert_type VARCHAR, created_at BIGINT, message VARCHAR, reference_id VARCHAR, severity VARCHAR, source VARCHAR, status VARCHAR, updated_at BIGINT"
TRINO_COLS_alert_audit_logs="id INTEGER, alert_id VARCHAR, changed_by VARCHAR, changed_at BIGINT, previous_status VARCHAR, new_status VARCHAR, change_note VARCHAR"
TRINO_COLS_audit_logs="id VARCHAR, action VARCHAR, created_at BIGINT, module VARCHAR, reference_id VARCHAR, error_message VARCHAR, ip_address VARCHAR, source_system VARCHAR, status VARCHAR, request_time BIGINT"

TRINO_COLS_invoices="id VARCHAR, created_at BIGINT, amount DOUBLE, customer_name VARCHAR, customer_phone VARCHAR, invoice_code VARCHAR, status VARCHAR, created_by VARCHAR, updated_at BIGINT, version INTEGER"
TRINO_COLS_invoice_items="id VARCHAR, item_name VARCHAR, price DOUBLE, quantity INTEGER, total DOUBLE, invoice_id VARCHAR, created_at BIGINT"
TRINO_COLS_orders="id VARCHAR, created_at BIGINT, customer_id VARCHAR, order_code VARCHAR, order_date BIGINT, status VARCHAR, total_amount DOUBLE, updated_at BIGINT, note VARCHAR"
TRINO_COLS_order_items="id VARCHAR, amount DOUBLE, price DOUBLE, product_id VARCHAR, quantity INTEGER, order_id VARCHAR"

TRINO_COLS_products="id VARCHAR, created_at BIGINT, created_by VARCHAR, description VARCHAR, name VARCHAR, price DOUBLE, status VARCHAR, stock_qty INTEGER, unit VARCHAR, updated_at BIGINT, updated_by VARCHAR, version INTEGER, category_id VARCHAR"
TRINO_COLS_product_categories="id VARCHAR, code VARCHAR, created_at BIGINT, created_by VARCHAR, description VARCHAR, is_active INTEGER, name VARCHAR, updated_at BIGINT, updated_by VARCHAR, version INTEGER"

TRINO_COLS_qc_enterprise="id INTEGER, address VARCHAR, email VARCHAR, fax VARCHAR, name VARCHAR, phone VARCHAR, tax_code VARCHAR, representative_name VARCHAR, business_license_no VARCHAR, license_issue_date INTEGER"
TRINO_COLS_qc_application="id INTEGER, application_code VARCHAR, applied_standard VARCHAR, commitment_checked INTEGER, enterprise_id INTEGER, gathering_place VARCHAR, is_deleted INTEGER, permit_code VARCHAR, permit_date INTEGER, procedure_type VARCHAR, signer_date INTEGER, signer_name VARCHAR, signer_place VARCHAR, signer_position VARCHAR, status_id INTEGER, submit_date INTEGER, technical_regulation VARCHAR"
TRINO_COLS_qc_application_status="id INTEGER, code VARCHAR, name VARCHAR"
TRINO_COLS_qc_application_status_history="id INTEGER, action_by VARCHAR, action_time BIGINT, application_id INTEGER, note VARCHAR, status_id INTEGER"
TRINO_COLS_qc_application_goods="id INTEGER, application_id INTEGER, import_date INTEGER, import_port VARCHAR, origin_manufacturer VARCHAR, product_name VARCHAR, quantity_or_weight VARCHAR, technical_specification VARCHAR"
TRINO_COLS_qc_application_attachments="id INTEGER, application_id INTEGER, file_path VARCHAR, file_type VARCHAR"
TRINO_COLS_qc_application_import_docs="id INTEGER, application_id INTEGER, bill_of_lading VARCHAR, cfs_number VARCHAR, co_number VARCHAR, conformity_cert_date INTEGER, conformity_cert_number VARCHAR, conformity_cert_org VARCHAR, contract_number VARCHAR, customs_declaration_no VARCHAR, invoice_number VARCHAR, packing_list VARCHAR, quality_cert_number VARCHAR, quality_cert_org VARCHAR, import_date INTEGER, invoice_date INTEGER, port_of_arrival VARCHAR"
TRINO_COLS_qc_audit_log="id INTEGER, action_name VARCHAR, action_time BIGINT, module_name VARCHAR, payload VARCHAR, reference_id VARCHAR"
TRINO_COLS_qc_ministry="id INTEGER, code VARCHAR, name VARCHAR, description VARCHAR, is_deleted INTEGER"
TRINO_COLS_qc_procedure="id INTEGER, code VARCHAR, name VARCHAR, description VARCHAR, is_deleted INTEGER"

TRINO_COLS_applications="id INTEGER, application_code VARCHAR, created_at BIGINT, status VARCHAR, procedure_id INTEGER"
TRINO_COLS_application_documents="id INTEGER, data_content VARCHAR, document_definition_id INTEGER, version_id INTEGER, application_id INTEGER"
TRINO_COLS_document_definition_versions="id INTEGER, created_at BIGINT, is_active INTEGER, schema_content VARCHAR, version VARCHAR, document_definition_id INTEGER"
TRINO_COLS_sys_files="id VARCHAR, created_at BIGINT, file_name VARCHAR, file_path VARCHAR, file_size BIGINT, mime_type VARCHAR, original_name VARCHAR, status VARCHAR, created_by VARCHAR, file_type VARCHAR"
TRINO_COLS_file_links="id INTEGER, entity_id VARCHAR, entity_type VARCHAR, file_id VARCHAR"
TRINO_COLS_attachment="attachment_id VARCHAR, checksum VARCHAR, document_type VARCHAR, file_name VARCHAR, file_path VARCHAR, file_size BIGINT, file_type VARCHAR, uploaded_at BIGINT, version_id VARCHAR"
TRINO_COLS_attachments="id INTEGER, dossier_id VARCHAR, attachment_type VARCHAR, file_name VARCHAR, file_path VARCHAR, file_format VARCHAR, file_size_kb DOUBLE, is_required INTEGER, uploaded_at BIGINT, label VARCHAR"

TRINO_COLS_app_user="id INTEGER, password VARCHAR, role VARCHAR, username VARCHAR, enterprise_tax_code VARCHAR"
TRINO_COLS_auth_config="id INTEGER, auth_type VARCHAR, config_json VARCHAR, is_active INTEGER"

TRINO_COLS_messages="id INTEGER, created_at BIGINT, message_id VARCHAR, parsed INTEGER, parsed_content VARCHAR, raw_message VARCHAR, status VARCHAR, tenant_id VARCHAR"
TRINO_COLS_message_store="id INTEGER, created_at BIGINT, message_id VARCHAR, parsed_content VARCHAR, registration_id VARCHAR, request_id VARCHAR"
TRINO_COLS_routing_messages="id INTEGER, created_at BIGINT, message_id VARCHAR, payload VARCHAR, procedure_code VARCHAR, status VARCHAR, updated_at BIGINT"
TRINO_COLS_received_responses="id INTEGER, payload VARCHAR, received_at BIGINT, registration_id VARCHAR, response_id VARCHAR, status VARCHAR"
TRINO_COLS_response_packages="id INTEGER, created_at BIGINT, processing_result VARCHAR, registration_id VARCHAR, response_code VARCHAR, response_id VARCHAR, response_message VARCHAR, status VARCHAR, enterprise_id VARCHAR"

TRINO_COLS_signatures="signature_id VARCHAR, cert_serial_number VARCHAR, cert_subject VARCHAR, created_at BIGINT, request_id VARCHAR, sign_time BIGINT, signature_data VARCHAR, signed_data VARCHAR, verified INTEGER, verified_at BIGINT"
TRINO_COLS_signature_info="id INTEGER, dossier_id VARCHAR, signer_name VARCHAR, signer_title VARCHAR, signing_place VARCHAR, signed_date INTEGER, legal_commitment_confirmed INTEGER"
TRINO_COLS_signature_verification_log="id INTEGER, created_at BIGINT, message VARCHAR, request_id VARCHAR, valid INTEGER"

TRINO_COLS_planning="id INTEGER, created_at BIGINT, description VARCHAR, dossier_code VARCHAR, name VARCHAR, request_id VARCHAR, status VARCHAR, status_message VARCHAR, updated_at BIGINT"
TRINO_COLS_procedures="code VARCHAR, created_at BIGINT, name VARCHAR, status VARCHAR, version VARCHAR, id INTEGER"
TRINO_COLS_procedure_documents="id INTEGER, is_required INTEGER, document_definition_id INTEGER, procedure_id INTEGER"
TRINO_COLS_sync_sessions="sync_id VARCHAR, created_at BIGINT, data_type VARCHAR, end_time BIGINT, message VARCHAR, source_system VARCHAR, start_time BIGINT, status VARCHAR, sync_mode VARCHAR, failed_count INTEGER, max_retry INTEGER, retry_count INTEGER, success_count INTEGER"
TRINO_COLS_system_limits="limit_id VARCHAR, action_on_exceed VARCHAR, created_at BIGINT, limit_type VARCHAR, max_value DOUBLE, status VARCHAR, target VARCHAR, time_window VARCHAR, updated_at BIGINT"
TRINO_COLS_system_limit_audits="id INTEGER, action_by VARCHAR, action_time BIGINT, limit_id VARCHAR, new_value VARCHAR, note VARCHAR, old_value VARCHAR"
TRINO_COLS_storage_config="id INTEGER, config_json VARCHAR, created_at BIGINT, secret_enc VARCHAR, updated_at BIGINT, user_id VARCHAR"
TRINO_COLS_theme_config="id INTEGER, config_json VARCHAR, created_at BIGINT, status VARCHAR, updated_at BIGINT"
TRINO_COLS_status_codes="code VARCHAR, name VARCHAR, created_at BIGINT, description VARCHAR, technical_name VARCHAR"
TRINO_COLS_asset="id VARCHAR, created_at BIGINT, iot VARCHAR, name VARCHAR, project_id VARCHAR, status INTEGER, updated_at BIGINT, uuids VARCHAR"
TRINO_COLS_flyway_schema_history="installed_rank INTEGER, version VARCHAR, description VARCHAR, type VARCHAR, script VARCHAR, checksum INTEGER, installed_by VARCHAR, installed_on BIGINT, execution_time INTEGER, success INTEGER"
TRINO_COLS_test_table="column1 VARCHAR"

# ── Cleanup lists ─────────────────────────────────────────────
ICEBERG_TABLES_CLEANUP=()
TRINO_TABLES_CLEANUP=()
for entry in "${TABLES_REGISTRY[@]}"; do
  IFS='|' read -r mysql_tbl iceberg_tbl pk kgroup transform <<< "$entry"
  ICEBERG_TABLES_CLEANUP+=("$iceberg_tbl")
  TRINO_TABLES_CLEANUP+=("${iceberg_tbl}_raw")
done

TRINO_VIEWS_CLEANUP=(
  "dossier_summary" "alert_dashboard"
  "registration_stats" "invoice_revenue"
  "enterprise_activity" "dn_inspection_stats"
)
