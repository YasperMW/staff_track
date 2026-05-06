import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import type { User } from '../services/api';
import { usersApi } from '../services/api';
import DataTable from '../components/DataTable';
import UserEditModal from '../components/UserEditModal';
import RoleChangeModal from '../components/RoleChangeModal';
import type { Column, Action } from '../components/DataTable';
import { UserPlus, Edit, Trash2, Eye, Shield, UserCheck, UserX, Key, AlertTriangle } from 'lucide-react';
import { useSystemAdmin } from '../hooks/useSystemAdmin';
import { useToast } from '../contexts/ToastContext';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isRoleModalOpen, setIsRoleModalOpen] = useState(false);
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });

  const navigate = useNavigate();
  const { isSystemAdmin } = useSystemAdmin();
  const { success, error, info } = useToast();

  useEffect(() => {
    loadUsers();
  }, [pagination.page, pagination.perPage]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await usersApi.getActiveUsers();
      console.log('API Response:', response);
      console.log('Response users:', response.users);
      console.log('Response total:', response.total_count);
      setUsers(response.users || []);
      setPagination(prev => ({ ...prev, total: response.total_count || 0 }));
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setIsEditModalOpen(true);
  };

  const handleDeleteUser = (user: User) => {
    setUserToDelete(user);
    setIsDeleteConfirmOpen(true);
  };

  const confirmDeleteUser = async () => {
    if (!userToDelete) return;
    try {
      await usersApi.deleteUser(userToDelete.user_id);
      success(`User "${userToDelete.first_name} ${userToDelete.surname}" deleted successfully`);
      setIsDeleteConfirmOpen(false);
      setUserToDelete(null);
      loadUsers();
    } catch (err: any) {
      error(`Failed to delete user: ${err.response?.data?.message || err.message}`);
    }
  };

  const handleViewUser = (user: User) => {
    navigate(`/users/${user.user_id}`);
  };

  const handleToggleUserStatus = async (user: User) => {
    const newStatus = user.status === 'active' ? 'inactive' : 'active';
    const action = newStatus === 'active' ? 'activate' : 'deactivate';
    try {
      await usersApi.updateUser(user.user_id, { status: newStatus });
      success(`User "${user.first_name} ${user.surname}" ${action}d successfully`);
      loadUsers();
    } catch (err: any) {
      error(`Failed to ${action} user: ${err.response?.data?.message || err.message}`);
    }
  };

  const handleAddUser = () => {
    setSelectedUser(null);
    setIsAddModalOpen(true);
  };

  const handleUserSave = (updatedUser: User) => {
    // Update the user in the local state
    setUsers(prev => prev.map(user => 
      user.user_id === updatedUser.user_id ? updatedUser : user
    ));
    setIsEditModalOpen(false);
    setSelectedUser(null);
  };

  const handleCloseModal = () => {
    setIsEditModalOpen(false);
    setSelectedUser(null);
  };

  const handleChangeRole = (user: User) => {
    setSelectedUser(user);
    setIsRoleModalOpen(true);
  };

  const handleRoleChangeSuccess = (updatedUser: User) => {
    // Update the user in the local state
    setUsers(prev => prev.map(user => 
      user.user_id === updatedUser.user_id ? updatedUser : user
    ));
    setIsRoleModalOpen(false);
    setSelectedUser(null);
  };

  const handleCloseRoleModal = () => {
    setIsRoleModalOpen(false);
    setSelectedUser(null);
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

  const getUserInitials = (firstName: string, surname: string) => {
    return `${firstName.charAt(0)}${surname.charAt(0)}`.toUpperCase();
  };

  const columns: Column<User>[] = [
    {
      key: 'employee_number',
      label: 'Employee ID',
      sortable: true,
      filterable: true,
      width: '120px'
    },
    {
      key: 'first_name',
      label: 'Name',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 avatar-gradient rounded-full flex items-center justify-center">
            <span className="text-white text-sm font-semibold">
              {getUserInitials(row.first_name, row.surname)}
            </span>
          </div>
          <div>
            <p className="font-medium text-text-dark dark:text-text-dark-light">
              {row.first_name} {row.surname}
            </p>
            <p className="text-sm text-text-grey dark:text-text-grey-dark">
              {row.email}
            </p>
          </div>
        </div>
      )
    },
    {
      key: 'department_name',
      label: 'Department',
      sortable: true,
      filterable: true,
      render: (value) => (
        <span className="text-sm text-text-dark dark:text-text-dark-light">
          {value || 'Unassigned'}
        </span>
      )
    },
    {
      key: 'designation',
      label: 'Designation',
      sortable: true,
      filterable: true,
      render: (value) => (
        <span className="text-sm text-text-grey dark:text-text-grey-dark">
          {value || 'N/A'}
        </span>
      )
    },
    {
      key: 'role_name',
      label: 'Role',
      sortable: true,
      filterable: true,
      render: (value) => {
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
        
        const roleColor = roleColors[value?.toLowerCase() as keyof typeof roleColors] || 'bg-sky-blue';
        
        return (
          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium text-white ${roleColor}`}>
            {value || 'Unknown'}
          </span>
        );
      }
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      filterable: true,
      render: (value) => getStatusBadge(value as string)
    },
    {
      key: 'last_login_at',
      label: 'Last Login',
      sortable: true,
      render: (value) => (
        <span className="text-sm text-text-grey dark:text-text-grey-dark">
          {value ? new Date(value).toLocaleDateString() : 'Never'}
        </span>
      )
    }
  ];

  const actions: Action<User>[] = [
    {
      label: 'View',
      icon: <Eye className="w-4 h-4" />,
      onClick: handleViewUser,
      variant: 'primary'
    },
    ...(isSystemAdmin ? [{
      label: 'Change Role',
      icon: <Key className="w-4 h-4" />,
      onClick: handleChangeRole,
      variant: 'secondary' as const
    }] : []),
    {
      label: row => row.status === 'active' ? 'Deactivate' : 'Activate',
      icon: row => row.status === 'active' ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />,
      onClick: handleToggleUserStatus,
      variant: 'secondary'
    }
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            User Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage system users, roles, and permissions
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => navigate('/roles')}
            className="btn-outline flex items-center space-x-2"
          >
            <Shield className="w-4 h-4" />
            <span>Manage Roles</span>
          </button>
          <button 
            onClick={handleAddUser}
            className="btn-primary flex items-center space-x-2"
          >
            <UserPlus className="w-4 h-4" />
            <span>Add User</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Users</p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {users.length}
              </p>
            </div>
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <UserPlus className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Active</p>
              <p className="text-2xl font-bold text-green-600">
                {users.filter(u => u.status === 'active').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
              <UserCheck className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Inactive</p>
              <p className="text-2xl font-bold text-red-600">
                {users.filter(u => u.status === 'inactive').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-xl flex items-center justify-center">
              <UserX className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Admins</p>
              <p className="text-2xl font-bold text-purple-600">
                {users.filter(u => u.role_name.toLowerCase() === 'admin').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <Shield className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <DataTable
        data={users}
        columns={columns}
        actions={actions}
        loading={loading}
        pagination={{
          ...pagination,
          onPageChange: (page) => setPagination(prev => ({ ...prev, page })),
          onPerPageChange: (perPage) => setPagination(prev => ({ ...prev, perPage, page: 1 }))
        }}
        emptyMessage="No users found. Create your first user to get started."
      />

      {/* User Edit Modal */}
      <UserEditModal
        user={selectedUser}
        isOpen={isEditModalOpen}
        onClose={handleCloseModal}
        onSave={handleUserSave}
      />

      {/* Add User Modal */}
      <UserEditModal
        user={null}
        isOpen={isAddModalOpen}
        onClose={() => {
          setIsAddModalOpen(false);
          setSelectedUser(null);
        }}
        onSave={(newUser) => {
          success(`User "${newUser.first_name} ${newUser.surname}" created successfully`);
          setIsAddModalOpen(false);
          loadUsers();
        }}
      />

      {/* Role Change Modal - Only for System Admins */}
      {isSystemAdmin && (
        <RoleChangeModal
          user={selectedUser}
          isOpen={isRoleModalOpen}
          onClose={handleCloseRoleModal}
          onSuccess={handleRoleChangeSuccess}
        />
      )}

      {/* Delete Confirmation Modal */}
      {isDeleteConfirmOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center">
                <AlertTriangle className="w-6 h-6 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                  Delete User
                </h3>
                <p className="text-sm text-text-grey dark:text-text-grey-dark">
                  This action cannot be undone
                </p>
              </div>
            </div>
            <p className="mb-4 text-text-dark dark:text-text-dark-light">
              Are you sure you want to delete user <span className="font-semibold">
                {userToDelete?.first_name} {userToDelete?.surname}
              </span>?
            </p>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setIsDeleteConfirmOpen(false);
                  setUserToDelete(null);
                }}
                className="btn-outline"
              >
                Cancel
              </button>
              <button
                onClick={confirmDeleteUser}
                className="btn-danger"
              >
                Delete User
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
