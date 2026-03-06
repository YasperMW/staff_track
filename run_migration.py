#!/usr/bin/env python3
"""
Database migration runner for staff_track project
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def run_migration(sql_file_path):
    """Run a SQL migration file against the database"""
    
    # Database connection parameters from environment
    db_params = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432'),
        'database': os.getenv('DB_NAME', 'st_johns_hr_system'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', 'password')
    }
    
    try:
        # Connect to database
        conn = psycopg2.connect(**db_params)
        cursor = conn.cursor()
        
        print(f"Connected to database: {db_params['database']}")
        
        # Read and execute the migration script
        with open(sql_file_path, 'r') as file:
            migration_sql = file.read()
        
        print(f"Running migration: {sql_file_path}")
        cursor.execute(migration_sql)
        conn.commit()
        
        print("Migration completed successfully!")
        
        # Verify the changes
        cursor.execute("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'audit_logs' 
            ORDER BY ordinal_position
        """)
        columns = cursor.fetchall()
        
        print("\nUpdated audit_logs table structure:")
        for col in columns:
            print(f"{col[0]}: {col[1]} (nullable: {col[2]})")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"Error running migration: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        raise

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python run_migration.py <sql_file_path>")
        sys.exit(1)
    
    sql_file_path = sys.argv[1]
    run_migration(sql_file_path)
