# Staff Track - Hospital HR Workforce Management System

## Project Overview

Staff Track is a comprehensive workforce management solution designed for St. John's Hospital. It enables hospital employees to report for duty using a mobile application while HR staff manage workforce operations through a web dashboard. The system integrates staff self-registration, attendance tracking, leave management, performance monitoring, and analytics with enhanced security and reliability features.

### Core Objectives

- Mobile attendance with GPS and timestamp
- Offline attendance capture and sync
- HR monitoring dashboard
- Requests and approval workflows
- Employee reporting system
- Secure authentication and role-based access
- Real-time workforce analytics
- Support for shared devices and personal file access

---

## Tech Stack

| Component | Technology | Description |
|-----------|------------|-------------|
| **Mobile App** | Flutter | Cross-platform mobile framework (Dart) |
| **Backend API** | FastAPI | Python async web framework |
| **Database** | PostgreSQL | Relational database |
| **Caching/Sessions** | Redis | In-memory data store |
| **Web Dashboard** | React + Vite + TypeScript | Modern SPA with Tailwind CSS |
| **Notifications** | Firebase Cloud Messaging | Push notifications |
| **Maps** | OpenStreetMap / Flutter Map | Location services |

---

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────┐
│  Flutter App    │────▶│  FastAPI Backend │────▶│ PostgreSQL │
│  (Mobile)       │     │  (Python)        │     │            │
└─────────────────┘     └──────────────────┘     └─────┬──────┘
                                                       │
                               ┌───────────────────────┘
                               │
                        ┌──────▼──────┐
                        │    Redis     │
                        │ (Caching)   │
                        └─────────────┘
                               │
                        ┌──────▼──────┐
                        │    FCM       │
                        │ (Notifications)│
                        └─────────────┘

                               │
                        ┌──────▼──────┐
                        │ React Dashboard│
                        │ (Web)         │
                        └──────────────┘
```

**Architecture Pattern:** FastAPI serves as the single source of truth for business logic and API services. React functions as a presentation layer for HR staff, consuming FastAPI endpoints.

---

## User Roles

| Role | Description |
|------|-------------|
| System Admin | Full system access and technical management |
| HR Admin | Full HR system access and user management |
| Head of Department | Can approve requests for their department |
| HR | HR staff with limited HR functions |
| Accountant | Approves financial-impacting leaves and budgets |
| Principal Hospital Administrator | Final approver for hospital operations |
| System Administrator | IT infrastructure and system maintenance |
| Staff | Basic access for personal information |

> **Note:** Approval permissions are role-based and configurable via permissions matrix.

---

## Core Modules

### 1. Authentication Module
- Secure login with JWT authentication
- Password reset functionality
- Role-based access control
- Session management with Redis
- Employee self-registration with employee number, national ID, selfie, and password
- Account approval by HR
- Account blacklisting/suspension

### 2. Attendance Module
- Employee check-in/check-out
- GPS capture with latitude/longitude
- Device information logging
- Geofence validation
- Offline attendance queue with SQLite
- Support for clock-in/out on shared devices
- Real-time tracking by shift (day/night)
- Award full day based on valid location

### 3. Reports Module
- Daily work reports
- Incident reporting with attachments support

### 4. Requests & Approval Workflow
- Leave requests (Annual, Compassionate, Maternity, Paternity, Unpaid)
- Shift change requests
- Overtime requests
- Multi-level approvals: Head of Department → HR → Accountant → Principal Hospital Administrator
- Mobile approval support for designated approvers
- Leave balance calculations based on grade + bonus days
- Approval/denial with optional comments
- Push notifications on status updates

### 5. Notifications Module
- Push notifications via Firebase Cloud Messaging
- Approval alerts
- System alerts to approvers during leave applications

### 6. Analytics Module
- Attendance trends
- Absenteeism reports
- Department summaries
- Real-time dashboards (total staff clocked in/out by shift)
- Actionable HR insights

### 7. Audit Logging
- HR actions tracking
- Login tracking
- Request approval logs

---

## Mobile Application Screens

The mobile app uses **role-based navigation**:

### Authentication Screens (All Users)
- Login Screen
- Register / Self-Onboard Screen
- Forgot Password Screen
- Biometric Setup Screen

### Employee Dashboard (Regular Staff)
- Daily Status & Quick Check-in Button
- Notifications Overview
- Payslip Access Quick Link
- Personal Attendance Summary

### Approver Dashboard (Hierarchy Roles)
- Pending Approvals Summary
- My Team / Department Attendance Overview
- Notifications Overview
- Quick Analytics Snapshot

### Bottom Navigation (Regular Employees)
- Home (Dashboard)
- Attendance (Check-in, Check-out, History)
- Requests (Submit Request, Status, Balances)
- Reports (Submit Work/Incident, History)
- Profile (Personal info, Photo, Payslips)
- Notifications

### Bottom Navigation (Approvers)
- Home (Approver Dashboard)
- Pending Approvals
- Team Attendance (Live view)
- Requests
- Analytics
- Profile
- Notifications

---

## Web Dashboard Screens

### Authentication
- Admin Login Screen
- HR Create Employee Account Screen
- Pending Self-Registrations Queue
- Role Assignment During Account Creation
- Account Management / Blacklist Users Screen

### HR Dashboard
- Workforce Overview
- Attendance Summary
- Notifications Panel
- Real-time shift tracking

### Attendance Management
- Live Attendance Table
- Attendance Map View
- Late Arrival Monitor

### Employee Management
- Employee List
- Add/Edit Employee
- Role & Department Assignment
- File Uploads (JODs, offer letters, payslips)

### Requests & Approvals
- Pending Requests Queue
- Approval Workflow Screen
- Request History

### Reports Management
- Staff Work Reports Viewer
- Incident Reports Viewer

### Analytics & Reports
- Monthly Attendance Reports
- Department Performance Charts
- Workforce Statistics

### System Management
- Departments Management
- Roles & Permissions
- Audit Logs Viewer

---

## Database Design

### Core Tables

**users**
- id, employee_number, national_id, name, email, phone
- password_hash, role_id, department_id, status
- profile_photo_url, blacklisted_at, blacklisted_reason
- registration_timestamp, selfie_verified

**roles**
- id, name

**departments**
- id, name

**attendance_logs**
- id, user_id, check_in_time, check_out_time
- latitude, longitude, accuracy, device_id
- offline_flag, sync_time

**work_reports**
- id, user_id, report_text, attachments, shift_date

**requests**
- id, user_id, type, reason, start_date, end_date
- status, approved_by, current_approver_id
- approval_level, approval_comments

**request_approvals**
- id, request_id, approver_id, level, action, comment, timestamp

**leave_balances**
- id, user_id, leave_type, allocated_days, used_days, remaining_days, bonus_days

**audit_logs**
- id, actor_id, action, entity, timestamp, ip_address

**employee_files**
- id, user_id, file_type, file_url, upload_date

---

## Offline Attendance Strategy

- Store attendance locally using SQLite
- Queue offline records
- Sync automatically when internet returns
- Preserve original timestamps
- Handle duplicate prevention

---

## Geolocation & Attendance Validation

- GPS capture with accuracy measurement
- Geofence radius validation
- Device ID logging
- Network IP recording
- Optional selfie verification
- Optional QR location verification

---

## Security Requirements

### Application Security
- HTTPS everywhere
- JWT with refresh tokens
- Encrypted passwords (bcrypt)
- Role-based permissions
- API rate limiting

### Data Protection
- Encrypted storage of sensitive data
- Audit logging
- Secure token storage on mobile

### Infrastructure Security
- Automated backups
- Server monitoring
- Firewall configuration
- Token revocation via Redis blacklist

---

## Deployment Architecture

### Hybrid Deployment Strategy

**Local Hospital Server**
- FastAPI Backend
- PostgreSQL Database
- Internal Dashboard Access

**Cloud Server**
- Backup services
- Remote monitoring
- Notifications
- Analytics processing

**Benefits**
- Works during internet outages
- Faster local access
- Reliable data redundancy

---

## Development Phases

### Phase 1 – Core System
- Authentication (including self-registration)
- Attendance system
- HR dashboard
- Requests submission workflow
- Basic mobile approval screens + RBAC enforcement

### Phase 2 – Reliability
- Offline sync (including queued approval actions)
- Notifications (enhanced for approver alerts)
- Analytics
- Audit logs
- Blacklisting

### Phase 3 – Advanced Features
- Selfie verification with liveness detection
- AI anomaly detection
- Payroll export (payslips)
- Shift scheduling
- Advanced mobile approvals (bulk actions, delegation)

---

## Key Dependencies

### Mobile (Flutter)
- provider (state management)
- google_fonts
- firebase_core, firebase_messaging
- flutter_local_notifications
- google_sign_in
- geolocator, geocoding
- flutter_map, latlong2
- image_picker, file_picker
- shared_preferences
- connectivity_plus

### Backend (FastAPI)
- PostgreSQL (asyncpg)
- Redis (redis-py)
- Firebase Admin SDK
- JWT (python-jose)
- Pydantic

### Web Dashboard (React)
- React 19 + TypeScript
- Vite
- Tailwind CSS
- React Router DOM
- Axios
- Lucide React (icons)

---

## Project Structure

```
staff_track/
├── lib/                    # Flutter mobile app
├── staff_track_api/        # FastAPI backend
├── staff-track-dashboard/  # React web dashboard
├── assets/                 # Images, logos
├── android/                # Android platform files
├── ios/                    # iOS platform files
├── web/                    # Web platform files
└── database/               # Database schemas
```

---

## Summary

Staff Track is a production-grade Hospital HR Workforce Management System that provides:

- **Efficient Attendance Tracking** - GPS-based with offline support
- **Streamlined Approvals** - Multi-level workflow with mobile support
- **Real-time Insights** - Analytics dashboards for HR decision-making
- **Robust Security** - JWT auth, RBAC, audit logging
- **Flexible Deployment** - Hybrid local/cloud architecture