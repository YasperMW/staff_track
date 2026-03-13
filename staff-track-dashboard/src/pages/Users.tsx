import React, { useState, useEffect } from 'react';
import type { User } from '../services/api';
import { usersApi } from '../services/api';
import DataTable from '../components/DataTable';
import UserEditModal from '../components/UserEditModal';
import type { Column, Action } from '../components/DataTable';
import { UserPlus, Edit, Trash2, Eye, Shield, UserCheck, UserX } from 'lucide-react';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });

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
    console.log('Delete user:', user);
    // TODO: Show confirmation dialog
  };

  const handleViewUser = (user: User) => {
    console.log('View user:', user);
    // TODO: Open user details modal
  };

  const handleToggleUserStatus = (user: User) => {
    console.log('Toggle status:', user);
    // TODO: Toggle active/inactive status
  };

  const handleAddUser = () => {
    console.log('Add new user');
    // TODO: Open add user modal
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

  const getStatusBadge = (status: string) => {
    const statusColors = {
      'active': 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      'inactive': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
      'pending': 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
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
      'admin': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
      'hr': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
      'manager': 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200',
      'employee': 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
    };
    
    return (
      <span className={`status-badge ${roleColors[roleName.toLowerCase() as keyof typeof roleColors] || roleColors.employee}`}>
        {roleName}
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
          <div className="w-8 h-8 bg-sky-blue rounded-full flex items-center justify-center">
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
      key: 'role_name',
      label: 'Role',
      sortable: true,
      filterable: true,
      render: (value) => getRoleBadge(value as string)
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
    {
      label: 'Edit',
      icon: <Edit className="w-4 h-4" />,
      onClick: handleEditUser,
      variant: 'secondary'
    },
    {
      label: row => row.status === 'active' ? 'Deactivate' : 'Activate',
      icon: row => row.status === 'active' ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />,
      onClick: handleToggleUserStatus,
      variant: 'secondary'
    },
    {
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteUser,
      variant: 'danger'
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
          <button className="btn-outline flex items-center space-x-2">
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
    </div>
  );
};

export default Users;
