# Staff Track Dashboard

A modern, responsive web dashboard for hospital HR workforce management. This dashboard provides HR staff and administrators with comprehensive tools to manage employee attendance, leave requests, scheduling, and workforce analytics.

## Overview

The Staff Track Dashboard is part of the St. John's Hospital HR Workforce Management System, designed to streamline hospital operations through:

- Real-time attendance monitoring
- Leave request management and approvals
- Employee scheduling and shift management
- Workforce analytics and reporting
- Role-based access control for different user types

## Technology Stack

- **Frontend**: React 19.2.0 with TypeScript
- **Build Tool**: Vite 7.3.1
- **Styling**: TailwindCSS 3.4.19 with Tailwind Typography
- **Routing**: React Router DOM 7.13.1
- **HTTP Client**: Axios 1.13.6
- **Icons**: Lucide React 0.577.0
- **Development**: ESLint 9.39.1 with TypeScript support

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (version 18.0.0 or higher)
- **npm** (version 9.0.0 or higher) or **yarn** (version 1.22.0 or higher)
- **Git** for version control

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd staff-track-dashboard
```

### 2. Install Dependencies

Using npm:
```bash
npm install
```

Or using yarn:
```bash
yarn install
```

### 3. Environment Configuration

Create a `.env` file in the root directory (if it doesn't exist):

```env
VITE_API_URL=http://localhost:8888
```

**Note**: Update `VITE_API_URL` to point to your backend API server. The dashboard communicates with a FastAPI backend for data operations.

## Running the Application

### Development Mode

Start the development server with hot module replacement:

```bash
npm run dev
```

Or using yarn:
```bash
yarn dev
```

The application will be available at `http://localhost:5173` (or another port if 5173 is occupied).

### Production Build

Build the application for production:

```bash
npm run build
```

Or using yarn:
```bash
yarn build
```

The built files will be generated in the `dist` directory.

### Preview Production Build

Preview the production build locally:

```bash
npm run preview
```

Or using yarn:
```bash
yarn preview
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run lint` - Run ESLint for code quality checks
- `npm run preview` - Preview production build

## Project Structure

```
staff-track-dashboard/
├── public/                 # Static assets
├── src/
│   ├── components/         # Reusable UI components
│   ├── contexts/          # React contexts for state management
│   ├── pages/             # Page components
│   ├── services/          # API service layer
│   ├── assets/            # Images and other assets
│   ├── App.tsx            # Main application component
│   ├── main.tsx           # Application entry point
│   └── index.css          # Global styles
├── .env                   # Environment variables
├── package.json           # Dependencies and scripts
├── tailwind.config.js     # TailwindCSS configuration
├── vite.config.ts         # Vite build configuration
└── README.md              # This file
```

## User Roles and Access

The dashboard supports multiple user roles with different access levels:

- **HR Admin** - Full system access and user management
- **Medical Director** - Clinical staff oversight and approvals
- **Department Supervisor** - Department-specific request approvals
- **Doctor** - Limited clinical management functions
- **Nurse** - Basic access for personal information
- **Clinical Officer** - Mid-level clinical access
- **Support Staff** - Basic access to personal information

## Features

### Core Functionality

- **Dashboard Overview** - Real-time workforce statistics and metrics
- **Attendance Management** - Monitor employee check-ins and check-outs
- **Leave Management** - Process and approve leave requests
- **Employee Directory** - View and manage employee profiles
- **Scheduling** - Create and manage work schedules
- **Reports & Analytics** - Generate workforce reports and insights
- **Settings** - Configure system preferences and user management

### Key Components

- Responsive design that works on desktop and tablet devices
- Real-time data updates from the backend API
- Role-based UI that adapts to user permissions
- Interactive charts and visualizations
- Search and filtering capabilities
- Export functionality for reports

## API Integration

The dashboard communicates with a FastAPI backend running on the configured `VITE_API_URL`. Ensure the backend service is running before starting the dashboard.

### API Endpoints Used

- Authentication and authorization
- Employee data retrieval
- Attendance records
- Leave requests and approvals
- Scheduling information
- Analytics and reporting data

## Development Guidelines

### Code Quality

Run linting before committing changes:

```bash
npm run lint
```

### Styling

The project uses TailwindCSS for styling. Follow the existing design patterns and utility classes. Custom styles are defined in `src/index.css`.

### Component Development

- Use TypeScript for all components
- Follow the existing component structure in `src/components/`
- Implement proper error handling and loading states
- Use the established API service pattern in `src/services/`

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   - The development server may use a different port if 5173 is occupied
   - Check the terminal output for the actual URL

2. **API Connection Issues**
   - Ensure the backend API is running at the configured URL
   - Check the `.env` file for correct `VITE_API_URL`
   - Verify network connectivity and CORS settings

3. **Build Errors**
   - Run `npm install` to ensure all dependencies are current
   - Check for TypeScript errors in the console
   - Run `npm run lint` to identify code quality issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is part of the St. John's Hospital HR Workforce Management System. Contact the system administrator for licensing information.

## Support

For technical support or questions about the dashboard:

- Contact the development team
- Check the project documentation
- Review the system design document: `../Hospital_HR_System_Design.md`
