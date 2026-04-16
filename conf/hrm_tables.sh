#!/bin/bash
# =============================================================
#  conf/hrm_tables.sh — Khai báo bảng HRM
#
#  ✅ Thêm bảng mới chỉ cần:
#    1. Thêm 1 dòng vào TABLES_REGISTRY
#    2. Khai báo KAFKA_COLS_*, ICEBERG_COLS_*, TRINO_COLS_*
#    3. passthrough: thêm SELECT_COLS_*
#    4. custom transform: thêm sql/flink_custom_<iceberg_table>.sql
# =============================================================

# Format: "mysql_table|iceberg_table|pk|kafka_group|transform"
# transform: passthrough | custom
TABLES_REGISTRY=(
  "employees|employees|emp_id|flink-hrm-emp|passthrough"
  "leave_requests|leave_requests|id|flink-hrm-lrq|passthrough"
  "payroll|payroll|id|flink-hrm-pay|passthrough"
  "attendance|attendance_analytics|id|flink-hrm-att|custom"
)

# ── Kafka source columns (Flink types) ────────────────────────
# Key: KAFKA_COLS_<mysql_table>
KAFKA_COLS_employees="emp_id INT, name STRING, department STRING, salary DOUBLE"
KAFKA_COLS_leave_requests="id INT, emp_id INT, leave_type STRING, start_date INT, end_date INT, days INT, status STRING, reason STRING"
KAFKA_COLS_payroll="id INT, emp_id INT, \`month\` STRING, base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE"
KAFKA_COLS_attendance="id INT, emp_id INT, check_in BIGINT, check_out BIGINT, status STRING"

# ── Iceberg sink columns (Flink types) ────────────────────────
# Key: ICEBERG_COLS_<iceberg_table>  (có thể khác kafka nếu là custom)
ICEBERG_COLS_employees="emp_id INT, name STRING, department STRING, salary DOUBLE"
ICEBERG_COLS_leave_requests="id INT, emp_id INT, leave_type STRING, start_date INT, end_date INT, days INT, status STRING, reason STRING"
ICEBERG_COLS_payroll="id INT, emp_id INT, \`month\` STRING, base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE"
ICEBERG_COLS_attendance_analytics="id INT, emp_id INT, check_in BIGINT, check_out BIGINT, work_hours DOUBLE, status STRING"

# ── SELECT columns cho passthrough INSERT ─────────────────────
# Key: SELECT_COLS_<mysql_table>
SELECT_COLS_employees="emp_id, name, department, salary"
SELECT_COLS_leave_requests="id, emp_id, leave_type, start_date, end_date, days, status, reason"
SELECT_COLS_payroll="id, emp_id, \`month\`, base_salary, deduction, bonus, net_salary"

# ── Trino external table columns ──────────────────────────────
# Key: TRINO_COLS_<iceberg_table>
TRINO_COLS_employees="emp_id INTEGER, name VARCHAR, department VARCHAR, salary DOUBLE"
TRINO_COLS_leave_requests="id INTEGER, emp_id INTEGER, leave_type VARCHAR, start_date INTEGER, end_date INTEGER, days INTEGER, status VARCHAR, reason VARCHAR"
TRINO_COLS_payroll="id INTEGER, emp_id INTEGER, month VARCHAR, base_salary DOUBLE, deduction DOUBLE, bonus DOUBLE, net_salary DOUBLE"
TRINO_COLS_attendance_analytics="id INTEGER, emp_id INTEGER, check_in BIGINT, check_out BIGINT, work_hours DOUBLE, status VARCHAR"

# ── Tên Trino table (minio schema) ───────────────────────────
# Key: TRINO_TABLE_<iceberg_table>
TRINO_TABLE_employees="employees"
TRINO_TABLE_leave_requests="leave_requests_raw"
TRINO_TABLE_payroll="payroll_raw"
TRINO_TABLE_attendance_analytics="attendance_raw"

# ── Danh sách cleanup ─────────────────────────────────────────
ICEBERG_CLEANUP=("employees" "leave_requests" "payroll" "attendance_analytics")
TRINO_VIEWS_CLEANUP=("attendance_summary" "department_stats" "late_ranking" "leave_analysis" "payroll_summary")
TRINO_TABLES_CLEANUP=("employees" "attendance_raw" "leave_requests_raw" "payroll_raw")
