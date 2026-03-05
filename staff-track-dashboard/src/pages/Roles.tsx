import React, { useState, useEffect } from 'react';
import type { Role } from '../services/api';
import { rolesApi } from '../services/api';
import DataTable from '../components/DataTable';
import type { Column, Action } from '../components/DataTable';
import { Plus, Shield, Edit, Trash2, Eye, Users, Key, Settings } from 'lucide-react';

const Roles: React.FC = () => {
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });

  useEffect(() => {
    loadRoles();
  }, [pagination.page, pagination.perPage]);

  const loadRoles = async () => {
    try {
      setLoading(true);
      const response = await rolesApi.getAllRoles();
      setRoles(response.items || []);
      setPagination(prev => ({ ...prev, total: response.total_count || 0 }));
    } catch (error) {
      console.error('Error loading roles:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEditRole = (role: Role) => {
    console.log('Edit role:', role);
    // TODO: Open edit modal
  };

  const handleDeleteRole = (role: Role) => {
    console.log('Delete role:', role);
    // TODO: Show confirmation dialog
  };

  const handleViewRole = (role: Role) => {
    console.log('View role:', role);
    // TODO: Open role details modal
  };

  const handleManagePermissions = (role: Role) => {
    console.log('Manage permissions:', role);
    // TODO: Open permissions management modal
  };

  const handleAddRole = () => {
    console.log('Add new role');
    // TODO: Open add role modal
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
      'nurse': 'bg-pink-500'
    };
    return roleColors[roleName.toLowerCase() as keyof typeof roleColors] || 'bg-sky-blue';
  };

  const getRoleIcon = (roleName: string) => {
    const roleIcons = {
      'admin': <Shield className="w-5 h-5" />,
      'administrator': <Shield className="w-5 h-5" />,
      'hr': <Users className="w-5 h-5" />,
      'manager': <Settings className="w-5 h-5" />,
      'employee': <Users className="w-5 h-5" />,
      'staff': <Users className="w-5 h-5" />,
      'doctor': <Shield className="w-5 h-5" />,
      'nurse': <Users className="w-5 h-5" />
    };
    return roleIcons[roleName.toLowerCase() as keyof typeof roleIcons] || <Key className="w-5 h-5" />;
  };

  const getRoleLevel = (roleName: string) => {
    const levels = {
      'admin': 1,
      'administrator': 1,
      'hr': 2,
      'manager': 3,
      'doctor': 3,
      'nurse': 4,
      'employee': 5,
      'staff': 5
    };
    return levels[roleName.toLowerCase() as keyof typeof levels] || 5;
  };

  const columns: Column<Role>[] = [
    {
      key: 'name',
      label: 'Role',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="flex items-center space-x-3">
          <div className={`w-10 h-10 ${getRoleColor(row.name)} rounded-xl flex items-center justify-center`}>
            <span className="text-white">
              {getRoleIcon(row.name)}
            </span>
          </div>
          <div>
            <p className="font-medium text-text-dark dark:text-text-dark-light capitalize">
              {row.name}
            </p>
            <p className="text-sm text-text-grey dark:text-text-grey-dark">
              Level {getRoleLevel(row.name)} access
            </p>
          </div>
        </div>
      )
    },
    {
      key: 'created_at',
      label: 'Created',
      sortable: true,
      filterable: false,
      render: (value) => (
        <span className="text-sm text-text-grey dark:text-text-grey-dark">
          {value ? new Date(value).toLocaleDateString() : 'N/A'}
        </span>
      )
    }
  ];

  const actions: Action<Role>[] = [
    {
      label: 'View',
      icon: <Eye className="w-4 h-4" />,
      onClick: handleViewRole,
      variant: 'primary'
    },
    {
      label: 'Edit',
      icon: <Edit className="w-4 h-4" />,
      onClick: handleEditRole,
      variant: 'secondary'
    },
    {
      label: 'Manage Permissions',
      icon: <Key className="w-4 h-4" />,
      onClick: handleManagePermissions,
      variant: 'secondary'
    },
    {
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteRole,
      variant: 'danger'
    }
  ];

  // Calculate statistics
  const adminRoles = roles.filter(role => 
    role.name.toLowerCase().includes('admin') || 
    role.name.toLowerCase().includes('administrator')
  ).length;
  const staffRoles = roles.filter(role => 
    role.name.toLowerCase().includes('staff') || 
    role.name.toLowerCase().includes('employee')
  ).length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Roles & Permissions
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage user roles and access permissions
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <button className="btn-outline flex items-center space-x-2">
            <Key className="w-4 h-4" />
            <span>Permission Matrix</span>
          </button>
          <button 
            onClick={handleAddRole}
            className="btn-primary flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Role</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Roles</p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {roles.length}
              </p>
            </div>
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <Shield className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Admin Roles</p>
              <p className="text-2xl font-bold text-purple-600">
                {adminRoles}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <Shield className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Staff Roles</p>
              <p className="text-2xl font-bold text-green-600">
                {staffRoles}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Specialized</p>
              <p className="text-2xl font-bold text-light-gold">
                {roles.length - adminRoles - staffRoles}
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-xl flex items-center justify-center">
              <Settings className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Role Hierarchy */}
      <div className="card">
        <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
          Role Hierarchy
        </h3>
        <div className="space-y-3">
          {roles
            .sort((a, b) => getRoleLevel(a.name) - getRoleLevel(b.name))
            .map((role) => (
              <div key={role.role_id} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
                <div className="flex items-center space-x-3">
                  <div className={`w-8 h-8 ${getRoleColor(role.name)} rounded-lg flex items-center justify-center`}>
                    <span className="text-white text-sm">
                      {getRoleIcon(role.name)}
                    </span>
                  </div>
                  <div>
                    <p className="font-medium text-text-dark dark:text-text-dark-light capitalize">
                      {role.name}
                    </p>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">
                      Access Level {getRoleLevel(role.name)}
                    </p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors">
                    <Edit className="w-4 h-4 text-text-grey" />
                  </button>
                  <button className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors">
                    <Key className="w-4 h-4 text-text-grey" />
                  </button>
                </div>
              </div>
            ))}
        </div>
      </div>

      {/* Roles Table */}
      <DataTable
        data={roles}
        columns={columns}
        actions={actions}
        loading={loading}
        pagination={{
          ...pagination,
          onPageChange: (page) => setPagination(prev => ({ ...prev, page })),
          onPerPageChange: (perPage) => setPagination(prev => ({ ...prev, perPage, page: 1 }))
        }}
        emptyMessage="No roles found. Create your first role to get started."
      />
    </div>
  );
};

export default Roles;
