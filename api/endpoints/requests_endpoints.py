from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from database import get_db
from endpoints.auth_endpoints import get_current_user
from models.db_models import User

router = APIRouter(prefix="/requests", tags=["requests"])


class RequestCreate(BaseModel):
    type: str
    start_date: str
    end_date: Optional[str] = None


@router.get("/summary")
async def get_requests_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = db.execute(
        text(
            """
            SELECT type, COUNT(*) AS count
            FROM requests
            WHERE status = 'pending' AND deleted_at IS NULL
            GROUP BY type
            """
        )
    ).fetchall()

    total_pending = 0
    by_type = []

    for row in result:
        request_type = row[0]
        count = int(row[1] or 0)
        total_pending += count
        by_type.append(
            {
                "type": request_type,
                "count": count,
            }
        )

    return {
        "total_pending": total_pending,
        "by_type": by_type,
    }


@router.post("")
async def create_request(
    payload: RequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        start_date = date.fromisoformat(payload.start_date)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid start_date format. Use YYYY-MM-DD.",
        )

    end_date_value = payload.end_date or payload.start_date
    try:
        end_date = date.fromisoformat(end_date_value)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid end_date format. Use YYYY-MM-DD.",
        )

    now = datetime.utcnow()

    result = db.execute(
        text(
            """
            INSERT INTO requests (
                request_id,
                user_id,
                type,
                start_date,
                end_date,
                status,
                current_approver_id,
                created_at,
                updated_at,
                deleted_at
            )
            VALUES (
                gen_random_uuid(),
                :user_id,
                :type,
                :start_date,
                :end_date,
                'pending',
                NULL,
                :created_at,
                :updated_at,
                NULL
            )
            RETURNING request_id
            """
        ),
        {
            "user_id": current_user.user_id,
            "type": payload.type,
            "start_date": start_date,
            "end_date": end_date,
            "created_at": now,
            "updated_at": now,
        },
    ).fetchone()

    if not result:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create request",
        )

    db.commit()

    return {"success": True, "id": str(result[0])}


@router.get("/admin/pending-list")
async def get_admin_pending_requests_list(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.role or not current_user.role.name:
        pass

    result = db.execute(
        text(
            """
            SELECT 
                r.request_id,
                r.type,
                r.start_date,
                r.end_date,
                r.status,
                u.first_name,
                u.surname,
                u.user_id
            FROM requests r
            JOIN users u ON u.user_id = r.user_id
            WHERE r.status = 'pending'
              AND r.deleted_at IS NULL
              AND (r.current_approver_id IS NULL OR r.current_approver_id = :approver_id)
            ORDER BY r.created_at DESC
            """
        ),
        {"approver_id": current_user.user_id},
    ).fetchall()

    requests = []

    for row in result:
        start_date = row[2]
        end_date = row[3]
        if end_date and end_date != start_date:
            date_range = f"{start_date.strftime('%b %d')} - {end_date.strftime('%b %d')}"
        else:
            date_range = start_date.strftime("%b %d")

        if end_date and end_date != start_date:
            duration_days = (end_date - start_date).days + 1
            duration = f"{duration_days} days"
        else:
            duration = "1 day"

        full_name = f"{row[5] or ''} {row[6] or ''}".strip()

        requests.append(
            {
                "id": str(row[0]),
                "type": row[1],
                "status": row[4],
                "date_range": date_range,
                "duration": duration,
                "user_name": full_name,
                "user_id": str(row[7]),
            }
        )

    return requests


@router.post("/admin/{request_id}/approve")
async def approve_request(
    request_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = db.execute(
        text(
            """
            UPDATE requests
            SET status = 'approved',
                updated_at = NOW()
            WHERE request_id = :request_id
              AND status = 'pending'
              AND deleted_at IS NULL
              AND (current_approver_id IS NULL OR current_approver_id = :approver_id)
            RETURNING request_id
            """
        ),
        {"request_id": request_id, "approver_id": current_user.user_id},
    ).fetchone()

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found or not eligible for approval",
        )

    db.commit()

    return {"success": True}


@router.post("/admin/{request_id}/deny")
async def deny_request(
    request_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = db.execute(
        text(
            """
            UPDATE requests
            SET status = 'denied',
                updated_at = NOW()
            WHERE request_id = :request_id
              AND status = 'pending'
              AND deleted_at IS NULL
              AND (current_approver_id IS NULL OR current_approver_id = :approver_id)
            RETURNING request_id
            """
        ),
        {"request_id": request_id, "approver_id": current_user.user_id},
    ).fetchone()

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found or not eligible for denial",
        )

    db.commit()

    return {"success": True}
