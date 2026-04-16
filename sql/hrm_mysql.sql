-- =============================================================
--  sql/hrm_mysql.sql — MySQL schema + seed data HRM
--  Thêm bảng mới: chỉ cần thêm CREATE TABLE + INSERT ở đây
-- =============================================================
CREATE DATABASE IF NOT EXISTS hrm;
USE hrm;

CREATE TABLE IF NOT EXISTS employees (
  emp_id     INT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  department VARCHAR(100) NOT NULL,
  salary     DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS attendance (
  id        INT PRIMARY KEY AUTO_INCREMENT,
  emp_id    INT NOT NULL,
  check_in  DATETIME,
  check_out DATETIME,
  status    VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS leave_requests (
  id         INT PRIMARY KEY AUTO_INCREMENT,
  emp_id     INT NOT NULL,
  leave_type VARCHAR(50),
  start_date DATE,
  end_date   DATE,
  days       INT,
  status     VARCHAR(20),
  reason     VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS payroll (
  id          INT PRIMARY KEY AUTO_INCREMENT,
  emp_id      INT NOT NULL,
  month       VARCHAR(7),
  base_salary DECIMAL(12,2),
  deduction   DECIMAL(12,2),
  bonus       DECIMAL(12,2),
  net_salary  DECIMAL(12,2)
);

-- ── Seed data ─────────────────────────────────────────────────
INSERT INTO employees VALUES
  (1,  'Nguyen Van A', 'Engineering', 25000000),
  (2,  'Tran Thi B',   'Marketing',   20000000),
  (3,  'Le Van C',     'Engineering', 28000000),
  (4,  'Pham Thi D',   'HR',          18000000),
  (5,  'Hoang Van E',  'Engineering', 30000000),
  (6,  'Nguyen Van F', 'HR',          22000000),
  (7,  'Tran Van G',   'Engineering', 27000000),
  (8,  'Le Thi H',     'Marketing',   21000000),
  (9,  'Pham Van I',   'Finance',     26000000),
  (10, 'Hoang Thi K',  'Engineering', 29000000)
ON DUPLICATE KEY UPDATE name=VALUES(name), department=VALUES(department), salary=VALUES(salary);

TRUNCATE TABLE attendance;
INSERT INTO attendance (emp_id, check_in, check_out, status) VALUES
  (1,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (2,  '2026-04-01 09:10:00', '2026-04-01 18:00:00', 'LATE'),
  (3,  '2026-04-01 08:05:00', '2026-04-01 17:30:00', 'ON_TIME'),
  (4,  '2026-04-01 08:20:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (5,  '2026-04-01 09:30:00', '2026-04-01 18:10:00', 'LATE'),
  (6,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (7,  '2026-04-01 08:15:00', '2026-04-01 16:30:00', 'EARLY_LEAVE'),
  (8,  '2026-04-01 09:00:00', '2026-04-01 18:00:00', 'LATE'),
  (9,  '2026-04-01 08:00:00', '2026-04-01 17:00:00', 'ON_TIME'),
  (10, '2026-04-01 08:40:00', '2026-04-01 17:30:00', 'ON_TIME'),

  (1,  '2026-04-02 08:10:00', '2026-04-02 17:10:00', 'ON_TIME'),
  (2,  '2026-04-02 09:20:00', '2026-04-02 18:00:00', 'LATE'),
  (3,  '2026-04-02 08:00:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (4,  '2026-04-02 08:25:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (5,  '2026-04-02 09:10:00', '2026-04-02 18:00:00', 'LATE'),
  (6,  '2026-04-02 08:05:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (7,  '2026-04-02 08:30:00', '2026-04-02 16:45:00', 'EARLY_LEAVE'),
  (8,  '2026-04-02 09:15:00', '2026-04-02 18:20:00', 'LATE'),
  (9,  '2026-04-02 08:00:00', '2026-04-02 17:00:00', 'ON_TIME'),
  (10, '2026-04-02 08:50:00', '2026-04-02 17:40:00', 'ON_TIME'),

  (1,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (2,  '2026-04-03 09:30:00', '2026-04-03 18:10:00', 'LATE'),
  (3,  '2026-04-03 08:10:00', '2026-04-03 17:20:00', 'ON_TIME'),
  (4,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (5,  '2026-04-03 09:40:00', '2026-04-03 18:30:00', 'LATE'),
  (6,  '2026-04-03 08:00:00', '2026-04-03 17:00:00', 'ON_TIME'),
  (7,  '2026-04-03 08:20:00', '2026-04-03 16:40:00', 'EARLY_LEAVE'),
  (8,  '2026-04-03 09:25:00', '2026-04-03 18:15:00', 'LATE'),
  (9,  '2026-04-03 08:05:00', '2026-04-03 17:05:00', 'ON_TIME'),
  (10, '2026-04-03 08:45:00', '2026-04-03 17:30:00', 'ON_TIME'),

  (1,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (2,  '2026-04-04 09:15:00', '2026-04-04 18:00:00', 'LATE'),
  (3,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (4,  '2026-04-04 08:30:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (5,  '2026-04-04 09:20:00', '2026-04-04 18:10:00', 'LATE'),
  (6,  '2026-04-04 08:05:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (7,  '2026-04-04 08:25:00', '2026-04-04 16:50:00', 'EARLY_LEAVE'),
  (8,  '2026-04-04 09:35:00', '2026-04-04 18:30:00', 'LATE'),
  (9,  '2026-04-04 08:00:00', '2026-04-04 17:00:00', 'ON_TIME'),
  (10, '2026-04-04 08:55:00', '2026-04-04 17:45:00', 'ON_TIME'),

  (1,  '2026-04-05 08:10:00', '2026-04-05 17:10:00', 'ON_TIME'),
  (2,  '2026-04-05 09:25:00', '2026-04-05 18:10:00', 'LATE'),
  (3,  '2026-04-05 08:05:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (4,  '2026-04-05 08:15:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (5,  '2026-04-05 09:30:00', '2026-04-05 18:20:00', 'LATE'),
  (6,  '2026-04-05 08:00:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (7,  '2026-04-05 08:20:00', '2026-04-05 16:40:00', 'EARLY_LEAVE'),
  (8,  '2026-04-05 09:40:00', '2026-04-05 18:30:00', 'LATE'),
  (9,  '2026-04-05 08:00:00', '2026-04-05 17:00:00', 'ON_TIME'),
  (10, '2026-04-05 08:50:00', '2026-04-05 17:30:00', 'ON_TIME');

TRUNCATE TABLE leave_requests;
INSERT INTO leave_requests (emp_id, leave_type, start_date, end_date, days, status, reason) VALUES
  (1,  'annual', '2026-04-07', '2026-04-11', 5, 'pending',  'Nghi le gia dinh'),
  (2,  'sick',   '2026-04-03', '2026-04-04', 2, 'approved', 'Cam cum'),
  (3,  'sick',   '2026-04-08', '2026-04-09', 2, 'approved', 'Dau dau'),
  (4,  'annual', '2026-04-14', '2026-04-16', 3, 'approved', 'Du lich'),
  (5,  'sick',   '2026-04-02', '2026-04-02', 1, 'approved', 'Sot'),
  (6,  'sick',   '2026-04-10', '2026-04-10', 1, 'approved', 'Met moi'),
  (7,  'annual', '2026-04-21', '2026-04-22', 2, 'pending',  'Viec ca nhan'),
  (8,  'unpaid', '2026-04-15', '2026-04-15', 1, 'rejected', 'Ly do ca nhan'),
  (9,  'annual', '2026-04-14', '2026-04-16', 3, 'approved', 'Nghi duong'),
  (10, 'unpaid', '2026-04-21', '2026-04-22', 2, 'pending',  'Viec nha');

TRUNCATE TABLE payroll;
INSERT INTO payroll (emp_id, month, base_salary, deduction, bonus, net_salary) VALUES
  (1,  '2026-04', 25000000, 0,      500000, 25500000),
  (2,  '2026-04', 20000000, 250000, 0,      19750000),
  (3,  '2026-04', 28000000, 0,      500000, 28500000),
  (4,  '2026-04', 18000000, 0,      500000, 18500000),
  (5,  '2026-04', 30000000, 250000, 0,      29750000),
  (6,  '2026-04', 22000000, 0,      500000, 22500000),
  (7,  '2026-04', 27000000, 100000, 0,      26900000),
  (8,  '2026-04', 21000000, 250000, 0,      20750000),
  (9,  '2026-04', 26000000, 0,      500000, 26500000),
  (10, '2026-04', 29000000, 0,      500000, 29500000);
