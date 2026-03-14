import React from 'react';
import { X, Mail, Phone, Calendar, MapPin, User as UserIcon, Shield, Building, Clock } from 'lucide-react';
import type { User } from '../services/api';

interface UserViewModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
}

const UserViewModal: React.FC<UserViewModalProps> = ({ user, isOpen, onClose }) => {
  if (!isOpen || !user) return null;

  const formatDate = (dateString: string | null | undefined) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusBadge = (status: string) => {
    const statusColors = {
      'active': 'status-active',
      'inactive': 'status-inactive',
      'pending': 'status-pending',
      'blacklisted': 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
    };
    
    return (
      <span className={`status-badge ${statusColors[status as keyof typeof statusColors] || statusColors.pending}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const getRoleBadge = (roleName: string) => {
    const roleColors = {
      'admin': 'bg-gradient-to-r from-purple-400 to-purple-600 text-white',
      'hr': 'bg-gradient-to-r from-blue-400 to-blue-600 text-white',
      'manager': 'bg-gradient-to-r from-indigo-400 to-indigo-600 text-white',
      'employee': 'bg-gradient-to-r from-gray-400 to-gray-600 text-white'
    };
    
    return (
      <span className={`status-badge ${roleColors[roleName.toLowerCase() as keyof typeof roleColors] || roleColors.employee}`}>
        {roleName}
      </span>
    );
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="header-gradient p-6 rounded-t-2xl">
          <div className="flex justify-between items-start">
            <div className="flex items-center space-x-4">
              <div className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
                <span className="text-white text-xl font-bold">
                  {user.first_name.charAt(0)}{user.surname.charAt(0)}
                </span>
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white">
                  {user.first_name} {user.surname}
                </h2>
                <p className="text-blue-100">{user.employee_number}</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-white hover:text-blue-100 transition-colors p-2 hover:bg-white hover:bg-opacity-10 rounded-lg"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Basic Info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Basic Information</h3>
              <div className="space-y-3">
                <div className="flex items-center space-x-3">
                  <Mail className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Email:</span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.email}</span>
                </div>
                {user.contact_number && (
                  <div className="flex items-center space-x-3">
                    <Phone className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">Phone:</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.contact_number}</span>
                  </div>
                )}
                {user.date_of_birth && (
                  <div className="flex items-center space-x-3">
                    <Calendar className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">Date of Birth:</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                      {new Date(user.date_of_birth).toLocaleDateString()}
                    </span>
                  </div>
                )}
                {user.gender && (
                  <div className="flex items-center space-x-3">
                    <UserIcon className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">Gender:</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.gender}</span>
                  </div>
                )}
              </div>
            </div>

            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Work Information</h3>
              <div className="space-y-3">
                <div className="flex items-center space-x-3">
                  <Shield className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Role:</span>
                  <span>{getRoleBadge(user.role_name)}</span>
                </div>
                <div className="flex items-center space-x-3">
                  <Building className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Department:</span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                    {user.department_name || 'Unassigned'}
                  </span>
                </div>
                {user.designation && (
                  <div className="flex items-center space-x-3">
                    <UserIcon className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">Designation:</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.designation}</span>
                  </div>
                )}
                {user.date_of_employment && (
                  <div className="flex items-center space-x-3">
                    <Calendar className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-600 dark:text-gray-400">Employment Date:</span>
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                      {new Date(user.date_of_employment).toLocaleDateString()}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Location Info */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Location Information</h3>
            <div className="space-y-3">
              {user.current_address && (
                <div className="flex items-center space-x-3">
                  <MapPin className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Address:</span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.current_address}</span>
                </div>
              )}
              {user.home_of_origin && (
                <div className="flex items-center space-x-3">
                  <MapPin className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Home of Origin:</span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.home_of_origin}</span>
                </div>
              )}
              {user.district && (
                <div className="flex items-center space-x-3">
                  <MapPin className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">District:</span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">{user.district}</span>
                </div>
              )}
            </div>
          </div>

          {/* System Information */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">System Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div className="flex items-center space-x-3">
                <span className="text-sm text-gray-600 dark:text-gray-400">Status:</span>
                <span>{getStatusBadge(user.status)}</span>
              </div>
              <div className="flex items-center space-x-3">
                <Clock className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-600 dark:text-gray-400">Last Login:</span>
                <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {formatDate(user.last_login_at)}
                </span>
              </div>
              <div className="flex items-center space-x-3">
                <Calendar className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-600 dark:text-gray-400">Registration Date:</span>
                <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {formatDate(user.created_at)}
                </span>
              </div>
              <div className="flex items-center space-x-3">
                <Shield className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-600 dark:text-gray-400">Head of Department:</span>
                <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {user.is_head_of_department ? 'Yes' : 'No'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserViewModal;
