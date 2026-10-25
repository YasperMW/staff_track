# Staff Track

Staff Track is a hospital HR workforce management system for St. John's Hospital. It combines a Flutter mobile app for staff attendance with a React dashboard for HR and administrators, backed by a FastAPI and PostgreSQL service.

## Features

- GPS- and geofence-based attendance check-in/check-out with offline capture and sync
- Shift tracking, lateness and early-departure reasons, and attendance history
- Leave, request, and multi-level approval workflows
- Employee directory, departments, designations, grades, and file management
- Announcements, in-app notifications, and Firebase Cloud Messaging push notifications
- HR dashboards, analytics, and PDF reports
- Role-based access control across mobile and web clients

## Repository Layout

```
lib/                          Flutter mobile application
staff-track-dashboard/        React + Vite web dashboard
database/                     PostgreSQL schema and migrations
project.md                    Detailed project and architecture notes
Hospital_HR_System_Design.md  System design document
```

The FastAPI backend is maintained in a separate repository:
[YasperMW/staff_track_api](https://github.com/YasperMW/staff_track_api).

## Tech Stack

| Component | Technology |
| --- | --- |
| Mobile app | Flutter / Dart |
| Web dashboard | React, TypeScript, Vite, Tailwind CSS |
| Backend API | FastAPI / Python |
| Database | PostgreSQL with PostGIS |
| Notifications | Firebase Cloud Messaging |
| Maps and location | OpenStreetMap, Flutter Map, Geolocator |

## Prerequisites

- Flutter 3.9 or newer and the Dart SDK
- Node.js 18 or newer and npm
- PostgreSQL 14 or newer with the PostGIS extension
- Python 3.8 or newer (only if running the backend locally)
- Android Studio or Xcode for mobile builds

## Getting Started

### Mobile App

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8888
```

The API URL is read from the `API_BASE_URL` compile-time variable and defaults to `http://localhost:8888`. Set it for other environments:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

Firebase and Google Sign-In require local configuration files that are intentionally excluded from version control:

- `android/app/google-services.json` for Firebase
- `android/app/client_secret_<id>.apps.googleusercontent.com.json` for Google OAuth

Obtain these from your Firebase and Google Cloud projects and place them in `android/app/`.

### Web Dashboard

```bash
cd staff-track-dashboard
npm install
cp .env.example .env
npm run dev
```

Edit `.env` if the backend is not running at `http://localhost:8888`:

```env
VITE_API_URL=http://localhost:8888
VITE_FASTAPI_URL=http://localhost:8888
```

Other dashboard commands:

```bash
npm run build
npm run preview
npm run lint
```

### Database

Create a database and apply the schema:

```bash
createdb staff_track
psql staff_track < database/Staff_track_db_cleaned.sql
```

The checked-in schema contains table definitions, indexes, functions, and migrations only. It contains no employee data and no default user accounts. Create your first administrator through your deployment process.

### Backend API

Clone the backend repository and follow its setup instructions:

```bash
git clone https://github.com/YasperMW/staff_track_api.git
```

At minimum, configure:

- `SECRET_KEY` - required JWT signing key
- `DATABASE_URL` - PostgreSQL connection string
- `CORS_ORIGINS` - allowed frontend origins
- Firebase, email, and Google OAuth credentials as needed

## Configuration

| Client | Variable | Purpose |
| --- | --- | --- |
| Mobile app | `API_BASE_URL` | Backend base URL, set with `--dart-define` |
| Dashboard | `VITE_API_URL` | Backend base URL used by Axios |
| Dashboard | `VITE_FASTAPI_URL` | Secondary backend URL |
| Backend | `SECRET_KEY` | JWT signing secret |
| Backend | `DATABASE_URL` | PostgreSQL connection string |
| Backend | `APP_TIMEZONE` | Application timezone |
| Backend | `CORS_ORIGINS` | Allowed cross-origin clients |
| Backend | `FCM_*` | Firebase Cloud Messaging credentials |
| Backend | `EMAIL_*` | SMTP settings for outbound email |
| Backend | `GOOGLE_CLIENT_ID` | Google OAuth client ID |

## Secrets and Local Configuration

Never commit real credentials. The following are ignored by git:

- `.env` and `.env.*` files, except `.env.example`
- `android/app/google-services.json`
- `android/app/client_secret_*.json`
- `serviceAccountKey.json`
- Android keystores (`*.jks`, `*.keystore`)

Use the checked-in `.env.example` files as templates and inject production values through your deployment platform or CI secrets.

## User Roles

The dashboard and API support these roles:

- System Admin
- HR Admin
- Head of Department
- HR
- Accountant
- Principal Hospital Administrator
- System Administrator
- Staff

## Documentation

- [project.md](project.md) - feature overview, architecture, and workflows
- [Hospital_HR_System_Design.md](Hospital_HR_System_Design.md) - system design specification
- [staff-track-dashboard/README.md](staff-track-dashboard/README.md) - dashboard-specific setup

## Contributing

1. Create a feature branch.
2. Make your changes and run the relevant analyzer or linter (`flutter analyze`, `npm run lint`).
3. Open a pull request with a clear description of the change.

## License

No license has been specified for this project. Contact the maintainer before reusing or redistributing the code.
