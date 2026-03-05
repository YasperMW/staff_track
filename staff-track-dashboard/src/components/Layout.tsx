import React, { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import {
  LayoutDashboard,
  Users,
  Building2,
  Shield,
  Calendar,
  FileText,
  Bell,
  Settings,
  LogOut,
  Menu,
  X,
  ChevronDown,
} from 'lucide-react';

interface SidebarItem {
  label: string;
  icon: React.ElementType;
  path: string;
  badge?: number;
}

const Layout: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const sidebarItems: SidebarItem[] = [
    {
      label: 'Dashboard',
      icon: LayoutDashboard,
      path: '/dashboard',
    },
    {
      label: 'Users',
      icon: Users,
      path: '/users',
    },
    {
      label: 'Departments',
      icon: Building2,
      path: '/departments',
    },
    {
      label: 'Roles & Permissions',
      icon: Shield,
      path: '/roles',
    },
    {
      label: 'Attendance',
      icon: Calendar,
      path: '/attendance',
    },
    {
      label: 'Requests',
      icon: FileText,
      path: '/requests',
    },
    {
      label: 'Announcements',
      icon: Bell,
      path: '/announcements',
    },
    {
      label: 'Settings',
      icon: Settings,
      path: '/settings',
    },
  ];

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const isActivePath = (path: string) => {
    if (path === '/dashboard') {
      return location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div className="min-h-screen bg-background-white">
      {/* Sidebar Overlay for Mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed top-0 left-0 z-50 w-64 h-full bg-surface-white shadow-xl transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:z-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-sky-blue to-light-gold rounded-xl flex items-center justify-center">
              <Building2 className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-text-dark">Staff Track</h1>
              <p className="text-xs text-text-grey">Admin Portal</p>
            </div>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5 text-text-dark" />
          </button>
        </div>

        <nav className="p-4">
          <ul className="space-y-2">
            {sidebarItems.map((item) => {
              const Icon = item.icon;
              const isActive = isActivePath(item.path);
              
              return (
                <li key={item.path}>
                  <button
                    onClick={() => {
                      navigate(item.path);
                      setSidebarOpen(false);
                    }}
                    className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 ${
                      isActive
                        ? 'bg-sky-blue text-white shadow-md'
                        : 'text-text-grey hover:bg-gray-50 hover:text-text-dark'
                    }`}
                  >
                    <div className="flex items-center space-x-3">
                      <Icon className="w-5 h-5" />
                      <span className="font-medium">{item.label}</span>
                    </div>
                    {item.badge && item.badge > 0 && (
                      <span
                        className={`px-2 py-1 text-xs font-semibold rounded-full ${
                          isActive
                            ? 'bg-white text-sky-blue'
                            : 'bg-pale-red text-white'
                        }`}
                      >
                        {item.badge > 99 ? '99+' : item.badge}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </nav>
      </div>

      {/* Main Content */}
      <div className="lg:ml-64">
        {/* Top Header */}
        <header className="bg-surface-white shadow-sm border-b border-gray-100 sticky top-0 z-30">
          <div className="flex items-center justify-between px-6 py-4">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden p-2 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <Menu className="w-5 h-5 text-text-dark" />
              </button>
              
              <div>
                <h2 className="text-xl font-semibold text-text-dark">
                  {sidebarItems.find(item => isActivePath(item.path))?.label || 'Dashboard'}
                </h2>
                <p className="text-sm text-text-grey">
                  Welcome back, {user?.first_name || 'Admin'}
                </p>
              </div>
            </div>

            {/* Profile Dropdown */}
            <div className="relative">
              <button
                onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
                className="flex items-center space-x-3 p-2 rounded-xl hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-sky-blue rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-semibold">
                    {user?.first_name?.[0] || 'A'}
                  </span>
                </div>
                <span className="hidden md:block text-sm font-medium text-text-dark">
                  {user?.first_name} {user?.surname}
                </span>
                <ChevronDown className="w-4 h-4 text-text-grey" />
              </button>

              {profileDropdownOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-surface-white rounded-xl shadow-lg border border-gray-100 py-2 z-50">
                  <div className="px-4 py-2 border-b border-gray-100">
                    <p className="text-sm font-medium text-text-dark">
                      {user?.first_name} {user?.surname}
                    </p>
                    <p className="text-xs text-text-grey">{user?.email}</p>
                    <p className="text-xs text-sky-blue font-medium">{user?.role_name}</p>
                  </div>
                  
                  <button
                    onClick={handleLogout}
                    className="w-full flex items-center space-x-2 px-4 py-2 text-pale-red hover:bg-red-50 transition-colors"
                  >
                    <LogOut className="w-4 h-4" />
                    <span className="text-sm font-medium">Logout</span>
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default Layout;
