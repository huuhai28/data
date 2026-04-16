-- =============================================================
--  sql/hrm_trino_views.sql — Analytics views HRM
--  Các views này luôn là logic nghiệp vụ riêng, không thể auto-gen
--  Thêm view mới: chỉ append SQL vào file này
-- =============================================================

-- View: attendance_summary
CREATE VIEW minio.db_hrm.attendance_summary AS
SELECT e.emp_id, e.name, e.department,
  a.status, a.work_hours, a.check_in, a.check_out
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL;

-- View: department_stats
CREATE VIEW minio.db_hrm.department_stats AS
SELECT e.department,
  COUNT(DISTINCT e.emp_id)                                     AS employee_count,
  COUNT(a.id)                                                  AS total_sessions,
  ROUND(AVG(a.work_hours), 2)                                  AS avg_work_hours,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END)   AS late_count,
  SUM(CASE WHEN a.status = 'ON_TIME'     THEN 1 ELSE 0 END)   AS on_time_count,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END)   AS early_leave_count
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
GROUP BY e.department
ORDER BY late_count DESC;

-- View: late_ranking
CREATE VIEW minio.db_hrm.late_ranking AS
SELECT e.emp_id, e.name, e.department,
  COUNT(*)                                                     AS total_days,
  SUM(CASE WHEN a.status = 'LATE'        THEN 1 ELSE 0 END)   AS late_days,
  SUM(CASE WHEN a.status = 'EARLY_LEAVE' THEN 1 ELSE 0 END)   AS early_leave_days,
  ROUND(AVG(a.work_hours), 2)                                  AS avg_work_hours,
  CASE
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 4 THEN 'CRITICAL'
    WHEN SUM(CASE WHEN a.status = 'LATE' THEN 1 ELSE 0 END) >= 2 THEN 'WARNING'
    ELSE 'GOOD'
  END AS discipline_tier
FROM minio.db_hrm.attendance_raw a
JOIN minio.db_hrm.employees e ON a.emp_id = e.emp_id
WHERE a.emp_id IS NOT NULL
GROUP BY e.emp_id, e.name, e.department
ORDER BY late_days DESC;

-- View: leave_analysis
CREATE VIEW minio.db_hrm.leave_analysis AS
SELECT e.emp_id, e.name, e.department,
  COUNT(l.id)                                                       AS total_requests,
  SUM(CASE WHEN l.status = 'approved' THEN l.days ELSE 0 END)      AS approved_days,
  SUM(CASE WHEN l.leave_type = 'sick'   THEN 1 ELSE 0 END)         AS sick_requests,
  SUM(CASE WHEN l.leave_type = 'annual' THEN 1 ELSE 0 END)         AS annual_requests,
  SUM(CASE WHEN l.status = 'pending'  THEN 1 ELSE 0 END)           AS pending_requests
FROM minio.db_hrm.leave_requests_raw l
JOIN minio.db_hrm.employees e ON l.emp_id = e.emp_id
GROUP BY e.emp_id, e.name, e.department
ORDER BY approved_days DESC;

-- View: payroll_summary
CREATE VIEW minio.db_hrm.payroll_summary AS
SELECT e.department,
  ROUND(AVG(p.base_salary), 0)  AS avg_base_salary,
  ROUND(AVG(p.deduction), 0)    AS avg_deduction,
  ROUND(AVG(p.bonus), 0)        AS avg_bonus,
  ROUND(AVG(p.net_salary), 0)   AS avg_net_salary,
  ROUND(SUM(p.net_salary), 0)   AS total_payroll
FROM minio.db_hrm.payroll_raw p
JOIN minio.db_hrm.employees e ON p.emp_id = e.emp_id
GROUP BY e.department
ORDER BY total_payroll DESC;
