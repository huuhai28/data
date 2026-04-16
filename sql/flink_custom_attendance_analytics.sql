-- =============================================================
--  sql/flink_custom_attendance_analytics.sql
--  Custom transform: attendance (Kafka) → attendance_analytics (Iceberg)
--  Tính work_hours và chuẩn hóa status khi có NULL
--
--  Note: file này được inject vào Flink SQL pipeline sau khi
--        các Kafka source tables đã được tạo.
-- =============================================================

-- INSERT: attendance (custom transform với work_hours)
INSERT INTO __CATALOG__.db_hrm.attendance_analytics
SELECT
  id,
  emp_id,
  check_in,
  check_out,
  CASE
    WHEN check_in IS NOT NULL AND check_out IS NOT NULL
    THEN CAST((check_out - check_in) / 3600000.0 AS DOUBLE)
    ELSE NULL
  END AS work_hours,
  CASE
    WHEN check_in IS NULL AND check_out IS NULL THEN 'MISSING_DATA'
    WHEN check_in IS NULL                       THEN 'NOT_CHECKED_IN'
    WHEN check_out IS NULL                      THEN 'NOT_CHECKED_OUT'
    ELSE status
  END AS status
FROM attendance_kafka
WHERE emp_id IS NOT NULL;
