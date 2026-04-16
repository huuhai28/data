-- ================================================================
--  admin_seed.sql — Seed data cho các bảng chính
-- ================================================================
USE admin_db;

-- ── adm_ministry ──────────────────────────────────────────────
INSERT INTO adm_ministry (order_no, ministry_code, ministry_name, description, is_active, created_by) VALUES
  (1,'BTC','Bo Tai Chinh','Ngan sach thue hai quan',1,'admin'),
  (2,'BCT','Bo Cong Thuong','San xuat thuong mai',1,'admin'),
  (3,'BYT','Bo Y te','Y te duoc pham',1,'admin'),
  (4,'BNN','Bo Nong nghiep va PTNT','Nong nghiep',1,'admin'),
  (5,'BGD','Bo Giao duc va Dao tao','Giao duc',1,'admin')
ON DUPLICATE KEY UPDATE ministry_name=VALUES(ministry_name);

-- ── adm_department ────────────────────────────────────────────
INSERT INTO adm_department (ministry_code, department_code, department_name, is_active, created_by) VALUES
  ('BTC','BTC_THUE','Cuc Thue',1,'admin'),
  ('BTC','BTC_HAIQUAN','Tong cuc Hai quan',1,'admin'),
  ('BCT','BCT_TMDT','Cuc Thuong mai dien tu',1,'admin'),
  ('BYT','BYT_DUOC','Cuc Quan ly Duoc',1,'admin'),
  ('BYT','BYT_ATVSTP','Cuc An toan thuc pham',1,'admin'),
  ('BNN','BNN_BVTV','Cuc Bao ve thuc vat',1,'admin'),
  ('BNN','BNN_TY','Cuc Thu y',1,'admin'),
  ('BGD','BGD_GDDT','Cuc Quan ly day va hoc',1,'admin')
ON DUPLICATE KEY UPDATE department_name=VALUES(department_name);

-- ── adm_branch ────────────────────────────────────────────────
INSERT INTO adm_branch (department_code, unit_code, unit_name, is_active, created_by) VALUES
  ('BTC_THUE','BTC_THUE_HN','Cuc Thue Ha Noi',1,'admin'),
  ('BTC_THUE','BTC_THUE_HCM','Cuc Thue TP HCM',1,'admin'),
  ('BTC_HAIQUAN','BTC_HQ_CATLAI','Chi cuc HQ Cang Cat Lai',1,'admin'),
  ('BYT_DUOC','BYT_DUOC_HN','Phong Quan ly Duoc Ha Noi',1,'admin'),
  ('BNN_BVTV','BNN_BVTV_MB','Chi cuc Kiem dich mien Bac',1,'admin')
ON DUPLICATE KEY UPDATE unit_name=VALUES(unit_name);

-- ── adm_procedure ─────────────────────────────────────────────
INSERT INTO adm_procedure (ministry_code, procedure_code, procedure_name, procedure_version, is_active, created_by) VALUES
  ('BCT','BCT-NK-001','Cap phep nhap khau hang hoa','v1.0',1,'admin'),
  ('BCT','BCT-NK-002','Cap phep nhap khau duoc lieu','v1.0',1,'admin'),
  ('BYT','BYT-DP-001','Dang ky luu hanh thuoc','v2.0',1,'admin'),
  ('BYT','BYT-TP-001','Cap phep an toan thuc pham','v1.0',1,'admin'),
  ('BNN','BNN-TV-001','Cap phep kiem dich thuc vat','v1.0',1,'admin'),
  ('BNN','BNN-TY-001','Cap phep kiem dich dong vat','v1.2',1,'admin'),
  ('BTC','BTC-HQ-001','Khai bao hai quan dien tu','v3.0',1,'admin'),
  ('BGD','BGD-VB-001','Cap phep van bang nuoc ngoai','v1.0',1,'admin')
ON DUPLICATE KEY UPDATE procedure_name=VALUES(procedure_name);

-- ── enterprise ────────────────────────────────────────────────
INSERT INTO enterprise (tax_code, enterprise_name, address, phone, email, is_active, created_by) VALUES
  ('0101234567','Cong ty TNHH Xuat Nhap Khau Phu Hung','123 Le Duan, Ha Noi','0241234567','phuhung@example.com',1,'admin'),
  ('0209876543','Cong ty CP Thuong Mai Viet Thang','45 Nguyen Hue, TP HCM','0289876543','vietthang@example.com',1,'admin'),
  ('0312345678','Cong ty TNHH Duoc Pham Thanh Dat','78 Tran Hung Dao, Da Nang','0236123456','thanhdat@example.com',1,'admin'),
  ('0498765432','Cong ty CP Thuc Pham Sach Mien Nam','12 Pasteur, TP HCM','0298765432','sachmiennam@example.com',1,'admin'),
  ('0511223344','Cong ty TNHH Nong San Xanh','56 Hung Vuong, Can Tho','0271122334','nongsanxanh@example.com',1,'admin'),
  ('0644332211','Cong ty CP Cong Nghe Tin Hoc Viet','99 Giai Phong, Ha Noi','0244332211','cnviet@example.com',1,'admin'),
  ('0755443322','Cong ty TNHH May Mac Thien Phuc','34 Cong Quynh, TP HCM','0255443322','thienphuc@example.com',1,'admin'),
  ('0866554433','Cong ty CP Xay Dung Ha Long','10 Ha Long, Quang Ninh','0233665544','halong@example.com',1,'admin'),
  ('0977665544','Cong ty TNHH Kho Van Logistics','200 Nguyen Van Cu, Ha Noi','0247766554','logistics@example.com',1,'admin'),
  ('1088776655','Cong ty CP Dich Vu Hai Quan Quoc Te','77 Ly Thuong Kiet, TP HCM','0288776655','haiquanqt@example.com',1,'admin')
ON DUPLICATE KEY UPDATE enterprise_name=VALUES(enterprise_name);

-- ── dossiers ──────────────────────────────────────────────────
TRUNCATE TABLE dossiers;
INSERT INTO dossiers (dossier_id, dossier_no, tax_code, procedure_type, inspection_location, application_no, technical_regulation, declared_standard, application_date, submitted_at, processed_at, status, enterprise_name, created_by) VALUES
  ('DOS-001','DN-001','0101234567','NOP_LAN_DAU','Cang Ha Noi','APP-001','QCVN 01:2021','ISO 9001:2015','2026-04-01','2026-04-02 08:00:00',NULL,'DANG_XU_LY','Cong ty TNHH Xuat Nhap Khau Phu Hung','admin'),
  ('DOS-002','DN-002','0209876543','NOP_LAN_DAU','Cang Cat Lai','APP-002','QCVN 02:2021','ISO 9001:2015','2026-04-01','2026-04-01 09:00:00','2026-04-05 14:00:00','DA_DUYET','Cong ty CP Thuong Mai Viet Thang','admin'),
  ('DOS-003','DN-003','0312345678','NOP_LAN_DAU','Cang Da Nang','APP-003','QCVN 03:2020','ISO 14001','2026-04-02','2026-04-02 10:00:00',NULL,'CHO_BO_SUNG','Cong ty TNHH Duoc Pham Thanh Dat','admin'),
  ('DOS-004','DN-004','0498765432','NOP_LAN_DAU','Cang Sai Gon','APP-004','QCVN 04:2021','HACCP','2026-04-02','2026-04-03 08:30:00',NULL,'DANG_XU_LY','Cong ty CP Thuc Pham Sach Mien Nam','admin'),
  ('DOS-005','DN-005','0511223344','NOP_LAN_DAU','Cang Can Tho','APP-005','QCVN 05:2020','VietGAP','2026-04-03','2026-04-03 11:00:00','2026-04-08 10:00:00','TU_CHOI','Cong ty TNHH Nong San Xanh','admin'),
  ('DOS-006','DN-006','0644332211','NOP_LAN_DAU','Cang Ha Phong','APP-006','QCVN 01:2021','ISO 9001:2015','2026-04-03','2026-04-04 09:00:00','2026-04-07 16:00:00','DA_DUYET','Cong ty CP Cong Nghe Tin Hoc Viet','admin'),
  ('DOS-007','DN-007','0755443322','BO_SUNG','Cang Cat Lai','APP-007','QCVN 07:2019','ISO 9001:2015','2026-04-04','2026-04-04 14:00:00',NULL,'DANG_XU_LY','Cong ty TNHH May Mac Thien Phuc','admin'),
  ('DOS-008','DN-008','0866554433','NOP_LAN_DAU','Cua khau Mong Cai','APP-008','QCVN 08:2021','ISO 14001','2026-04-05','2026-04-05 10:00:00',NULL,'TAO_MOI','Cong ty CP Xay Dung Ha Long','admin'),
  ('DOS-009','DN-009','0977665544','NOP_LAN_DAU','Cang Tien Sa','APP-009','QCVN 09:2020','ISO 9001:2015','2026-04-06','2026-04-06 08:00:00','2026-04-10 11:00:00','DA_DUYET','Cong ty TNHH Kho Van Logistics','admin'),
  ('DOS-010','DN-010','1088776655','NOP_LAN_DAU','Cang Ha Noi','APP-010','QCVN 01:2021','ISO 9001:2015','2026-04-07',NULL,NULL,'TAO_MOI','Cong ty CP Dich Vu Hai Quan Quoc Te','admin');

-- ── dossier_status_historys ───────────────────────────────────
TRUNCATE TABLE dossier_status_historys;
INSERT INTO dossier_status_historys (dossier_id, changed_by, changed_at, previous_status, new_status, change_summary) VALUES
  ('DOS-001','admin','2026-04-02 08:00:00','TAO_MOI','DANG_XU_LY','Nop ho so'),
  ('DOS-002','admin','2026-04-01 09:00:00','TAO_MOI','DANG_XU_LY','Nop ho so'),
  ('DOS-002','officer01','2026-04-05 14:00:00','DANG_XU_LY','DA_DUYET','Ho so hop le'),
  ('DOS-003','admin','2026-04-02 10:00:00','TAO_MOI','DANG_XU_LY','Nop ho so'),
  ('DOS-003','officer02','2026-04-07 09:00:00','DANG_XU_LY','CHO_BO_SUNG','Thieu tai lieu'),
  ('DOS-005','officer01','2026-04-08 10:00:00','DANG_XU_LY','TU_CHOI','Khong dat tieu chuan'),
  ('DOS-006','officer03','2026-04-07 16:00:00','DANG_XU_LY','DA_DUYET','Ho so hop le'),
  ('DOS-009','officer02','2026-04-10 11:00:00','DANG_XU_LY','DA_DUYET','Ho so hop le');

-- ── processing_result ─────────────────────────────────────────
TRUNCATE TABLE processing_result;
INSERT INTO processing_result (dossier_id, notice_no, inspection_agency_name, signing_place, signed_date, result_code, rejection_reason) VALUES
  ('DOS-002','TB-002','Cuc Thu y - Bo NN','Ha Noi','2026-04-05','DAP_UNG',NULL),
  ('DOS-005','TB-005','Cuc BVTV - Bo NN','Ha Noi','2026-04-08','KHONG_DAP_UNG','Khong dat vi sinh vat'),
  ('DOS-006','TB-006','Cuc Quan ly Duoc','Ha Noi','2026-04-07','DAP_UNG',NULL),
  ('DOS-009','TB-009','Cuc ATVSTP','Ha Noi','2026-04-10','DAP_UNG',NULL);

-- ── goods_declaration ─────────────────────────────────────────
TRUNCATE TABLE goods_declaration;
INSERT INTO goods_declaration (dossier_id, goods_name, technical_specification, origin_manufacturer, quantity_weight, import_port, expected_import_date) VALUES
  ('DOS-001','Thiet bi y te','ISO 13485-2016','Siemens AG - Germany','500 kg','Cang Ha Noi','2026-04-15'),
  ('DOS-002','Thuc pham dong goi','HACCP 2019','Nestle - Switzerland','2000 kg','Cang Cat Lai','2026-04-10'),
  ('DOS-003','Duoc pham','USP 43','Pfizer Inc - USA','100 kg','Cang Da Nang','2026-04-20'),
  ('DOS-004','Thuc pham chuc nang','CODEX STAN 192','Abbott - USA','300 kg','Cang Sai Gon','2026-04-18'),
  ('DOS-005','Hat giong','ISTA 2023','Syngenta - Switzerland','1000 kg','Cang Can Tho','2026-04-12');

-- ── registrations ─────────────────────────────────────────────
TRUNCATE TABLE registrations;
INSERT INTO registrations (id, amend_version, created_at, enterprise_id, procedure_code, received_at, registration_id, status, created_by, procedure_name) VALUES
  ('REG-001',0,'2026-04-01 08:00:00','0101234567','BCT-NK-001','2026-04-01 08:05:00','DK-001','APPROVED','admin','Cap phep nhap khau hang hoa'),
  ('REG-002',0,'2026-04-01 10:00:00','0312345678','BYT-DP-001','2026-04-01 10:05:00','DK-002','PROCESSING','admin','Dang ky luu hanh thuoc'),
  ('REG-003',0,'2026-04-02 09:00:00','0498765432','BYT-TP-001','2026-04-02 09:05:00','DK-003','APPROVED','admin','Cap phep ATVSTP'),
  ('REG-004',1,'2026-04-02 14:00:00','0511223344','BNN-TV-001','2026-04-02 14:05:00','DK-004','REJECTED','admin','Cap phep kiem dich thuc vat'),
  ('REG-005',0,'2026-04-03 08:00:00','0209876543','BTC-HQ-001','2026-04-03 08:05:00','DK-005','APPROVED','admin','Khai bao hai quan'),
  ('REG-006',0,'2026-04-03 11:00:00','0644332211','BCT-NK-002','2026-04-03 11:05:00','DK-006','PROCESSING','admin','Cap phep nhap khau duoc lieu'),
  ('REG-007',0,'2026-04-04 09:00:00','0755443322','BCT-NK-001','2026-04-04 09:05:00','DK-007','APPROVED','admin','Cap phep nhap khau hang hoa'),
  ('REG-008',0,'2026-04-05 10:00:00','0866554433','BNN-TY-001','2026-04-05 10:05:00','DK-008','PROCESSING','admin','Cap phep kiem dich dong vat'),
  ('REG-009',0,'2026-04-06 08:00:00','0977665544','BTC-HQ-001','2026-04-06 08:05:00','DK-009','APPROVED','admin','Khai bao hai quan'),
  ('REG-010',0,'2026-04-07 09:00:00','1088776655','BCT-NK-001','2026-04-07 09:05:00','DK-010','RECEIVED','admin','Cap phep nhap khau hang hoa');

-- ── registration_statuses ────────────────────────────────────
INSERT INTO registration_statuses (code, business_name, description, technical_name) VALUES
  ('RECEIVED','Da tiep nhan','Ho so da duoc tiep nhan','RECEIVED'),
  ('PROCESSING','Dang xu ly','Ho so dang trong qua trinh xu ly','PROCESSING'),
  ('APPROVED','Da duyet','Ho so duoc chap thuan','APPROVED'),
  ('REJECTED','Bi tu choi','Ho so bi tu choi','REJECTED'),
  ('CANCELLED','Da huy','Ho so da bi huy','CANCELLED')
ON DUPLICATE KEY UPDATE business_name=VALUES(business_name);

-- ── alerts ───────────────────────────────────────────────────
TRUNCATE TABLE alerts;
INSERT INTO alerts (alert_id, alert_type, created_at, message, reference_id, severity, source, status, updated_at) VALUES
  ('ALT-001','DOSSIER_OVERDUE','2026-04-06 08:00:00','Ho so DOS-001 qua han 3 ngay','DOS-001','WARNING','SYSTEM','NEW',NULL),
  ('ALT-002','REGISTRATION_FAIL','2026-04-08 10:00:00','Dang ky DK-004 bi tu choi','DK-004','CRITICAL','SYSTEM','ACKNOWLEDGED','2026-04-08 11:00:00'),
  ('ALT-003','CERT_EXPIRING','2026-04-09 09:00:00','Giay phep DN 0312345678 sap het han','0312345678','WARNING','CERT_SVC','NEW',NULL),
  ('ALT-004','API_ERROR','2026-04-08 14:00:00','Loi ket noi API cong TT quoc gia','API-GOV','CRITICAL','API_GW','RESOLVED','2026-04-08 15:00:00'),
  ('ALT-005','DOSSIER_OVERDUE','2026-04-09 08:00:00','Ho so DOS-004 qua han 3 ngay','DOS-004','WARNING','SYSTEM','NEW',NULL),
  ('ALT-006','SYNC_FAILED','2026-04-07 22:00:00','Dong bo BCT that bai','SYNC-BCT','CRITICAL','SYNC_SVC','RESOLVED','2026-04-07 23:00:00'),
  ('ALT-007','INSPECTION_RESULT','2026-04-08 10:30:00','Ket qua DOS-005 KHONG DAP UNG','DOS-005','INFO','INSP_SVC','NEW',NULL),
  ('ALT-008','DOSSIER_OVERDUE','2026-04-10 08:00:00','Ho so DOS-007 qua han 4 ngay','DOS-007','CRITICAL','SYSTEM','NEW',NULL);

-- ── invoices ──────────────────────────────────────────────────
TRUNCATE TABLE invoices;
INSERT INTO invoices (id, created_at, amount, customer_name, customer_phone, invoice_code, status, created_by) VALUES
  ('INV-001','2026-04-01 10:00:00',1500000,'Cong ty Phu Hung','0241234567','HD-001','PAID','admin'),
  ('INV-002','2026-04-02 11:00:00',2300000,'Cong ty Viet Thang','0289876543','HD-002','PENDING','admin'),
  ('INV-003','2026-04-03 09:00:00',800000,'Cong ty Thanh Dat','0236123456','HD-003','PAID','admin'),
  ('INV-004','2026-04-04 14:00:00',3200000,'Cong ty Sach Mien Nam','0298765432','HD-004','PAID','admin'),
  ('INV-005','2026-04-05 10:00:00',1100000,'Cong ty Nong San Xanh','0271122334','HD-005','PENDING','admin'),
  ('INV-006','2026-04-06 08:00:00',4500000,'Cong ty Tin Hoc Viet','0244332211','HD-006','OVERDUE','admin'),
  ('INV-007','2026-04-07 09:00:00',2700000,'Cong ty May Mac','0255443322','HD-007','PAID','admin'),
  ('INV-008','2026-04-08 11:00:00',1900000,'Cong ty Ha Long','0233665544','HD-008','PENDING','admin');

-- ── invoice_items ─────────────────────────────────────────────
TRUNCATE TABLE invoice_items;
INSERT INTO invoice_items (id, item_name, price, quantity, total, invoice_id, created_at) VALUES
  ('II-001a','Le phi tham dinh',500000,1,500000,'INV-001','2026-04-01 10:00:00'),
  ('II-001b','Le phi cap phep',1000000,1,1000000,'INV-001','2026-04-01 10:00:00'),
  ('II-002a','Le phi tham dinh',500000,1,500000,'INV-002','2026-04-02 11:00:00'),
  ('II-002b','Le phi kiem dinh',1800000,1,1800000,'INV-002','2026-04-02 11:00:00'),
  ('II-003a','Le phi cap phep',800000,1,800000,'INV-003','2026-04-03 09:00:00'),
  ('II-004a','Le phi tham dinh',500000,1,500000,'INV-004','2026-04-04 14:00:00'),
  ('II-004b','Le phi kiem dinh mau',2700000,1,2700000,'INV-004','2026-04-04 14:00:00');

-- ── orders ───────────────────────────────────────────────────
TRUNCATE TABLE orders;
INSERT INTO orders (id, created_at, customer_id, order_code, order_date, status, total_amount, note) VALUES
  ('ORD-001','2026-04-01 09:00:00','0101234567','DH-001','2026-04-01 09:00:00','COMPLETED',15000000,'Dich vu tham dinh tron goi'),
  ('ORD-002','2026-04-02 10:00:00','0312345678','DH-002','2026-04-02 10:00:00','PROCESSING',23000000,'Goi cap phep duoc pham'),
  ('ORD-003','2026-04-03 11:00:00','0498765432','DH-003','2026-04-03 11:00:00','COMPLETED',8500000,'Tu van ATVSTP'),
  ('ORD-004','2026-04-04 08:00:00','0511223344','DH-004','2026-04-04 08:00:00','CANCELLED',6000000,'Huy do ho so bi tu choi'),
  ('ORD-005','2026-04-05 14:00:00','0755443322','DH-005','2026-04-05 14:00:00','PROCESSING',18000000,'Kiem dinh hang may mac');

-- ── audit_logs ────────────────────────────────────────────────
TRUNCATE TABLE audit_logs;
INSERT INTO audit_logs (id, action, created_at, module, reference_id, ip_address, source_system, status, request_time) VALUES
  ('LOG-001','SUBMIT','2026-04-01 08:05:00','DOSSIER','DOS-001','113.190.1.1','PORTAL','SUCCESS','2026-04-01 08:04:58'),
  ('LOG-002','APPROVE','2026-04-05 14:00:00','DOSSIER','DOS-002','10.0.0.5','OFFICE','SUCCESS','2026-04-05 13:59:50'),
  ('LOG-003','REGISTER','2026-04-01 08:05:00','REGISTRATION','REG-001','113.190.1.1','PORTAL','SUCCESS','2026-04-01 08:04:55'),
  ('LOG-004','REJECT','2026-04-08 10:00:00','REGISTRATION','REG-004','10.0.0.6','OFFICE','SUCCESS','2026-04-08 09:59:45'),
  ('LOG-005','LOGIN','2026-04-09 08:00:00','AUTH','USER-001','192.168.1.100','PORTAL','SUCCESS','2026-04-09 07:59:58'),
  ('LOG-006','API_CALL','2026-04-08 14:00:00','INTEGRATION','API-GOV','10.0.0.1','API_GW','FAILED','2026-04-08 13:59:50');

-- ── sync_sessions ────────────────────────────────────────────
INSERT INTO sync_sessions (sync_id, created_at, data_type, start_time, status, sync_mode, source_system, success_count, failed_count) VALUES
  ('SYNC-001','2026-04-10 02:00:00','DOSSIER','2026-04-10 02:00:00','COMPLETED','FULL','ORACLE',145,2),
  ('SYNC-002','2026-04-10 06:00:00','REGISTRATION','2026-04-10 06:00:00','COMPLETED','INCREMENTAL','ORACLE',23,0),
  ('SYNC-003','2026-04-10 10:00:00','INVOICE','2026-04-10 10:00:00','FAILED','INCREMENTAL','BILLING',0,5);

-- ── system_limits ────────────────────────────────────────────
INSERT INTO system_limits (limit_id, action_on_exceed, limit_type, max_value, status, target, time_window) VALUES
  ('LIM-001','BLOCK','API_RATE',100,'ACTIVE','PORTAL','MINUTE'),
  ('LIM-002','WARN','FILE_SIZE',10485760,'ACTIVE','UPLOAD','SINGLE'),
  ('LIM-003','BLOCK','DOSSIER_DAILY',50,'ACTIVE','ENTERPRISE','DAY')
ON DUPLICATE KEY UPDATE max_value=VALUES(max_value);

-- ── status_codes ─────────────────────────────────────────────
INSERT INTO status_codes (code, name, description, technical_name) VALUES
  ('TAO_MOI','Tao moi','Ho so moi tao','CREATED'),
  ('DANG_XU_LY','Dang xu ly','Dang trong qua trinh xu ly','PROCESSING'),
  ('DA_DUYET','Da duyet','Da duoc chap thuan','APPROVED'),
  ('TU_CHOI','Tu choi','Bi tu choi','REJECTED'),
  ('CHO_BO_SUNG','Cho bo sung','Cho nguoi dung bo sung','PENDING_SUPPLEMENT'),
  ('DA_HUY','Da huy','Da bi huy','CANCELLED')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- ── qc_ministry + qc_procedure ──────────────────────────────
INSERT INTO qc_ministry (code, name, description) VALUES
  ('BCT','Bo Cong Thuong','Quan ly thuong mai'),
  ('BYT','Bo Y te','Quan ly y te'),
  ('BNN','Bo Nong nghiep','Quan ly nong nghiep')
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO qc_procedure (code, name) VALUES
  ('QC-NK-001','Kiem tra chat luong hang nhap khau'),
  ('QC-TP-001','Kiem tra ATVSTP'),
  ('QC-YT-001','Kiem tra thiet bi y te')
ON DUPLICATE KEY UPDATE name=VALUES(name);
