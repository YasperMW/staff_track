from sqlalchemy import Column, String, Boolean, DateTime, Text, Numeric, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from database import Base
import uuid

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_number = Column(String(50), nullable=False, unique=True)
    national_id = Column(String(50), unique=True)
    first_name = Column(String(100), nullable=False)
    surname = Column(String(100), nullable=False)
    other_names = Column(String(150))
    suffix = Column(String(20))
    date_of_birth = Column(Date)
    gender = Column(String(10))
    home_of_origin = Column(String(150))
    traditional_authority = Column(String(100))
    district = Column(String(100))
    current_address = Column(Text)
    contact_number = Column(String(30), unique=True)
    email = Column(String(255), unique=True)
    marital_status = Column(String(20))
    spouse_name = Column(String(150))
    spouse_contact = Column(String(30))
    date_of_employment = Column(Date)
    designation_id = Column(UUID(as_uuid=True), ForeignKey("designations.designation_id"))
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.department_id"))
    is_head_of_department = Column(Boolean, default=False)
    phone = Column(String(30), unique=True)
    password_hash = Column(Text, nullable=False)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.role_id"), nullable=False)
    status = Column(String(30), nullable=False, default="pending")
    profile_photo_url = Column(Text)
    blacklisted_at = Column(DateTime(timezone=True))
    blacklisted_reason = Column(Text)
    registration_timestamp = Column(DateTime(timezone=True))
    selfie_verified = Column(Boolean, default=False)
    last_login_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True))
    deleted_by = Column(UUID(as_uuid=True), ForeignKey("users.user_id"))
    
    # Relationships
    role = relationship("Role", back_populates="users", foreign_keys=[role_id])
    department = relationship("Department", back_populates="users", foreign_keys=[department_id])
    designation = relationship("Designation", back_populates="users", foreign_keys=[designation_id])

class Designation(Base):
    __tablename__ = "designations"
    
    designation_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(150), nullable=False)
    description = Column(Text)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.department_id"))
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True))
    deleted_by = Column(UUID(as_uuid=True), ForeignKey("users.user_id"))
    
    # Relationships
    department = relationship("Department", back_populates="designations", foreign_keys=[department_id])
    users = relationship("User", back_populates="designation", foreign_keys="User.designation_id")

class Role(Base):
    __tablename__ = "roles"
    
    role_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, unique=True)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True))
    deleted_by = Column(UUID(as_uuid=True), ForeignKey("users.user_id"))
    
    # Relationships
    users = relationship("User", back_populates="role", foreign_keys="User.role_id")

class Department(Base):
    __tablename__ = "departments"
    
    department_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(150), nullable=False, unique=True)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True))
    deleted_by = Column(UUID(as_uuid=True), ForeignKey("users.user_id"))
    
    # Relationships
    users = relationship("User", back_populates="department", foreign_keys="User.department_id")
    designations = relationship("Designation", back_populates="department", foreign_keys="Designation.department_id")
