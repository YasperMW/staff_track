from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from datetime import datetime, date, time
from typing import Optional
import pytz

from models.db_models import AttendanceLog, User
from database import get_db
from auth_endpoints import get_current_user

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/check-in")
async def check_in(
    location: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    accuracy: Optional[float] = None,
    device_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Check in the current user"""
    
    # Check if user already checked in today (not checked out)
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    existing_attendance = db.query(AttendanceLog).filter(
        and_(
            AttendanceLog.user_id == current_user.user_id,
            AttendanceLog.check_in_time >= today_start,
            AttendanceLog.check_in_time <= today_end,
            AttendanceLog.check_out_time.is_(None)
        )
    ).first()
    
    if existing_attendance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Already checked in today. Please check out first."
        )
    
    # Create location string if lat/lng provided
    location_str = None
    if latitude is not None and longitude is not None:
        location_str = f"POINT({longitude} {latitude})"
    elif location:
        location_str = location
    
    # Create attendance log
    attendance = AttendanceLog(
        user_id=current_user.user_id,
        check_in_time=datetime.now(),
        location=location_str,
        accuracy=accuracy,
        device_id=device_id,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    
    db.add(attendance)
    db.commit()
    db.refresh(attendance)
    
    return {
        "message": "Check-in successful",
        "attendance_log_id": str(attendance.attendance_log_id),
        "check_in_time": attendance.check_in_time.strftime("%H:%M:%S"),
        "location": location_str
    }

@router.post("/check-out")
async def check_out(
    location: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    accuracy: Optional[float] = None,
    device_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Check out the current user"""
    
    # Find today's active attendance record (checked in but not out)
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    attendance = db.query(AttendanceLog).filter(
        and_(
            AttendanceLog.user_id == current_user.user_id,
            AttendanceLog.check_in_time >= today_start,
            AttendanceLog.check_in_time <= today_end,
            AttendanceLog.check_out_time.is_(None)
        )
    ).first()
    
    if not attendance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No active check-in record found for today"
        )
    
    # Update location if provided
    if latitude is not None and longitude is not None:
        attendance.location = f"POINT({longitude} {latitude})"
    elif location:
        attendance.location = location
    
    if accuracy is not None:
        attendance.accuracy = accuracy
    
    if device_id is not None:
        attendance.device_id = device_id
    
    # Update check out time
    attendance.check_out_time = datetime.now()
    attendance.updated_at = datetime.now()
    
    db.commit()
    db.refresh(attendance)
    
    # Calculate work hours
    work_hours = (attendance.check_out_time - attendance.check_in_time).total_seconds() / 3600.0
    
    return {
        "message": "Check-out successful",
        "attendance_log_id": str(attendance.attendance_log_id),
        "check_out_time": attendance.check_out_time.strftime("%H:%M:%S"),
        "work_hours": round(work_hours, 2),
        "location": attendance.location
    }

@router.get("/today")
async def get_today_attendance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get today's attendance record for the current user"""
    
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    attendance = db.query(AttendanceLog).filter(
        and_(
            AttendanceLog.user_id == current_user.user_id,
            AttendanceLog.check_in_time >= today_start,
            AttendanceLog.check_in_time <= today_end
        )
    ).order_by(desc(AttendanceLog.check_in_time)).first()
    
    if not attendance:
        return {"message": "No attendance record for today"}
    
    # Calculate work hours if checked out
    work_hours = None
    if attendance.check_out_time:
        work_hours = (attendance.check_out_time - attendance.check_in_time).total_seconds() / 3600.0
    
    return {
        "attendance_log_id": str(attendance.attendance_log_id),
        "date": attendance.check_in_time.strftime("%Y-%m-%d"),
        "check_in_time": attendance.check_in_time.strftime("%H:%M:%S"),
        "check_out_time": attendance.check_out_time.strftime("%H:%M:%S") if attendance.check_out_time else None,
        "location": attendance.location,
        "work_hours": round(work_hours, 2) if work_hours else None,
        "device_id": attendance.device_id,
        "accuracy": float(attendance.accuracy) if attendance.accuracy else None
    }

@router.get("/history")
async def get_attendance_history(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get attendance history for the current user"""
    
    query = db.query(AttendanceLog).filter(AttendanceLog.user_id == current_user.user_id)
    
    if start_date:
        try:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
            query = query.filter(AttendanceLog.check_in_time >= start_dt)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid start_date format. Use YYYY-MM-DD"
            )
    
    if end_date:
        try:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59, microsecond=999999)
            query = query.filter(AttendanceLog.check_in_time <= end_dt)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid end_date format. Use YYYY-MM-DD"
            )
    
    attendances = query.order_by(desc(AttendanceLog.check_in_time)).limit(limit).all()
    
    result = []
    for att in attendances:
        work_hours = None
        if att.check_out_time:
            work_hours = (att.check_out_time - att.check_in_time).total_seconds() / 3600.0
        
        result.append({
            "attendance_log_id": str(att.attendance_log_id),
            "date": att.check_in_time.strftime("%Y-%m-%d"),
            "check_in_time": att.check_in_time.strftime("%H:%M:%S"),
            "check_out_time": att.check_out_time.strftime("%H:%M:%S") if att.check_out_time else None,
            "location": att.location,
            "work_hours": round(work_hours, 2) if work_hours else None,
            "device_id": att.device_id,
            "accuracy": float(att.accuracy) if att.accuracy else None
        })
    
    return result

@router.get("/summary")
async def get_attendance_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get attendance summary for the current user"""
    
    query = db.query(AttendanceLog).filter(AttendanceLog.user_id == current_user.user_id)
    
    if start_date:
        try:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
            query = query.filter(AttendanceLog.check_in_time >= start_dt)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid start_date format. Use YYYY-MM-DD"
            )
    
    if end_date:
        try:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59, microsecond=999999)
            query = query.filter(AttendanceLog.check_in_time <= end_dt)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid end_date format. Use YYYY-MM-DD"
            )
    
    # Get all attendance records
    attendances = query.all()
    
    if not attendances:
        return {
            "total_days": 0,
            "present_days": 0,
            "late_days": 0,
            "total_work_hours": 0,
            "total_overtime_hours": 0,
            "average_work_hours": 0
        }
    
    # Calculate statistics
    total_days = len(attendances)
    present_days = len([a for a in attendances if a.check_out_time is not None])
    
    # Calculate late check-ins (after 9:00 AM)
    late_days = 0
    total_work_seconds = 0
    total_overtime_seconds = 0
    
    for att in attendances:
        if att.check_in_time:
            check_in_hour = att.check_in_time.hour
            if check_in_hour >= 9:  # Consider late if 9 AM or later
                late_days += 1
        
        if att.check_out_time:
            work_seconds = (att.check_out_time - att.check_in_time).total_seconds()
            total_work_seconds += work_seconds
            
            # Calculate overtime (after 8 hours)
            work_hours = work_seconds / 3600.0
            if work_hours > 8:
                total_overtime_seconds += (work_hours - 8) * 3600.0
    
    total_work_hours = total_work_seconds / 3600.0
    total_overtime_hours = total_overtime_seconds / 3600.0
    
    return {
        "total_days": total_days,
        "present_days": present_days,
        "late_days": late_days,
        "total_work_hours": round(total_work_hours, 2),
        "total_overtime_hours": round(total_overtime_hours, 2),
        "average_work_hours": round(total_work_hours / present_days, 2) if present_days > 0 else 0
    }
