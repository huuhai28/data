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
    
    with open(flink_sql_path, "w", encoding="utf-8") as f:
        f.write(f"-- GENERATED PIPELINE FOR PROJECT: {project_name}\n")
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
            for line in body.split(","):
                line = line.strip()
                
                # Bỏ qua dòng trống hoặc dòng rác
                if not line or line.startswith("--") or line.startswith("/*"):
                    continue
                    
                if "KEY" in line.upper(): 
                    if "PRIMARY KEY" in line.upper():
                        pk_match = re.search(r"\((.*?)\)", line)
                        if pk_match: pk = pk_match.group(1).replace("`","").strip()
                    continue
                
                parts = line.split()
                if len(parts) < 2: # Nếu dòng không có ít nhất 2 chữ (Tên + Kiểu) thì bỏ qua
                    continue
                    
                col_name = parts[0].replace("`","")
                col_type = map_type(parts[1])
                cols.append(f"  {col_name} {col_type}")

            # Sink Table
            f.write(f"CREATE TABLE IF NOT EXISTS {namespace}.{table_name} (\n" + ",\n".join(cols) + f"\n  , PRIMARY KEY ({pk}) NOT ENFORCED\n) WITH ('write.upsert.enabled'='true','format-version'='2');\n\n")
            
            # Kafka Source
            f.write(f"CREATE TABLE IF NOT EXISTS default_catalog.default_database.{table_name}_src (\n" + ",\n".join(cols) + f"\n  , PRIMARY KEY ({pk}) NOT ENFORCED\n) WITH ('connector'='kafka','topic'='{topic_prefix}.{project_name}.{table_name}','properties.bootstrap.servers'='kafka:9092','format'='debezium-json');\n\n")
            
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
