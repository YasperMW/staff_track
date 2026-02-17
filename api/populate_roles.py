#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal, engine
from models.db_models import Base, Role
from datetime import datetime

def create_roles():
    """Create the 6 specified roles in the database"""
    print("Creating roles in database...")
    
    # Create session
    db = SessionLocal()
    
    try:
        # Define the 6 roles
        roles_to_create = [
            {
                'name': 'Head of Department',
                'description': 'Head of a department responsible for departmental operations'
            },
            {
                'name': 'Human Resource Manager',
                'description': 'Human Resources personnel responsible for employee management'
            },
            {
                'name': 'Accountant',
                'description': 'Financial personnel responsible for accounting operations'
            },
            {
                'name': 'Principal Hospital Administrator',
                'description': 'Top-level hospital administrator with full system access'
            },
            {
                'name': 'System Administrator',
                'description': 'Technical administrator with system-level permissions'
            },
            {
                'name': 'Staff',
                'description': 'Regular hospital staff member'
            }
        ]
        
        # Check existing roles
        existing_roles = db.query(Role).all()
        existing_role_names = {role.name for role in existing_roles}
        
        print(f"Found {len(existing_roles)} existing roles:")
        for role in existing_roles:
            print(f"  - {role.name}")
        
        # Create new roles that don't exist
        created_count = 0
        for role_data in roles_to_create:
            role_name = role_data['name']
            
            if role_name not in existing_role_names:
                new_role = Role(
                    name=role_name,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                db.add(new_role)
                created_count += 1
                print(f"✓ Created role: {role_name}")
            else:
                print(f"○ Role already exists: {role_name}")
        
        # Commit changes
        db.commit()
        
        print(f"\n✅ Successfully created {created_count} new roles")
        
        # Show all roles after creation
        all_roles = db.query(Role).all()
        print(f"\nTotal roles in database: {len(all_roles)}")
        for role in all_roles:
            print(f"  - {role.name}")
            
    except Exception as e:
        print(f"❌ Error creating roles: {e}")
        db.rollback()
    finally:
        db.close()

def check_roles():
    """Check current roles in the database"""
    print("Checking current roles in database...")
    
    db = SessionLocal()
    try:
        roles = db.query(Role).all()
        print(f"Found {len(roles)} roles:")
        for role in roles:
            print(f"  - ID: {role.role_id}, Name: {role.name}, Created: {role.created_at}")
    except Exception as e:
        print(f"❌ Error checking roles: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Manage roles in database')
    parser.add_argument('--check', action='store_true', help='Check existing roles')
    parser.add_argument('--create', action='store_true', help='Create the 6 specified roles')
    
    args = parser.parse_args()
    
    if args.check:
        check_roles()
    elif args.create:
        create_roles()
    else:
        print("Usage: python populate_roles.py --check | --create")
        print("  --check  : Check existing roles in database")
        print("  --create : Create the 6 specified roles")
