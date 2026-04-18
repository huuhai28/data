import re
import os

# Đường dẫn file nguồn và đích
SQL_FILE = "init/sql/admin_schema.sql"
OUTPUT_FLINK = "flink_admin_pipeline.sql"
OUTPUT_TRINO = "trino_admin_views.sql"

def map_type(mysql_type):
    mysql_type = mysql_type.upper()
    if "BIGINT" in mysql_type: return "BIGINT"
    if "INT" in mysql_type: return "INT"
    if "TINYINT" in mysql_type: return "INT"
    if "VARCHAR" in mysql_type: return "STRING"
    if "TEXT" in mysql_type: return "STRING"
    if "LONGTEXT" in mysql_type: return "STRING"
    if "DATETIME" in mysql_type: return "TIMESTAMP(3)"
    if "TIMESTAMP" in mysql_type: return "TIMESTAMP(3)"
    if "DECIMAL" in mysql_type: return "DOUBLE"
    if "NUMERIC" in mysql_type: return "DOUBLE"
    return "STRING"

def parse_sql():
    if not os.path.exists(SQL_FILE):
        print(f"❌ Không tìm thấy file {SQL_FILE}")
        return

    with open(SQL_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Tìm tất cả các khối CREATE TABLE
    tables = re.findall(r"CREATE TABLE IF NOT EXISTS (\w+) \((.*?)\);", content, re.DOTALL | re.IGNORECASE)
    
    flink_sql = []
    trino_sql = []
    table_names = []

    # Header cho Flink SQL
    flink_sql.append("-- ============================================")
    flink_sql.append("--  FLINK SQL GENERATED FOR 85 TABLES")
    flink_sql.append("-- ============================================")
    flink_sql.append("USE CATALOG catalog_admin;")
    flink_sql.append("CREATE DATABASE IF NOT EXISTS db_admin;")
    flink_sql.append("")

    for table_name, body in tables:
        table_names.append(table_name)
        lines = [l.strip() for l in body.split("\n") if l.strip()]
        
        columns = []
        pk = ""
        
        for line in lines:
            line = line.rstrip(",")
            # Tìm Primary Key
            if "PRIMARY KEY" in line.upper():
                pk_match = re.search(r"PRIMARY KEY \((.*?)\)", line, re.IGNORECASE)
                if pk_match:
                    pk = pk_match.group(1).replace("`", "")
                continue
            
            # Tìm Unique Key / Index (bỏ qua)
            if "KEY " in line.upper() or "UNIQUE " in line.upper():
                continue

            # Parse cột: name type ...
            parts = line.split()
            if len(parts) >= 2:
                col_name = parts[0].replace("`", "")
                col_type = map_type(parts[1])
                columns.append(f"  {col_name} {col_type}")

        # TẠO FLINK ICEBERG TABLE
        flink_sql.append(f"-- Table: {table_name}")
        flink_sql.append(f"CREATE TABLE IF NOT EXISTS db_admin.{table_name} (")
        flink_sql.append(",\n".join(columns))
        if pk:
            flink_sql.append(f"  , PRIMARY KEY ({pk}) NOT ENFORCED")
        flink_sql.append(") WITH ('write.upsert.enabled'='true','format-version'='2');")
        flink_sql.append("")

        # TẠO KAFKA SOURCE (Dùng default_catalog)
        flink_sql.append(f"CREATE TABLE IF NOT EXISTS default_catalog.default_database.{table_name}_k (")
        flink_sql.append(",\n".join(columns))
        if pk:
            flink_sql.append(f"  , PRIMARY KEY ({pk}) NOT ENFORCED")
        flink_sql.append(f") WITH (")
        flink_sql.append(f"  'connector' = 'kafka',")
        flink_sql.append(f"  'topic' = 'admin_db.admin_db.{table_name}',") # Debezium topic format
        flink_sql.append(f"  'properties.bootstrap.servers' = 'kafka:9092',")
        flink_sql.append(f"  'format' = 'debezium-json'")
        flink_sql.append(f");")
        flink_sql.append("")
        
        # LỆNH INSERT
        flink_sql.append(f"INSERT INTO catalog_admin.db_admin.{table_name} SELECT * FROM default_catalog.default_database.{table_name}_k;")
        flink_sql.append("")
        flink_sql.append("-- " + "-"*40)

    # Ghi file kết quả
    with open(OUTPUT_FLINK, "w", encoding="utf-8") as f:
        f.write("\n".join(flink_sql))
    
    print(f"✅ Đã tạo xong Flink SQL cho {len(table_names)} bảng!")
    print(f"👉 Danh sách bảng include cho Debezium:")
    print(f"admin_db." + ",admin_db.".join(table_names))

if __name__ == "__main__":
    generate()
