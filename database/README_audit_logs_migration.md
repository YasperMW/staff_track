# Database Migration for Audit Logs Entity Column

## Issue
The attendance check-in endpoint is failing because the `audit_logs` table is missing the `entity` column that the SQLAlchemy model expects.

The error shows:
```
psycopg2.errors.UndefinedColumn: column "entity" of relation "audit_logs" does not exist
```

## Root Cause
The database schema has `entity_type` and `entity_id` columns, but the SQLAlchemy model in `staff_track_api/models/db_models.py` expects an `entity` column.

## Solution
Run the migration script `add_audit_logs_entity_column.sql` to add the missing columns.

## How to Run the Migration

### Option 1: Using psql command line
```bash
psql -h localhost -U postgres -d your_database_name -f add_audit_logs_entity_column.sql
```

### Option 2: Using Python with psycopg2
```python
import psycopg2

# Connect to your database with your credentials
conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="your_database_name",
    user="postgres",
    password="your_password"
)

cursor = conn.cursor()

# Read and execute the migration script
with open('add_audit_logs_entity_column.sql', 'r') as file:
    migration_sql = file.read()

cursor.execute(migration_sql)
conn.commit()

# Verify the changes
cursor.execute("""
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'audit_logs' 
    ORDER BY ordinal_position
""")
columns = cursor.fetchall()

print("Updated table structure:")
for col in columns:
    print(f"{col[0]}: {col[1]} (nullable: {col[2]})")

cursor.close()
conn.close()
```

### Option 3: Using pgAdmin or similar GUI tool
1. Open pgAdmin and connect to your database
2. Open the Query Tool for your database
3. Copy and paste the contents of `add_audit_logs_entity_column.sql`
4. Execute the script

## What the Migration Does

1. **Adds the missing `entity` column** (VARCHAR(100)) to match the SQLAlchemy model
2. **Adds the `details` column** (JSONB) for storing audit details
3. **Adds the `timestamp` column** (timestamp with time zone) for audit timestamps
4. **Updates existing records** to populate `entity` from `entity_type` where possible

## After Migration
Once the migration is complete, the attendance check-in endpoint should work properly.

## Verification
To verify the migration worked correctly, you can run:
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'audit_logs' 
ORDER BY ordinal_position;
```

You should see the new columns: `entity`, `details`, and `timestamp`.
