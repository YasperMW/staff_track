#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from endpoints.auth_endpoints import hash_password, verify_password
from models.db_models import User
from database import SessionLocal
import hashlib

def fix_password_hash(user_email, new_password):
    """Fix password hash for a specific user"""
    print(f"Fixing password hash for user: {user_email}")
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == user_email).first()
        if not user:
            print(f"User {user_email} not found")
            return False
        
        print(f"Current hash length: {len(user.password_hash)}")
        print(f"Current hash starts with: {user.password_hash[:10]}...")
        
        # Create new bcrypt hash
        new_hash = hash_password(new_password)
        print(f"New hash length: {len(new_hash)}")
        print(f"New hash starts with: {new_hash[:10]}...")
        
        # Update user password
        user.password_hash = new_hash
        db.commit()
        
        print(f"✓ Password hash updated for {user_email}")
        
        # Test the new hash
        if verify_password(new_password, new_hash):
            print("✓ New password hash verified successfully")
            return True
        else:
            print("✗ New password hash verification failed")
            return False
            
    except Exception as e:
        print(f"Error fixing password hash: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def check_all_users():
    """Check all users and identify password hash issues"""
    print("Checking all users...")
    
    db = SessionLocal()
    try:
        users = db.query(User).all()
        print(f"Found {len(users)} users:")
        
        for user in users:
            hash_length = len(user.password_hash) if user.password_hash else 0
            is_bcrypt = user.password_hash.startswith('$2b$') if user.password_hash else False
            
            print(f"  - {user.email}:")
            print(f"    Hash length: {hash_length}")
            print(f"    Is bcrypt: {is_bcrypt}")
            print(f"    Status: {user.status}")
            
            if not is_bcrypt and hash_length > 0:
                print(f"    ⚠️  This user needs password hash fixed!")
            print()
            
    except Exception as e:
        print(f"Error checking users: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("Password Hash Fix Tool")
    print("=" * 30)
    
    # Check all users first
    check_all_users()
    
    # Fix specific user if needed
    user_email = input("Enter user email to fix (or press Enter to skip): ").strip()
    if user_email:
        new_password = input("Enter new password for this user: ").strip()
        if fix_password_hash(user_email, new_password):
            print("✓ Password fix completed successfully")
        else:
            print("✗ Password fix failed")
