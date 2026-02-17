#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from endpoints.auth_endpoints import hash_password, verify_password
from models.db_models import User
from database import SessionLocal
import bcrypt

def test_password_functions():
    """Test password hashing and verification functions"""
    print("Testing password functions...")
    
    # Test password
    test_password = "test123"
    
    # Hash the password
    hashed = hash_password(test_password)
    print(f"Original password: {test_password}")
    print(f"Hashed password: {hashed}")
    print(f"Hash length: {len(hashed)}")
    
    # Verify the password
    is_valid = verify_password(test_password, hashed)
    print(f"Password verification result: {is_valid}")
    
    # Test with wrong password
    is_valid_wrong = verify_password("wrongpassword", hashed)
    print(f"Wrong password verification result: {is_valid_wrong}")
    
    return is_valid

def check_existing_users():
    """Check existing users in database"""
    print("\nChecking existing users in database...")
    
    db = SessionLocal()
    try:
        users = db.query(User).all()
        print(f"Found {len(users)} users in database:")
        
        for user in users:
            print(f"  - Email: {user.email}")
            print(f"    Employee Number: {user.employee_number}")
            print(f"    Role: {user.role.name if user.role else 'No role'}")
            print(f"    Password hash exists: {'Yes' if user.password_hash else 'No'}")
            print(f"    Password hash length: {len(user.password_hash) if user.password_hash else 0}")
            print(f"    Status: {user.status}")
            print()
            
    except Exception as e:
        print(f"Error checking users: {e}")
    finally:
        db.close()

def test_user_authentication():
    """Test authentication for existing users"""
    print("\nTesting user authentication...")
    
    db = SessionLocal()
    try:
        # Get first user for testing
        user = db.query(User).first()
        if not user:
            print("No users found in database")
            return
        
        print(f"Testing with user: {user.email}")
        
        # Test with a known password (you'll need to provide this)
        test_password = input("Enter password to test for this user: ")
        
        if verify_password(test_password, user.password_hash):
            print("✓ Authentication successful!")
        else:
            print("✗ Authentication failed!")
            
    except Exception as e:
        print(f"Error during authentication test: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("Password Authentication Debug Tool")
    print("=" * 40)
    
    # Test basic password functions
    if test_password_functions():
        print("\n✓ Password functions working correctly")
    else:
        print("\n✗ Password functions have issues")
        sys.exit(1)
    
    # Check existing users
    check_existing_users()
    
    # Test authentication (optional)
    if input("\nDo you want to test authentication with an existing user? (y/n): ").lower() == 'y':
        test_user_authentication()
