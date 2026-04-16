import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import { useTheme } from '../contexts/ThemeContext';
import { usersApi, shiftConfigurationsApi } from '../services/api';
import type { ShiftConfiguration, ShiftConfigurationUpdate } from '../services/api';
import { 
  Settings as SettingsIcon, 
  User, 
  Bell, 
  Database, 
  Moon, 
  Sun, 
  Save,
  RefreshCw,
  Download,
  Upload,
  Key,
  Lock,
  Eye,
  EyeOff,
  Clock,
  Edit2,
  Trash2
} from 'lucide-react';

const Settings: React.FC = () => {
  const { success, error, warning, info } = useToast();
  const { theme, toggleTheme } = useTheme();
  
  // Profile Settings
  const [profile, setProfile] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    department: '',
    role: '',
    employeeNumber: '',
    status: '',
    profilePhotoUrl: '',
    lastLoginAt: ''
  });

  // Loading state
  const [loading, setLoading] = useState(true);

  // Shift Configurations
  const [shiftConfigurations, setShiftConfigurations] = useState<ShiftConfiguration[]>([]);
  const [shiftConfigLoading, setShiftConfigLoading] = useState(false);
  const [editingShift, setEditingShift] = useState<ShiftConfiguration | null>(null);
  const [shiftForm, setShiftForm] = useState<ShiftConfigurationUpdate>({});

  // Load profile data and shift configurations on component mount
  useEffect(() => {
    loadProfileData();
    loadShiftConfigurations();
  }, []);

  const loadProfileData = async () => {
    try {
      setLoading(true);
      const profileData = await usersApi.getCurrentUserProfile();
      console.log('Profile data:', profileData);
      
      setProfile({
        firstName: profileData.first_name || '',
        lastName: profileData.surname || '',
        email: profileData.email || '',
        phone: profileData.phone || '',
        department: profileData.department_name || '',
        role: profileData.role_name || '',
        employeeNumber: profileData.employee_number || '',
        status: profileData.status || '',
        profilePhotoUrl: profileData.profile_photo_url || '',
        lastLoginAt: profileData.last_login_at || ''
      });
      
    } catch (err: any) {
      console.error('Error loading profile data:', err);
      error('Failed to load profile data');
    } finally {
      setLoading(false);
    }
  };

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

  // System Settings
  const [system, setSystem] = useState({
    timezone: 'UTC',
    language: 'English',
    dateFormat: 'MM/DD/YYYY',
    timeFormat: '12-hour',
    defaultPage: 'dashboard',
    autoSave: true
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

  const handleSaveProfile = async () => {
    try {
      // TODO: Implement profile update API call
      console.log('Saving profile data:', profile);
      success('Profile settings saved successfully');
    } catch (err: any) {
      console.error('Error saving profile:', err);
      error('Failed to save profile settings');
    }
  };

  const handleSaveNotifications = () => {
    success('Notification preferences updated');
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

  // Shift Configuration Functions
  const loadShiftConfigurations = async () => {
    try {
      setShiftConfigLoading(true);
      const configs = await shiftConfigurationsApi.getAll();
      setShiftConfigurations(configs);
    } catch (err: any) {
      console.error('Error loading shift configurations:', err);
      error('Failed to load shift configurations');
    } finally {
      setShiftConfigLoading(false);
    }
  };

  const handleEditShift = (config: ShiftConfiguration) => {
    setEditingShift(config);
    setShiftForm({
      shift_name: config.shift_name,
      check_in_earliest: config.check_in_earliest,
      check_in_latest: config.check_in_latest,
      official_start_time: config.official_start_time,
      check_out_earliest: config.check_out_earliest,
      check_out_latest: config.check_out_latest,
      official_end_time: config.official_end_time,
      extended_start_time: config.extended_start_time,
      late_threshold: config.late_threshold,
      is_active: config.is_active,
      description: config.description
    });
  };

  const handleSaveShift = async () => {
    if (!editingShift) return;

    try {
      setShiftConfigLoading(true);
      await shiftConfigurationsApi.update(editingShift.shift_config_id, shiftForm);
      success('Shift configuration updated successfully');
      setEditingShift(null);
      setShiftForm({});
      loadShiftConfigurations();
    } catch (err: any) {
      console.error('Error updating shift configuration:', err);
      error('Failed to update shift configuration');
    } finally {
      setShiftConfigLoading(false);
    }
  };

  const handleCancelEdit = () => {
    setEditingShift(null);
    setShiftForm({});
  };

  const handleDeleteShift = async (config: ShiftConfiguration) => {
    if (!confirm(`Are you sure you want to delete the "${config.shift_name}" configuration?`)) {
      return;
    }

    try {
      setShiftConfigLoading(true);
      await shiftConfigurationsApi.delete(config.shift_config_id);
      success('Shift configuration deleted successfully');
      loadShiftConfigurations();
    } catch (err: any) {
      console.error('Error deleting shift configuration:', err);
      error('Failed to delete shift configuration');
    } finally {
      setShiftConfigLoading(false);
    }
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
              {loading && <RefreshCw className="w-4 h-4 animate-spin text-text-grey" />}
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Employee Number
                </label>
                <input
                  type="text"
                  value={profile.employeeNumber}
                  disabled
                  className="input-field bg-gray-100 dark:bg-gray-800"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Status
                </label>
                <input
                  type="text"
                  value={profile.status}
                  disabled
                  className="input-field bg-gray-100 dark:bg-gray-800"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  First Name
                </label>
                <input
                  type="text"
                  value={profile.firstName}
                  onChange={(e) => setProfile({...profile, firstName: e.target.value})}
                  disabled={loading}
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
                  disabled={loading}
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
                  disabled={loading}
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
                  disabled={loading}
                  className="input-field"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                  Department
                </label>
                <input
                  type="text"
                  value={profile.department}
                  disabled
                  className="input-field bg-gray-100 dark:bg-gray-800"
                />
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
              <button 
                onClick={handleSaveProfile} 
                disabled={loading}
                className="btn-primary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Save className="w-4 h-4" />
                <span>{loading ? 'Loading...' : 'Save Profile'}</span>
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

          {/* Shift Configuration Management - HR Admin Only */}
          {(profile.role === 'HR Admin' || profile.role === 'System Admin') && (
          <div className="card">
            <div className="flex items-center space-x-3 mb-6">
              <Clock className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Shift Configuration Management
              </h2>
              {shiftConfigLoading && <RefreshCw className="w-4 h-4 animate-spin text-text-grey" />}
            </div>
            
            {/* Current Configurations */}
            <div className="space-y-4 mb-6">
              {shiftConfigurations.map((config) => (
                <div key={config.shift_config_id} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                  <div className="flex justify-between items-start mb-3">
                    <div>
                      <h3 className="font-medium text-text-dark dark:text-text-dark-light">
                        {config.shift_name}
                      </h3>
                      <p className="text-sm text-text-grey dark:text-text-grey-dark">
                        {config.shift_type} {config.is_active ? '(Active)' : '(Inactive)'}
                      </p>
                      {config.description && (
                        <p className="text-sm text-text-grey dark:text-text-grey-dark mt-1">
                          {config.description}
                        </p>
                      )}
                    </div>
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleEditShift(config)}
                        className="p-1 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900 rounded"
                        title="Edit"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDeleteShift(config)}
                        className="p-1 text-red-600 hover:bg-red-50 dark:hover:bg-red-900 rounded"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="font-medium text-text-grey dark:text-text-grey-dark">Check-in:</span>
                      <span className="ml-2 text-text-dark dark:text-text-dark-light">
                        {config.check_in_earliest} - {config.check_in_latest}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium text-text-grey dark:text-text-grey-dark">Check-out:</span>
                      <span className="ml-2 text-text-dark dark:text-text-dark-light">
                        {config.check_out_earliest} - {config.check_out_latest}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium text-text-grey dark:text-text-grey-dark">Official Hours:</span>
                      <span className="ml-2 text-text-dark dark:text-text-dark-light">
                        {config.official_start_time} - {config.official_end_time}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium text-text-grey dark:text-text-grey-dark">Extended After:</span>
                      <span className="ml-2 text-text-dark dark:text-text-dark-light">
                        {config.extended_start_time}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Edit Form */}
            {editingShift && (
              <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                <h3 className="font-medium text-text-dark dark:text-text-dark-light mb-4">
                  Edit {editingShift.shift_name}
                </h3>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Configuration Name
                    </label>
                    <input
                      type="text"
                      value={shiftForm.shift_name || ''}
                      onChange={(e) => setShiftForm({...shiftForm, shift_name: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Status
                    </label>
                    <select
                      value={shiftForm.is_active?.toString() || 'true'}
                      onChange={(e) => setShiftForm({...shiftForm, is_active: e.target.value === 'true'})}
                      className="input-field"
                    >
                      <option value="true">Active</option>
                      <option value="false">Inactive</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Check-in Earliest
                    </label>
                    <input
                      type="time"
                      value={shiftForm.check_in_earliest || ''}
                      onChange={(e) => setShiftForm({...shiftForm, check_in_earliest: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Check-in Latest
                    </label>
                    <input
                      type="time"
                      value={shiftForm.check_in_latest || ''}
                      onChange={(e) => setShiftForm({...shiftForm, check_in_latest: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Official Start Time
                    </label>
                    <input
                      type="time"
                      value={shiftForm.official_start_time || ''}
                      onChange={(e) => setShiftForm({...shiftForm, official_start_time: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Official End Time
                    </label>
                    <input
                      type="time"
                      value={shiftForm.official_end_time || ''}
                      onChange={(e) => setShiftForm({...shiftForm, official_end_time: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Check-out Earliest
                    </label>
                    <input
                      type="time"
                      value={shiftForm.check_out_earliest || ''}
                      onChange={(e) => setShiftForm({...shiftForm, check_out_earliest: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Check-out Latest
                    </label>
                    <input
                      type="time"
                      value={shiftForm.check_out_latest || ''}
                      onChange={(e) => setShiftForm({...shiftForm, check_out_latest: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Extended Start Time
                    </label>
                    <input
                      type="time"
                      value={shiftForm.extended_start_time || ''}
                      onChange={(e) => setShiftForm({...shiftForm, extended_start_time: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Late Threshold
                    </label>
                    <input
                      type="time"
                      value={shiftForm.late_threshold || ''}
                      onChange={(e) => setShiftForm({...shiftForm, late_threshold: e.target.value})}
                      className="input-field"
                    />
                  </div>
                  
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                      Description
                    </label>
                    <textarea
                      value={shiftForm.description || ''}
                      onChange={(e) => setShiftForm({...shiftForm, description: e.target.value})}
                      rows={3}
                      className="input-field"
                    />
                  </div>
                </div>
                
                <div className="flex space-x-3 mt-6">
                  <button 
                    onClick={handleSaveShift}
                    disabled={shiftConfigLoading}
                    className="btn-primary flex items-center space-x-2 disabled:opacity-50"
                  >
                    <Save className="w-4 h-4" />
                    <span>{shiftConfigLoading ? 'Saving...' : 'Save Changes'}</span>
                  </button>
                  <button 
                    onClick={handleCancelEdit}
                    className="btn-outline"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}
          </div>
          )}
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
