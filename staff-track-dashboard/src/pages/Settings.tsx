import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import { useTheme } from '../contexts/ThemeContext';
import { useAuth } from '../contexts/AuthContext';
import { usersApi, shiftConfigurationsApi } from '../services/api';
import type { ShiftConfiguration, ShiftConfigurationUpdate } from '../services/api';
import { useRef } from 'react';
import {
  Settings as SettingsIcon,
  User,
  Moon,
  Sun,
  Save,
  RefreshCw,
  Key,
  Lock,
  Eye,
  EyeOff,
  Clock,
  Edit2,
  Trash2,
  Mail,
  Phone,
  Briefcase,
  Camera,
  Users,
} from 'lucide-react';

const Settings: React.FC = () => {
  const { success, error } = useToast();
  const { theme, toggleTheme } = useTheme();
  const { user } = useAuth();

  const [activeTab, setActiveTab] = useState<'account' | 'preferences' | 'security'>('account');

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
    lastLoginAt: '',
    bio: '',
    joinDate: '',
    position: ''
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
        lastLoginAt: profileData.last_login_at || '',
        bio: 'Dedicated healthcare professional with years of experience in hospital management systems.',
        joinDate: profileData.created_at || '2020-03-15',
        position: profileData.role_name || 'Staff Member'
      });

    } catch (err: any) {
      console.error('Error loading profile data:', err);
      error('Failed to load profile data');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveProfile = async () => {
    try {
      await usersApi.updateUser(user?.user_id || '', {
        first_name: profile.firstName,
        surname: profile.lastName,
        phone: profile.phone
      });
      success('Profile settings saved successfully');
      loadProfileData();
    } catch (err: any) {
      console.error('Error saving profile:', err);
      error(err.response?.data?.message || 'Failed to save profile settings');
    }
  };

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
  const [showPasswordForm, setShowPasswordForm] = useState(false);

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

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleAvatarUpload = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      error('Please select an image file');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      error('Image file size must be less than 5MB');
      return;
    }

    try {
      const imageUrl = URL.createObjectURL(file);
      setProfile(prev => ({ ...prev, profilePhotoUrl: imageUrl }));
      success('Avatar updated successfully');
    } catch (err: any) {
      error('Failed to upload avatar');
    }

    if (e.target) e.target.value = '';
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

      {/* Profile Header Card */}
      <div className="card">
        <div className="flex flex-col md:flex-row items-center md:items-start space-y-4 md:space-y-0 md:space-x-6">
          {/* Avatar */}
          <div className="relative">
            <div className="w-20 h-20 bg-sky-blue rounded-full flex items-center justify-center overflow-hidden">
              {profile.profilePhotoUrl ? (
                <img src={profile.profilePhotoUrl} alt="Profile" className="w-full h-full rounded-full object-cover" />
              ) : (
                <span className="text-white text-2xl font-bold">
                  {profile.firstName.charAt(0)}{profile.lastName.charAt(0)}
                </span>
              )}
            </div>
            <button
              onClick={handleAvatarUpload}
              className="absolute bottom-0 right-0 w-8 h-8 bg-white dark:bg-gray-800 rounded-full flex items-center justify-center shadow-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              <Camera className="w-4 h-4 text-gray-600 dark:text-gray-400" />
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleAvatarChange}
              className="hidden"
            />
          </div>

          {/* Basic Info */}
          <div className="flex-1 text-center md:text-left">
            <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">
              {profile.firstName} {profile.lastName}
            </h2>
            <p className="text-text-grey dark:text-text-grey-dark mb-2">
              {profile.position}
            </p>
            <div className="flex flex-wrap justify-center md:justify-start gap-4 text-sm">
              <div className="flex items-center space-x-1 text-text-grey dark:text-text-grey-dark">
                <Briefcase className="w-4 h-4" />
                <span>{profile.department}</span>
              </div>
              <div className="flex items-center space-x-1 text-text-grey dark:text-text-grey-dark">
                <Users className="w-4 h-4" />
                <span>{profile.role}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="flex space-x-8">
          {(['account', 'preferences', 'security'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab
                  ? 'border-sky-blue text-sky-blue'
                  : 'border-transparent text-text-grey dark:text-text-grey-dark hover:text-text-dark dark:hover:text-text-dark-light'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="space-y-6">
        {/* Account Tab */}
        {activeTab === 'account' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Contact Information */}
            <div className="card">
              <div className="flex items-center space-x-3 mb-6">
                <User className="w-5 h-5 text-sky-blue" />
                <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                  Contact Information
                </h2>
                {loading && <RefreshCw className="w-4 h-4 animate-spin text-text-grey" />}
              </div>

              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <Mail className="w-5 h-5 text-text-grey dark:text-text-grey-dark" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">Email</p>
                    <input
                      type="email"
                      value={profile.email}
                      readOnly
                      className="input-field bg-gray-50 dark:bg-gray-800 cursor-not-allowed"
                    />
                  </div>
                </div>
                <div className="flex items-center space-x-3">
                  <Phone className="w-5 h-5 text-text-grey dark:text-text-grey-dark" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">Phone</p>
                    <input
                      type="tel"
                      value={profile.phone}
                      onChange={(e) => setProfile({...profile, phone: e.target.value})}
                      disabled={loading}
                      className="input-field"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Employment Details */}
            <div className="card">
              <div className="flex items-center space-x-3 mb-6">
                <Briefcase className="w-5 h-5 text-sky-blue" />
                <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                  Employment Details
                </h2>
              </div>

              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Employee Number</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.employeeNumber}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Department</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.department}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Role</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.role}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Status</span>
                  <span className="text-sm font-medium text-green-600">{profile.status}</span>
                </div>
              </div>
            </div>

            {/* Personal Info */}
            <div className="card lg:col-span-2">
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Personal Information
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          </div>
        )}

        {/* Preferences Tab */}
        {activeTab === 'preferences' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-6">
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
                          </div>
                          <div className="flex space-x-2">
                            <button onClick={() => handleEditShift(config)} className="p-1 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900 rounded">
                              <Edit2 className="w-4 h-4" />
                            </button>
                            <button onClick={() => handleDeleteShift(config)} className="p-1 text-red-600 hover:bg-red-50 dark:hover:bg-red-900 rounded">
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <div><span className="text-text-grey">Check-in:</span> {config.check_in_earliest} - {config.check_in_latest}</div>
                          <div><span className="text-text-grey">Check-out:</span> {config.check_out_earliest} - {config.check_out_latest}</div>
                        </div>
                      </div>
                    ))}
                  </div>

                  {editingShift && (
                    <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                      <h3 className="font-medium text-text-dark dark:text-text-dark-light mb-4">
                        Edit {editingShift.shift_name}
                      </h3>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium mb-2">Configuration Name</label>
                          <input type="text" value={shiftForm.shift_name || ''} onChange={(e) => setShiftForm({...shiftForm, shift_name: e.target.value})} className="input-field" />
                        </div>
                        <div>
                          <label className="block text-sm font-medium mb-2">Status</label>
                          <select value={shiftForm.is_active?.toString() || 'true'} onChange={(e) => setShiftForm({...shiftForm, is_active: e.target.value === 'true'})} className="input-field">
                            <option value="true">Active</option>
                            <option value="false">Inactive</option>
                          </select>
                        </div>
                      </div>
                      <div className="flex space-x-3 mt-6">
                        <button onClick={handleSaveShift} disabled={shiftConfigLoading} className="btn-primary flex items-center space-x-2 disabled:opacity-50">
                          <Save className="w-4 h-4" />
                          <span>{shiftConfigLoading ? 'Saving...' : 'Save Changes'}</span>
                        </button>
                        <button onClick={handleCancelEdit} className="btn-outline">Cancel</button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              {/* Appearance */}
              <div className="card">
                <div className="flex items-center space-x-3 mb-6">
                  <SettingsIcon className="w-5 h-5 text-sky-blue" />
                  <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                    Appearance
                  </h2>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-text-dark dark:text-text-dark-light">Theme</p>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark">Choose your preferred theme</p>
                  </div>
                  <button onClick={toggleTheme} className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                    {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Security Tab */}
        {activeTab === 'security' && (
          <div className="max-w-2xl space-y-6">
            <div className="card">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <Lock className="w-5 h-5 text-sky-blue" />
                  <div>
                    <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                      Change Password
                    </h2>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark">
                      Update your password to keep your account secure
                    </p>
                  </div>
                </div>
                {!showPasswordForm && (
                  <button
                    onClick={() => setShowPasswordForm(true)}
                    className="btn-primary flex items-center space-x-2"
                  >
                    <Key className="w-4 h-4" />
                    <span>Change Password</span>
                  </button>
                )}
              </div>

              {showPasswordForm && (
                <div className="mt-6 space-y-4">
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

                  <div className="flex space-x-3 pt-4">
                    <button onClick={handlePasswordChange} className="btn-primary flex items-center space-x-2">
                      <Key className="w-4 h-4" />
                      <span>Change Password</span>
                    </button>
                    <button
                      onClick={() => {
                        setShowPasswordForm(false);
                        setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
                      }}
                      className="btn-outline"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Settings;
