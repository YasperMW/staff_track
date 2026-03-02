# Database Migration for Holiday Categories

## Issue
The holidays management system requires a database schema update to support institutional and public holidays categories, and the table should be renamed from `public_holidays` to `holidays` for clarity.

## Solution
Run the migration script `add_holiday_categories.sql` to update your database schema.

## How to Run the Migration

### Option 1: Using psql command line
```bash
psql -h localhost -U postgres -d staff_track -f add_holiday_categories.sql
```

### Option 2: Using Python with psycopg2
```python
import psycopg2

# Connect to your database
conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="staff_track",
    user="postgres",
    password="your_password"
)

cursor = conn.cursor()

# Read and execute the migration script
with open('add_holiday_categories.sql', 'r') as file:
    migration_sql = file.read()

cursor.execute(migration_sql)
conn.commit()

# Verify the changes
cursor.execute("""
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'holidays' 
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
2. Open the Query Tool for your `staff_track` database
3. Copy and paste the contents of `add_holiday_categories.sql`
4. Execute the script

## What the Migration Does

1. **Renames the table** from `public_holidays` to `holidays` for clarity

2. **Adds new columns:**
   - `category` (VARCHAR(20), DEFAULT 'institutional')
   - `source` (VARCHAR(100), nullable)
   - `country_code` (VARCHAR(2), DEFAULT 'MW')

3. **Makes existing columns nullable:**
   - `created_by` (to allow public holidays from API without a creator)

4. **Updates existing records:**
   - Sets `category = 'institutional'` and `source = 'manual'` for existing holidays

5. **Adds indexes for performance:**
   - Index on `category` column
   - Index on `source` column

6. **Adds comments** to document the new columns

## After Migration
Once the migration is complete, the holidays management system will work properly with both institutional and public holidays using the renamed `holidays` table.

## Verification
To verify the migration worked correctly, you can run:
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'holidays' 
ORDER BY ordinal_position;
```

You should see the new columns: `category`, `source`, and `country_code`, and the table should now be named `holidays`.
