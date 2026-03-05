import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { ToastProvider } from './contexts/ToastContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Departments from './pages/Departments';
import Roles from './pages/Roles';
import Attendance from './pages/Attendance';
import Requests from './pages/Requests';
import Announcements from './pages/Announcements';
import Settings from './pages/Settings';
import Profile from './pages/Profile';
import ProtectedRoute from './components/ProtectedRoute';

// Placeholder components for other routes

function App() {
  return (
    <ToastProvider>
      <ThemeProvider>
        <AuthProvider>
          <Router>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route
                path="/dashboard"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Dashboard />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/users"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Users />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/departments"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Departments />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/roles"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Roles />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/attendance"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Attendance />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/requests"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Requests />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/announcements"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Announcements />
                    </Layout>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/settings"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Settings />
                    </Layout>
                  </ProtectedRoute>
                }
              />
            </Routes>
          </Router>
        </AuthProvider>
      </ThemeProvider>
    </ToastProvider>
  );
}

export default App;
