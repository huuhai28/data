import re
import os
import sys

def map_type(mysql_type):
    t = mysql_type.upper()
    if "BIGINT" in t: return "BIGINT"
    if "INT" in t: return "INT"
    if "VARCHAR" in t: return "STRING"
    if "TEXT" in t: return "STRING"
    if "DATETIME" in t: return "TIMESTAMP(3)"
    if "DECIMAL" in t: return "DOUBLE"
    return "STRING"

def generate_pipeline(project_name, sql_file, catalog, namespace, topic_prefix, credential):
    if not os.path.exists(sql_file):
        print(f"❌ Không tìm thấy file SQL: {sql_file}")
        return

    with open(sql_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Tìm tất cả lệnh CREATE TABLE
    tables = re.findall(r"CREATE TABLE IF NOT EXISTS (\w+) \((.*?)\);", content, re.DOTALL | re.IGNORECASE)
    
    output_dir = f"generated/{project_name}"
    os.makedirs(output_dir, exist_ok=True)
    
    flink_sql_path = f"{output_dir}/pipeline.sql"
    tables_list_path = f"{output_dir}/tables.list"
    
    table_names = [t[0] for t in tables]
    with open(tables_list_path, "w") as f:
        f.write("\n".join(table_names))

    with open(flink_sql_path, "w", encoding="utf-8") as f:
        f.write(f"-- GENERATED PIPELINE FOR PROJECT: {project_name}\n")
        f.write("SET 'execution.checkpointing.interval' = '60s';\n")
        f.write("SET 'table.exec.sink.upsert-materialize' = 'AUTO';\n\n")
        f.write(f"CREATE CATALOG {catalog} WITH (\n")
        f.write(f"  'type'                 = 'iceberg',\n")
        f.write(f"  'catalog-impl'         = 'org.apache.iceberg.rest.RESTCatalog',\n")
        f.write(f"  'uri'                  = 'http://polaris:8181/api/catalog',\n")
        f.write(f"  'credential'           = '{credential}',\n")
        f.write(f"  'warehouse'            = '{catalog}',\n")
        f.write(f"  'scope'                = 'PRINCIPAL_ROLE:ALL',\n")
        f.write(f"  'io-impl'              = 'org.apache.iceberg.aws.s3.S3FileIO',\n")
        f.write(f"  's3.endpoint'          = 'http://minio:9000',\n")
        f.write(f"  's3.access-key-id'     = 'admin',\n")
        f.write(f"  's3.secret-access-key' = 'password'\n);\n")
        f.write(f"USE CATALOG {catalog};\n")
        f.write(f"CREATE DATABASE IF NOT EXISTS {namespace};\n\n")

        for table_name, body in tables:
            cols = []
            pk = "id" # Default PK
            
            # Kỹ thuật tách cột thông minh: Chỉ tách dấu phẩy KHÔNG nằm trong ngoặc đơn
            # Ví dụ: DECIMAL(10,2) sẽ không bị chặt đôi
            raw_lines = re.split(r",\s*(?![^()]*\))", body)

            for line in raw_lines:
                line = line.strip()
                if not line or line.startswith("--") or line.startswith("/*"):
                    continue
                    
                line_upper = line.upper()
                
                # Nếu là dòng PRIMARY KEY riêng biệt (ở cuối bảng)
                if "PRIMARY KEY" in line_upper and "(" in line:
                    pk_match = re.search(r"PRIMARY KEY\s*\((.*?)\)", line, re.I)
                    if pk_match: pk = pk_match.group(1).replace("`","").strip()
                    # Nếu dòng này chỉ có PRIMARY KEY (id) thì continue
                    if line_upper.startswith("PRIMARY KEY"): continue
                
                # Nếu là các loại KEY khác (INDEX, UNIQUE...) thì bỏ qua
                if " KEY" in line_upper and "PRIMARY" not in line_upper:
                    continue
                if "CONSTRAINT" in line_upper:
                    continue
                
                parts = line.split()
                if len(parts) < 2: continue
                    
                col_name = parts[0].replace("`","")
                
                # Nếu khóa chính nằm cùng dòng với định nghĩa cột
                if "PRIMARY KEY" in line_upper:
                    pk = col_name

                # Lấy phần kiểu dữ liệu (có thể chứa dấu phẩy như DECIMAL(10,2))
                raw_type = " ".join(parts[1:]) 
                col_type = map_type(raw_type)
                
                cols.append(f"  {col_name} {col_type}")

            # Sink Table
            f.write(f"CREATE TABLE IF NOT EXISTS {namespace}.{table_name} (\n" + ",\n".join(cols) + f"\n  , PRIMARY KEY ({pk}) NOT ENFORCED\n) WITH ('write.upsert.enabled'='true','format-version'='2');\n\n")
            
            # Kafka Source
            f.write(f"CREATE TABLE IF NOT EXISTS default_catalog.default_database.{table_name}_src (\n" + ",\n".join(cols) + f"\n  , PRIMARY KEY ({pk}) NOT ENFORCED\n) WITH (\n")
            f.write(f"  'connector'                    = 'kafka',\n")
            f.write(f"  'topic'                        = '{topic_prefix}.{project_name}.{table_name}',\n")
            f.write(f"  'properties.bootstrap.servers' = 'kafka:9092',\n")
            f.write(f"  'properties.group.id'          = 'flink-{project_name}-{table_name}',\n")
            f.write(f"  'scan.startup.mode'            = 'earliest-offset',\n")
            f.write(f"  'format'                       = 'debezium-json',\n")
            f.write(f"  'debezium-json.schema-include' = 'true'\n);\n\n")
            
            # Insert
            f.write(f"INSERT INTO {catalog}.{namespace}.{table_name}\nSELECT * FROM default_catalog.default_database.{table_name}_src;\n\n")
            f.write("-" * 50 + "\n")

    print(f"✅ Đã tạo xong Pipeline cho {project_name} tại {flink_sql_path}")

if __name__ == "__main__":
    if len(sys.argv) < 7:
        # Chạy mặc định cho hrm
        generate_pipeline("hrm", "sql/hrm_mysql.sql", "catalog_hrm", "db_hrm", "hrm_topic", "admin:password")
    else:
        generate_pipeline(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
