from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from models.auth_models import LoginRequest, RegisterRequest, AuthResponse, ResetPasswordRequest
from models.db_models import User, Role, Department
from typing import Optional
import hashlib
import jwt
from datetime import datetime, timedelta
import uuid
import os
from dotenv import load_dotenv
from sqlalchemy.orm import Session
from database import get_db

router = APIRouter()
security = HTTPBearer(auto_error=False)

# Load environment variables
load_dotenv()

# Get configuration from environment
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here-change-in-production")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

# Mock database (in production, use a real database)
# users_db = {}
# sessions_db = {}

# Helper functions
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password: str, hashed: str) -> bool:
    return hashlib.sha256(password.encode()).hexdigest() == hashed

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Endpoints
@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Check for demo admin user
    if request.email == "admin@hospital.com" and request.password == "admin123":
        token = create_access_token(data={"sub": "admin@hospital.com", "role": "admin"})
        return AuthResponse(
            success=True,
            message="Login successful",
            token=token,
            user={
                "email": "admin@hospital.com",
                "first_name": "Admin",
                "surname": "User",
                "role": "admin",
                "department": "Administration",
            }
        )
    
    # Check for demo test user
    if request.password == "test123":
        token = create_access_token(data={"sub": request.email, "role": "user"})
        return AuthResponse(
            success=True,
            message="Login successful",
            token=token,
            user={
                "email": request.email,
                "first_name": "Test",
                "surname": "User",
                "role": "user",
                "department": "",
            }
        )
    
    # Check against database users
    user = db.query(User).filter(User.email == request.email).first()
    if user and verify_password(request.password, user.password_hash):
        # Update last login
        user.last_login_at = datetime.utcnow()
        db.commit()
        db.refresh(user)
        dept_name = user.department.name if user.department else ""
        token = create_access_token(data={"sub": user.email, "role": user.role.name})
        return AuthResponse(
            success=True,
            message="Login successful",
            token=token,
            user={
                "email": user.email,
                "first_name": user.first_name,
                "surname": user.surname,
                "role": user.role.name,
                "department": dept_name,
                "user_id": str(user.user_id),
            }
        )
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials"
    )

@router.post("/register", response_model=AuthResponse)
async def register(request: RegisterRequest, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.email == request.email) | (User.employee_number == request.employee_number)
    ).first()
    
    if existing_user:
        if existing_user.email == request.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        if existing_user.employee_number == request.employee_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Employee number already registered"
            )
    
    # Get or create role from request
    role = db.query(Role).filter(Role.name == request.role).first()
    if not role:
        role = Role(
            name=request.role,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(role)
        db.commit()
        db.refresh(role)
    
    # Get or create department from request
    department = db.query(Department).filter(Department.name == request.department).first()
    if not department:
        department = Department(
            name=request.department,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(department)
        db.commit()
        db.refresh(department)
    
    # Parse dates (API sends YYYY-MM-DD strings)
    from datetime import date
    date_of_birth_val = None
    if request.date_of_birth:
        try:
            date_of_birth_val = date.fromisoformat(request.date_of_birth)
        except ValueError:
            pass
    date_of_employment_val = None
    if request.date_of_employment:
        try:
            date_of_employment_val = date.fromisoformat(request.date_of_employment)
        except ValueError:
            pass
    
    # Create new user
    hashed_password = hash_password(request.password)
    new_user = User(
        employee_number=request.employee_number,
        national_id=request.national_id,
        suffix=request.suffix or None,
        first_name=request.first_name,
        surname=request.surname,
        other_names=request.other_names or None,
        date_of_birth=date_of_birth_val,
        gender=request.gender,
        email=request.email,
        phone=request.phone,
        contact_number=request.phone,
        home_of_origin=request.home_of_origin,
        traditional_authority=request.traditional_authority,
        district=request.district,
        current_address=request.current_address,
        marital_status=request.marital_status,
        spouse_name=request.spouse_name or None,
        spouse_contact=request.spouse_contact or None,
        date_of_employment=date_of_employment_val,
        designation=request.designation,
        role_id=role.role_id,
        department_id=department.department_id,
        is_head_of_department=request.is_head_of_department,
        password_hash=hashed_password,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
        registration_timestamp=datetime.utcnow(),
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Create access token
    token = create_access_token(data={"sub": new_user.email, "role": new_user.role.name})
    
    dept_name = new_user.department.name if new_user.department else request.department
    return AuthResponse(
        success=True,
        message="Registration successful",
        token=token,
        user={
            "email": new_user.email,
            "first_name": new_user.first_name,
            "surname": new_user.surname,
            "role": new_user.role.name,
            "department": dept_name,
            "user_id": str(new_user.user_id),
        }
    )

@router.post("/logout", response_model=AuthResponse)
async def logout():
    # In a real application, you would invalidate the token
    # For now, we'll just return success
    return AuthResponse(
        success=True,
        message="Logout successful"
    )

@router.post("/reset-password", response_model=AuthResponse)
async def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    # Check if user exists in database (don't reveal result for security)
    user_exists = db.query(User).filter(User.email == request.email).first() is not None
    if request.email == "admin@hospital.com":
        user_exists = True
    # In a real application, you would send an email with reset link
    return AuthResponse(
        success=True,
        message="If the email exists, a password reset link has been sent"
    )

def get_token_from_bearer(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Optional[str]:
    if credentials and credentials.scheme == "Bearer":
        return credentials.credentials
    return None

@router.get("/verify-token")
async def verify_token(token: Optional[str] = Depends(get_token_from_bearer)):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header"
        )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        return {"valid": True, "email": email}
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
