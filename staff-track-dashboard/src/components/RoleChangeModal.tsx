import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import type { User, Role } from '../services/api';
import { usersApi, rolesApi } from '../services/api';
import { X, Shield, AlertTriangle } from 'lucide-react';

interface RoleChangeModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (updatedUser: User) => void;
}

const RoleChangeModal: React.FC<RoleChangeModalProps> = ({
  user,
  isOpen,
  onClose,
  onSuccess
}) => {
  const [roles, setRoles] = useState<Role[]>([]);
  const [selectedRoleId, setSelectedRoleId] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [loadingRoles, setLoadingRoles] = useState(false);
  const { showToast } = useToast();

  useEffect(() => {
    if (isOpen) {
      loadRoles();
      if (user) {
        setSelectedRoleId(user.role_id);
      }
    }
  }, [isOpen, user]);

  const loadRoles = async () => {
    try {
      setLoadingRoles(true);
      const response = await rolesApi.getAllRoles();
      setRoles(response.roles || []);
    } catch (error) {
      console.error('Error loading roles:', error);
      showToast('Failed to load roles', 'error');
    } finally {
      setLoadingRoles(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!user || !selectedRoleId) return;
    
    // Don't submit if role hasn't changed
    if (selectedRoleId === user.role_id) {
      onClose();
      return;
    }

    try {
      setLoading(true);
      
      const response = await usersApi.updateUserRole(user.user_id, selectedRoleId);
      
      if (response.success && response.data) {
        showToast(`Role updated successfully for ${user.first_name} ${user.surname}`, 'success');
        onSuccess(response.data);
        onClose();
      } else {
        showToast(response.message || 'Failed to update role', 'error');
      }
    } catch (error: any) {
      console.error('Error updating user role:', error);
      const errorMessage = error.response?.data?.detail || 'Failed to update user role';
      showToast(errorMessage, 'error');
    } finally {
      setLoading(false);
    }
  };

  const getRoleColor = (roleName: string) => {
    const roleColors = {
      'admin': 'bg-purple-500',
      'administrator': 'bg-purple-500',
      'hr': 'bg-blue-500',
      'manager': 'bg-indigo-500',
      'employee': 'bg-gray-500',
      'staff': 'bg-green-500',
      'doctor': 'bg-red-500',
      'nurse': 'bg-pink-500',
      'system admin': 'bg-red-600',
      'system administrator': 'bg-red-600',
      'principal hospital administrator': 'bg-purple-600',
      'accountant': 'bg-yellow-600',
      'department supervisor': 'bg-indigo-600',
      'medical director': 'bg-teal-600'
    };
    return roleColors[roleName.toLowerCase() as keyof typeof roleColors] || 'bg-sky-blue';
  };

  const getSystemAdminRoles = () => {
    return roles.filter(role => 
      role.name.toLowerCase().includes('system admin') || 
      role.name.toLowerCase().includes('system administrator')
    );
  };

  const getRestrictedRoles = () => {
    const systemAdminRoles = getSystemAdminRoles();
    return roles.filter(role => 
      !systemAdminRoles.some(sar => sar.role_id === role.role_id)
    );
  };

  if (!isOpen || !user) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-md mx-4">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <Shield className="w-5 h-5 text-sky-blue" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Change User Role
              </h2>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Modify role for {user.first_name} {user.surname}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Current User Info */}
          <div className="p-4 bg-gray-50 dark:bg-gray-900 rounded-xl">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-r from-sky-blue to-blue-600 rounded-full flex items-center justify-center">
                <span className="text-white font-semibold text-lg">
                  {user.first_name.charAt(0)}{user.surname.charAt(0)}
                </span>
              </div>
              <div className="flex-1">
                <p className="font-medium text-gray-900 dark:text-white">
                  {user.first_name} {user.surname}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {user.email} • {user.employee_number}
                </p>
                <div className="flex items-center space-x-2 mt-1">
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium text-white ${getRoleColor(user.role_name)}`}>
                    {user.role_name}
                  </span>
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    Current Role
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* System Admin Warning */}
          {getSystemAdminRoles().some(role => role.role_id === selectedRoleId) && (
            <div className="flex items-start space-x-3 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-xl">
              <AlertTriangle className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  System Admin Role
                </p>
                <p className="text-xs text-yellow-700 dark:text-yellow-300 mt-1">
                  This role grants full system access. Only assign to trusted personnel.
                </p>
              </div>
            </div>
          )}

          {/* Role Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Select New Role
            </label>
            {loadingRoles ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-sky-blue"></div>
              </div>
            ) : (
              <div className="space-y-2">
                {/* Regular Roles */}
                {getRestrictedRoles().length > 0 && (
                  <div>
                    <p className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-2">Standard Roles</p>
                    {getRestrictedRoles().map((role) => (
                      <label
                        key={role.role_id}
                        className="flex items-center space-x-3 p-3 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors"
                      >
                        <input
                          type="radio"
                          name="role"
                          value={role.role_id}
                          checked={selectedRoleId === role.role_id}
                          onChange={(e) => setSelectedRoleId(e.target.value)}
                          className="w-4 h-4 text-sky-blue border-gray-300 focus:ring-sky-blue"
                        />
                        <div className="flex items-center space-x-3 flex-1">
                          <div className={`w-8 h-8 ${getRoleColor(role.name)} rounded-lg flex items-center justify-center`}>
                            <Shield className="w-4 h-4 text-white" />
                          </div>
                          <div className="flex-1">
                            <p className="font-medium text-gray-900 dark:text-white capitalize">
                              {role.name}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">
                              {role.description || 'Standard user role'}
                            </p>
                          </div>
                        </div>
                      </label>
                    ))}
                  </div>
                )}

                {/* System Admin Roles */}
                {getSystemAdminRoles().length > 0 && (
                  <div>
                    <p className="text-xs font-medium text-red-500 dark:text-red-400 mb-2">System Administrator Roles</p>
                    {getSystemAdminRoles().map((role) => (
                      <label
                        key={role.role_id}
                        className="flex items-center space-x-3 p-3 border border-red-200 dark:border-red-800 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 cursor-pointer transition-colors"
                      >
                        <input
                          type="radio"
                          name="role"
                          value={role.role_id}
                          checked={selectedRoleId === role.role_id}
                          onChange={(e) => setSelectedRoleId(e.target.value)}
                          className="w-4 h-4 text-red-600 border-red-300 focus:ring-red-500"
                        />
                        <div className="flex items-center space-x-3 flex-1">
                          <div className={`w-8 h-8 ${getRoleColor(role.name)} rounded-lg flex items-center justify-center`}>
                            <Shield className="w-4 h-4 text-white" />
                          </div>
                          <div className="flex-1">
                            <p className="font-medium text-red-700 dark:text-red-300 capitalize">
                              {role.name}
                            </p>
                            <p className="text-xs text-red-600 dark:text-red-400">
                              {role.description || 'Full system administrator access'}
                            </p>
                          </div>
                        </div>
                      </label>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !selectedRoleId || selectedRoleId === user.role_id}
              className="px-4 py-2 bg-sky-blue text-white rounded-lg hover:bg-sky-blue disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center space-x-2"
            >
              {loading && (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              )}
              <span>Update Role</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default RoleChangeModal;
