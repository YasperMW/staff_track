import React, { useState } from 'react';
import { useToast } from '../contexts/ToastContext';
import { useTheme } from '../contexts/ThemeContext';
import { 
  Settings as SettingsIcon, 
  User, 
  Bell, 
  Shield, 
  Database, 
  Mail, 
  Smartphone, 
  Globe, 
  Moon, 
  Sun, 
  Save,
  RefreshCw,
  Download,
  Upload,
  Key,
  Lock,
  Eye,
  EyeOff
} from 'lucide-react';

const Settings: React.FC = () => {
  const { success, error, warning, info } = useToast();
  const { theme, toggleTheme } = useTheme();
  
  // Profile Settings
  const [profile, setProfile] = useState({
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@hospital.com',
    phone: '+1 234 567 8900',
    department: 'Emergency Department',
    role: 'Administrator'
  });

  // Notification Settings
  const [notifications, setNotifications] = useState({
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    announcementAlerts: true,
    requestAlerts: true,
    systemAlerts: true,
    weeklyReports: true,
    monthlyReports: false
  });

  // Security Settings
  const [security, setSecurity] = useState({
    twoFactorAuth: false,
    sessionTimeout: '30',
    passwordExpiry: '90',
    loginAlerts: true,
    apiAccess: false
  });

  // System Settings
  const [system, setSystem] = useState({
    timezone: 'UTC',
    language: 'English',
    dateFormat: 'MM/DD/YYYY',
    timeFormat: '12-hour',
    defaultPage: 'dashboard',
    autoSave: true,
    compactMode: false
  });

  // Password visibility states
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Password change form
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  const handleSaveProfile = () => {
    success('Profile settings saved successfully');
  };

  const handleSaveNotifications = () => {
    success('Notification preferences updated');
  };

  const handleSaveSecurity = () => {
    success('Security settings updated');
  };

  const handleSaveSystem = () => {
    success('System preferences saved');
  };

  const handlePasswordChange = () => {
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      error('New passwords do not match');
      return;
    }
    
    if (passwordForm.newPassword.length < 8) {
      error('Password must be at least 8 characters long');
      return;
    }

    success('Password changed successfully');
    setPasswordForm({
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    });
  };

  const handleExportData = () => {
    info('Exporting user data...');
    // TODO: Implement data export
  };

  const handleImportData = () => {
    info('Import functionality coming soon');
    // TODO: Implement data import
  };

  const handleClearCache = () => {
    warning('Cache cleared successfully');
    // TODO: Implement cache clearing
  };

  const handleResetSettings = () => {
    warning('Settings reset to defaults');
    // TODO: Implement settings reset
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Settings
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage your account settings and preferences
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile Settings */}
        <div className="lg:col-span-2 space-y-6">
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <User className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Profile Settings
              </h2>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  First Name
                </label>
                <input
                  type="text"
                  value={profile.firstName}
                  onChange={(e) => setProfile({...profile, firstName: e.target.value})}
                  className="input-field"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Last Name
                </label>
                <input
                  type="text"
                  value={profile.lastName}
                  onChange={(e) => setProfile({...profile, lastName: e.target.value})}
                  className="input-field"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Email
                </label>
                <input
                  type="email"
                  value={profile.email}
                  onChange={(e) => setProfile({...profile, email: e.target.value})}
                  className="input-field"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Phone
                </label>
                <input
                  type="tel"
                  value={profile.phone}
                  onChange={(e) => setProfile({...profile, phone: e.target.value})}
                  className="input-field"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Department
                </label>
                <select
                  value={profile.department}
                  onChange={(e) => setProfile({...profile, department: e.target.value})}
                  className="input-field"
                >
                  <option value="Emergency Department">Emergency Department</option>
                  <option value="ICU">ICU</option>
                  <option value="Surgery">Surgery</option>
                  <option value="Pediatrics">Pediatrics</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Role
                </label>
                <input
                  type="text"
                  value={profile.role}
                  disabled
                  className="input-field bg-gray-100 dark:bg-gray-800"
                />
              </div>
            </div>
            
            <div className="mt-6">
              <button onClick={handleSaveProfile} className="btn-primary flex items-center space-x-2">
                <Save className="w-4 h-4" />
                <span>Save Profile</span>
              </button>
            </div>
          </div>

          {/* Password Change */}
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <Lock className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Change Password
              </h2>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Current Password
                </label>
                <div className="relative">
                  <input
                    type={showCurrentPassword ? 'text' : 'password'}
                    value={passwordForm.currentPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, currentPassword: e.target.value})}
                    className="input-field pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-text-grey hover:text-text-dark"
                  >
                    {showCurrentPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  New Password
                </label>
                <div className="relative">
                  <input
                    type={showNewPassword ? 'text' : 'password'}
                    value={passwordForm.newPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, newPassword: e.target.value})}
                    className="input-field pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-text-grey hover:text-text-dark"
                  >
                    {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Confirm New Password
                </label>
                <div className="relative">
                  <input
                    type={showConfirmPassword ? 'text' : 'password'}
                    value={passwordForm.confirmPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, confirmPassword: e.target.value})}
                    className="input-field pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-text-grey hover:text-text-dark"
                  >
                    {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
            </div>
            
            <div className="mt-6">
              <button onClick={handlePasswordChange} className="btn-primary flex items-center space-x-2">
                <Key className="w-4 h-4" />
                <span>Change Password</span>
              </button>
            </div>
          </div>

          {/* Notification Settings */}
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <Bell className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Notification Preferences
              </h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">Email Notifications</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Receive notifications via email</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notifications.emailNotifications}
                    onChange={(e) => setNotifications({...notifications, emailNotifications: e.target.checked})}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-sky-blue dark:peer-focus:ring-sky-blue dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-sky-blue"></div>
                </label>
              </div>
              
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">Push Notifications</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Browser push notifications</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notifications.pushNotifications}
                    onChange={(e) => setNotifications({...notifications, pushNotifications: e.target.checked})}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-sky-blue dark:peer-focus:ring-sky-blue dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-sky-blue"></div>
                </label>
              </div>
              
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">SMS Notifications</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Receive text message alerts</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notifications.smsNotifications}
                    onChange={(e) => setNotifications({...notifications, smsNotifications: e.target.checked})}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-sky-blue dark:peer-focus:ring-sky-blue dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-sky-blue"></div>
                </label>
              </div>
              
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">Announcement Alerts</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">New announcements</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notifications.announcementAlerts}
                    onChange={(e) => setNotifications({...notifications, announcementAlerts: e.target.checked})}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-sky-blue dark:peer-focus:ring-sky-blue dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-sky-blue"></div>
                </label>
              </div>
            </div>
            
            <div className="mt-6">
              <button onClick={handleSaveNotifications} className="btn-primary flex items-center space-x-2">
                <Save className="w-4 h-4" />
                <span>Save Notifications</span>
              </button>
            </div>
          </div>
        </div>

        {/* Sidebar Settings */}
        <div className="space-y-6">
          {/* Appearance */}
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <SettingsIcon className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Appearance
              </h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">Theme</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Choose your preferred theme</p>
                </div>
                <button
                  onClick={toggleTheme}
                  className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                >
                  {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
                </button>
              </div>
              
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">Compact Mode</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Reduce spacing</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={system.compactMode}
                    onChange={(e) => setSystem({...system, compactMode: e.target.checked})}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-sky-blue dark:peer-focus:ring-sky-blue dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-sky-blue"></div>
                </label>
              </div>
            </div>
          </div>

          {/* System Settings */}
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <Database className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                System
              </h2>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Timezone
                </label>
                <select
                  value={system.timezone}
                  onChange={(e) => setSystem({...system, timezone: e.target.value})}
                  className="input-field"
                >
                  <option value="UTC">UTC</option>
                  <option value="EST">Eastern Time</option>
                  <option value="PST">Pacific Time</option>
                  <option value="GMT">GMT</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Language
                </label>
                <select
                  value={system.language}
                  onChange={(e) => setSystem({...system, language: e.target.value})}
                  className="input-field"
                >
                  <option value="English">English</option>
                  <option value="Spanish">Spanish</option>
                  <option value="French">French</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Default Page
                </label>
                <select
                  value={system.defaultPage}
                  onChange={(e) => setSystem({...system, defaultPage: e.target.value})}
                  className="input-field"
                >
                  <option value="dashboard">Dashboard</option>
                  <option value="users">Users</option>
                  <option value="attendance">Attendance</option>
                </select>
              </div>
            </div>
            
            <div className="mt-6">
              <button onClick={handleSaveSystem} className="btn-primary flex items-center space-x-2">
                <Save className="w-4 h-4" />
                <span>Save System</span>
              </button>
            </div>
          </div>

          {/* Data Management */}
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <Database className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Data Management
              </h2>
            </div>
            
            <div className="space-y-3">
              <button
                onClick={handleExportData}
                className="w-full btn-outline flex items-center justify-center space-x-2"
              >
                <Download className="w-4 h-4" />
                <span>Export Data</span>
              </button>
              
              <button
                onClick={handleImportData}
                className="w-full btn-outline flex items-center justify-center space-x-2"
              >
                <Upload className="w-4 h-4" />
                <span>Import Data</span>
              </button>
              
              <button
                onClick={handleClearCache}
                className="w-full btn-outline flex items-center justify-center space-x-2"
              >
                <RefreshCw className="w-4 h-4" />
                <span>Clear Cache</span>
              </button>
              
              <button
                onClick={handleResetSettings}
                className="w-full btn-outline flex items-center justify-center space-x-2 text-red-600 border-red-600 hover:bg-red-50 dark:hover:bg-red-900"
              >
                <RefreshCw className="w-4 h-4" />
                <span>Reset Settings</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
