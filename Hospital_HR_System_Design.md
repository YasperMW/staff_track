# St. John’s Hospital HR Workforce Management System

## System Design & Implementation Document

### 1. Project Overview

#### Purpose
Design and implement a production-grade Hospital HR Workforce Management System that enables hospital employees to report for duty using a mobile application while HR staff manage workforce operations through a web dashboard. The system integrates staff self-registration, attendance tracking, leave management, performance monitoring, and analytics, with enhanced security and reliability features.

#### Core Objectives
- Mobile attendance with GPS and timestamp
- Offline attendance capture and sync
- HR monitoring dashboard
- Requests and approval workflows, including specific leave types
- Employee reporting system
- Secure authentication and role-based access, with self-registration and blacklisting
- Real-time workforce analytics
- Support for shared devices and personal file access (e.g., payslips)

### 2. Technology Stack

#### Mobile Application
- Flutter

#### Backend API (Core System)
- FastAPI
- PostgreSQL
- Redis

#### Web Dashboard
- Laravel (Frontend/UI consuming FastAPI APIs)

#### Supporting Services
- Firebase Cloud Messaging (Notifications)
- OpenStreetMap / Mapbox (Maps & Location)

### 3. High-Level Architecture
Flutter Mobile App → FastAPI Backend → PostgreSQL Database  
Laravel Web Dashboard → FastAPI Backend

FastAPI serves as the single source of business logic and API services. Laravel functions as a presentation layer for HR staff.

### 4. User Roles
- HR Admin
- Medical Director
- Department Supervisor (Head of Department) – Can approve requests for their department
- Doctor (potential approver depending on config)
- Nurse
- Clinical Officer
- Support Staff
- Accountant – Approves financial-impacting leaves
- Principal Hospital Administrator – Final approver
- System Admin (with managerial rights alongside HR)

**Note**: Approval permissions are role-based and configurable (e.g., via permissions matrix: can_approve_annual_leave, can_approve_maternity, etc.).

### 5. Core System Modules

#### Authentication Module
- Secure login
- JWT authentication
- Password reset
- Role-based access control
- Session management
- Employee self-registration with employee number, national ID, selfie/photo, and password creation
- Account approval by HR
- Blacklisting/suspension of accounts

#### Attendance Module
- Employee check-in/check-out
- GPS capture
- Device information logging
- Geofence validation
- Offline attendance queue
- Support for clock-in/out on shared devices
- Real-time tracking of staff clocked in/out by shift (day/night)
- Award full day based on valid location; otherwise register absent

#### Reports Module
- Daily work reports
- Incident reporting
- Attachments support

#### Requests & Approval Workflow
- Leave requests (Annual, Compassionate, Maternity, Paternity, Unpaid)
- Shift change requests
- Overtime requests
- Multi-level approvals following hierarchy: Head of Department → HR → Accountant → Principal Hospital Administrator
- Mobile approval support: Designated approvers can review and action pending requests assigned to them via the mobile app
- Leave balance calculations based on grade + bonus days
- Partial leave adjustments and balance display
- Drill-down selection of approvers during submission (for notifications/routing)
- Approval/denial with optional comments; status updates trigger notifications to employee and next approver

#### Notifications Module
- Push notifications
- Approval alerts
- System alerts
- Notifications to approvers during leave applications

#### Analytics Module
- Attendance trends
- Absenteeism reports
- Department summaries
- Workforce analytics
- Real-time dashboards (e.g., total staff clocked in/out by shift)
- Actionable HR insights

#### Audit Logging
- HR actions tracking
- Login tracking
- Request approval logs

### 6. Mobile Application Screens (Employees & Approvers)

The mobile app uses **role-based navigation** to present tailored interfaces:
- **Regular Employees** (non-approver roles): Focus on self-service (attendance, submit requests, personal info).
- **Approvers** (roles with approval permissions): Dedicated approval-centric screens and navigation.

**Common Authentication Screens** (all users)
- Login Screen
- Register / Self-Onboard Screen (enter employee number, national ID, capture/upload selfie, create password, other details)
- Forgot Password Screen
- Biometric Setup Screen (optional after activation/approval)

**Role-Based Home / Dashboard**
- **Employee Dashboard** (regular staff)
  - Daily Status & Quick Check-in Button
  - Notifications Overview
  - Payslip Access Quick Link
  - Personal Attendance Summary
- **Approver Dashboard** (hierarchy roles)
  - Pending Approvals Summary (count + urgent items)
  - My Team / Department Attendance Overview
  - Notifications Overview (including approval alerts)
  - Quick Analytics Snapshot (e.g., absenteeism in department)

**Bottom Navigation / Main Flows** (role-specific)

**For Regular Employees**
- Home (Dashboard)
- Attendance (Report for Duty, Check-Out, History)
- Requests (Submit Request with hierarchy selection, Request Status & Balances)
- Reports (Submit Work/Incident, History)
- Profile (Personal info, Photo, Payslips, Device Info)
- Notifications (Center)

**For Approvers**
- Home (Approver Dashboard)
- Pending Approvals (dedicated screen – list of requests routed to current user; filters by type/date/department)
  - Pending Approvals List
  - Request Detail View (employee info, dates, type, reason, attachments, previous approvals/comments)
  - Approve / Deny with Comment Field
  - Bulk select & action (Phase 3)
- Team Attendance (Live view of department/team clock-ins, map, late arrivals)
- Requests (View submitted/own requests + approval history)
- Analytics (Department trends, absenteeism, workforce stats)
- Profile (same as employees + approval delegation options if Phase 3)
- Notifications (Center with priority on approval alerts)

**Additional Shared / Conditional Screens**
- Notification Center (accessible to all)
- Request Status / History (employees see own; approvers see assigned + department)
- Audit / Logs Viewer (HR/Admin roles only, possibly web-only initially)

### 7. Web Dashboard Screens (HR & Supervisors)

#### Authentication
- Admin Login Screen
- HR Create Employee Account Screen (pre-assign employee number, etc.)
- Pending Self-Registrations Queue (review details, selfie, national ID)
- Role Assignment During Account Creation
- Account Management / Blacklist Users Screen

#### HR Dashboard
- Workforce Overview
- Attendance Summary
- Notifications Panel
- Real-time shift tracking (clocked in/out)

#### Attendance Management
- Live Attendance Table
- Attendance Map View
- Late Arrival Monitor

#### Employee Management
- Employee List
- Add/Edit Employee
- Role & Department Assignment
- File Uploads (JODs = Job Descriptions, offer letters, payslips)

#### Requests & Approvals
- Pending Requests Queue
- Approval Workflow Screen
- Request History

#### Reports Management
- Staff Work Reports Viewer
- Incident Reports Viewer

#### Analytics & Reports
- Monthly Attendance Reports
- Department Performance Charts
- Workforce Statistics

#### System Management
- Departments Management
- Roles & Permissions
- Audit Logs Viewer

### 8. Database Design (Core Tables)

#### users
- id (PK)
- employee_number (unique, primary identifier)
- national_id (unique)
- name
- email
- phone
- password_hash
- role_id (FK to roles)
- department_id (FK to departments)
- status (e.g., pending, active, blacklisted, suspended, terminated)
- profile_photo_url
- blacklisted_at (timestamp)
- blacklisted_reason
- registration_timestamp
- selfie_verified (boolean)

#### roles
- id (PK)
- name (e.g., HR Admin, Doctor)

#### departments
- id (PK)
- name

#### attendance_logs
- id (PK)
- user_id (FK)
- check_in_time
- check_out_time
- latitude
- longitude
- accuracy
- device_id
- offline_flag
- sync_time

#### work_reports
- id (PK)
- user_id (FK)
- report_text
- attachments
- shift_date

#### requests
- id (PK)
- user_id (FK)
- type (e.g., annual_leave, compassionate_leave)
- reason
- start_date
- end_date
- status (pending, approved, denied)
- approved_by (FK to users)
- current_approver_id (FK to users)
- approval_level (integer)
- approval_comments (JSONB or TEXT)

#### request_approvals (for history per level)
- id (PK)
- request_id (FK)
- approver_id (FK)
- level (integer)
- action (approve/deny)
- comment
- timestamp

#### leave_balances
- id (PK)
- user_id (FK)
- leave_type
- allocated_days
- used_days
- remaining_days
- bonus_days

#### audit_logs
- id (PK)
- actor_id (FK)
- action
- entity
- timestamp
- ip_address

#### employee_files (for centralized files)
- id (PK)
- user_id (FK)
- file_type (e.g., JOD, offer_letter, payslip)
- file_url
- upload_date

#### pending_registrations (optional staging table)
- id (PK)
- employee_number
- national_id
- selfie_url
- status (pending_approval, approved, rejected)

### 9. Offline Attendance Strategy
- Store attendance locally using SQLite
- Queue offline records
- Sync automatically when internet returns
- Preserve original timestamps
- Handle duplicate prevention

### 10. Geolocation & Attendance Validation
- GPS capture
- Geofence radius validation
- Device ID logging
- Network IP recording
- Optional selfie verification
- Optional QR location verification

### 11. Security Requirements

#### Application Security
- HTTPS everywhere
- JWT with refresh tokens
- Encrypted passwords
- Role-based permissions
- API rate limiting

#### Data Protection
- Encrypted storage of sensitive data
- Audit logging
- Secure token storage on mobile

#### Infrastructure Security
- Automated backups
- Server monitoring
- Firewall configuration
- Blacklisting mechanism with Redis for token revocation

### 12. Deployment Architecture

#### Hybrid Deployment Strategy

**Local Hospital Server**
- FastAPI Backend
- PostgreSQL Database
- Internal Dashboard Access

**Cloud Server**
- Backup services
- Remote monitoring
- Notifications
- Analytics processing

**Benefits**:
- Works during internet outages
- Faster local access
- Reliable data redundancy

### 13. Development Phases

#### Phase 1 – Core System
- Authentication (including self-registration)
- Attendance system
- HR dashboard
- Requests submission workflow
- Basic mobile approval screens + RBAC enforcement

#### Phase 2 – Reliability
- Offline sync (including queued approval actions)
- Notifications (enhanced for approver alerts)
- Analytics
- Audit logs
- Blacklisting

#### Phase 3 – Advanced Features
- Selfie verification with liveness detection
- AI anomaly detection (e.g., flag suspicious leave patterns)
- Payroll export (including payslips)
- Shift scheduling
- Advanced mobile approvals (bulk actions, calendar preview, delegation)

### 14. Operational Considerations
- Staff training sessions required
- Device management policies (including shared devices)
- Support procedures
- Backup recovery testing
- System monitoring

### 15. Authentication & Account Lifecycle

#### Account Creation (HR Pre-Assignment)
- HR creates pending employee records with unique employee_number, basic details, and permissions via dashboard
- System generates invitation or allows self-registration lookup

#### Employee Self-Registration (Mobile)
- Enter employee_number, national_id, selfie, other details, and create password
- Provisional account created pending HR approval
- Optional biometric setup after approval

#### Login Process
- Secure JWT-based authentication
- Refresh token lifecycle management
- Device session tracking
- Suspicious login detection (new device/location alerts)

#### Password Management
- Forgot password workflow with OTP or secure token
- Forced periodic password updates (configurable)
- Account lockout after repeated failed login attempts
- No mandatory first change (since self-created)

#### Device & Session Management
- Limit number of active devices per user
- Remote logout by HR/admin
- Session expiration controls
- Support for shared devices in clock-in/out

#### Account Recovery & Deactivation
- HR ability to deactivate/blacklist staff accounts immediately
- Automatic deactivation for terminated staff
- Audit trail for account changes

#### Security Enhancements
- Optional multi-factor authentication for HR users
- IP address logging
- Login activity monitoring
- Role-based access enforcement during authentication
- Redis-based token blacklisting for immediate revocation

**End of Document**