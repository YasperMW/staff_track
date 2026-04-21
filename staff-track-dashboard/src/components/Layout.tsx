import React, { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import {
  LayoutDashboard,
  Users,
  Building2,
  Shield,
  Calendar,
  FileText,
  Bell,
  Send,
  Settings,
  LogOut,
  Menu,
  X,
  ChevronDown,
  Sun,
  Moon,
  BarChart3,
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
  const { theme, toggleTheme } = useTheme();
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
      label: 'Roles',
      icon: Shield,
      path: '/roles',
    },
    {
      label: 'Attendance',
      icon: Calendar,
      path: '/attendance',
    },
    {
      label: 'Reports',
      icon: BarChart3,
      path: '/reports',
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
      label: 'Push Notifications',
      icon: Send,
      path: '/notifications',
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

  // Close profile dropdown on Escape
  useEffect(() => {
    if (!profileDropdownOpen) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setProfileDropdownOpen(false);
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [profileDropdownOpen]);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex">
      {/* Skip to main content – keyboard / screen-reader accessibility */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-[100] focus:px-4 focus:py-2 focus:bg-blue-600 focus:text-white focus:rounded-lg focus:text-sm focus:font-semibold focus:shadow-lg"
      >
        Skip to main content
      </a>
      {/* Sidebar Overlay for Mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed top-0 left-0 z-50 w-64 h-screen bg-white dark:bg-gray-800 shadow-xl transform transition-transform duration-300 ease-in-out lg:relative lg:z-0 lg:translate-x-0 flex flex-col ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-700">
          <div className="flex items-center space-x-3">
            <img 
              src="/src/assets/logo.png" 
              alt="Staff Track Logo" 
              className="w-10 h-10 rounded-xl object-contain"
            />
            <div>
              <h1 className="text-lg font-bold text-gray-900 dark:text-white">Staff Track</h1>
              <p className="text-xs text-gray-500 dark:text-gray-400">Admin Portal</p>
            </div>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          >
            <X className="w-5 h-5 text-gray-900 dark:text-white" />
          </button>
        </div>

        <nav className="p-4 flex-1 overflow-y-auto">
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
                    aria-current={isActive ? 'page' : undefined}
                    className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 ${
                      isActive
                        ? 'bg-blue-500 text-white shadow-md'
                        : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-white'
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
                            ? 'bg-white text-blue-500'
                            : 'bg-red-500 text-white'
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
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Top Header */}
        <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 sticky top-0 z-30 flex-shrink-0">
          <div className="flex items-center justify-between px-6 py-4">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Menu className="w-5 h-5 text-gray-900 dark:text-white" />
              </button>
              
              <div>
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                  {sidebarItems.find(item => isActivePath(item.path))?.label || 'Dashboard'}
                </h2>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Welcome back, {user?.first_name || 'Admin'}
                </p>
              </div>
            </div>

            {/* Profile Dropdown */}
            <div className="flex items-center space-x-3">
              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                title="Toggle theme"
              >
                {theme === 'light' ? (
                  <Moon className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                ) : (
                  <Sun className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                )}
              </button>

              {/* User Profile */}
              <div className="relative">
                <button
                  onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
                  className="flex items-center space-x-3 p-2 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                >
                <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-semibold">
                    {user?.first_name?.[0] || 'A'}
                  </span>
                </div>
                <span className="hidden md:block text-sm font-medium text-gray-900 dark:text-white">
                  {user?.first_name} {user?.surname}
                </span>
                <ChevronDown className="w-4 h-4 text-gray-500 dark:text-gray-400" />
              </button>

              {profileDropdownOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 py-2 z-50">
                  <div className="px-4 py-2 border-b border-gray-100 dark:border-gray-700">
                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                      {user?.first_name} {user?.surname}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{user?.email}</p>
                    <p className="text-xs text-blue-500 font-medium">{user?.role_name}</p>
                  </div>
                  
                  <button
                    onClick={handleLogout}
                    className="w-full flex items-center space-x-2 px-4 py-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <LogOut className="w-4 h-4" />
                    <span className="text-sm font-medium">Logout</span>
                  </button>
                </div>
              )}
            </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main id="main-content" className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default Layout;
