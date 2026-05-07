import React, { useState, useEffect } from 'react';
import type { Role } from '../services/api';
import { rolesApi } from '../services/api';
import DataTable from '../components/DataTable';
import StatsCard from '../components/StatsCard';
import type { Column, Action } from '../components/DataTable';
import { Plus, Shield, Edit, Trash2, Eye, Users, Settings, X } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';

const Roles: React.FC = () => {
  const { success, error: showError } = useToast();
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });

  // Modal states
  const [viewRole, setViewRole] = useState<Role | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [editRole, setEditRole] = useState<Role | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [deleteRole, setDeleteRole] = useState<Role | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [newRoleName, setNewRoleName] = useState('');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  useEffect(() => {
    loadRoles();
  }, [pagination.page, pagination.perPage]);

  const loadRoles = async () => {
    try {
      setLoading(true);
      const response = await rolesApi.getAllRoles();
      setRoles(response.roles || []);
      setPagination(prev => ({ ...prev, total: response.total_count || 0 }));
    } catch (error) {
      console.error('Error loading roles:', error);
      showError('Failed to load roles');
    } finally {
      setLoading(false);
    }
  };

  const handleViewRole = (role: Role) => {
    setViewRole(role);
    setIsViewModalOpen(true);
  };

  const handleEditRole = (role: Role) => {
    setEditRole(role);
    setEditName(role.name);
    setIsEditModalOpen(true);
  };

  const handleSaveEdit = async () => {
    if (!editRole || !editName.trim()) return;
    try {
      const updated = await rolesApi.updateRole(editRole.role_id, { name: editName.trim() });
      setRoles(prev => prev.map(r => r.role_id === updated.role_id ? updated : r));
      setIsEditModalOpen(false);
      setEditRole(null);
      success('Role updated successfully');
    } catch (err: any) {
      showError(err.response?.data?.detail || 'Failed to update role');
    }
  };

  const handleDeleteRole = (role: Role) => {
    setDeleteRole(role);
    setIsDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!deleteRole) return;
    try {
      await rolesApi.deleteRole(deleteRole.role_id);
      setRoles(prev => prev.filter(r => r.role_id !== deleteRole.role_id));
      setIsDeleteModalOpen(false);
      setDeleteRole(null);
      success('Role deleted successfully');
    } catch (err: any) {
      showError(err.response?.data?.detail || 'Failed to delete role');
    }
  };

  const handleAddRole = async () => {
    if (!newRoleName.trim()) return;
    try {
      setIsCreating(true);
      const created = await rolesApi.createRole({ name: newRoleName.trim() });
      setRoles(prev => [...prev, created]);
      setIsCreateModalOpen(false);
      setNewRoleName('');
      success('Role created successfully');
    } catch (err: any) {
      showError(err.response?.data?.detail || 'Failed to create role');
    } finally {
      setIsCreating(false);
    }
  };

  const getRoleColor = (roleName: string) => {
    const roleColors: Record<string, string> = {
      'system admin': 'bg-purple-500',
      'hr admin': 'bg-blue-500',
      'head of department': 'bg-indigo-500',
      'hr': 'bg-blue-400',
      'accountant': 'bg-green-500',
      'principal hospital administrator': 'bg-purple-400',
      'system administrator': 'bg-purple-600',
      'staff': 'bg-gray-500',
    };
    return roleColors[roleName.toLowerCase()] || 'bg-sky-blue';
  };

  const getRoleIcon = (roleName: string) => {
    const roleIcons: Record<string, React.ReactNode> = {
      'system admin': <Shield className="w-5 h-5" />,
      'hr admin': <Users className="w-5 h-5" />,
      'head of department': <Settings className="w-5 h-5" />,
      'hr': <Users className="w-5 h-5" />,
      'accountant': <Settings className="w-5 h-5" />,
      'principal hospital administrator': <Shield className="w-5 h-5" />,
      'system administrator': <Shield className="w-5 h-5" />,
      'staff': <Users className="w-5 h-5" />,
    };
    return roleIcons[roleName.toLowerCase()] || <Shield className="w-5 h-5" />;
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
              {row.user_count || 0} user(s)
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
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteRole,
      variant: 'danger'
    }
  ];

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
        <button
          onClick={() => setIsCreateModalOpen(true)}
          className="btn-primary flex items-center space-x-2"
        >
          <Plus className="w-4 h-4" />
          <span>Add Role</span>
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatsCard
          label="Total Roles"
          value={roles.length}
          icon={<Shield className="w-6 h-6 text-sky-blue" />}
          iconBgColor="bg-sky-blue"
        />
        <StatsCard
          label="Admin Roles"
          value={adminRoles}
          icon={<Shield className="w-6 h-6 text-purple-600 dark:text-purple-400" />}
          iconBgColor="bg-purple-100 dark:bg-purple-900"
          valueColor="text-purple-600"
        />
        <StatsCard
          label="Staff Roles"
          value={staffRoles}
          icon={<Users className="w-6 h-6 text-green-600 dark:text-green-400" />}
          iconBgColor="bg-green-100 dark:bg-green-900"
          valueColor="text-green-600"
        />
        <StatsCard
          label="Specialized"
          value={roles.length - adminRoles - staffRoles}
          icon={<Settings className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />}
          iconBgColor="bg-yellow-100 dark:bg-yellow-900"
          valueColor="text-light-gold"
        />
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

      {/* View Role Modal */}
      {isViewModalOpen && viewRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Role Details</h2>
              <button onClick={() => { setIsViewModalOpen(false); setViewRole(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 ${getRoleColor(viewRole.name)} rounded-xl flex items-center justify-center`}>
                  <span className="text-white">{getRoleIcon(viewRole.name)}</span>
                </div>
                <div>
                  <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{viewRole.name}</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">{viewRole.user_count || 0} user(s) assigned</p>
                </div>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 space-y-3">
                <div>
                  <p className="text-xs text-text-grey dark:text-text-grey-dark uppercase tracking-wide">Created</p>
                  <p className="font-medium text-text-dark dark:text-text-dark-light">{viewRole.created_at ? new Date(viewRole.created_at).toLocaleDateString() : 'N/A'}</p>
                </div>
                {viewRole.updated_at && (
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark uppercase tracking-wide">Last Updated</p>
                    <p className="font-medium text-text-dark dark:text-text-dark-light">{new Date(viewRole.updated_at).toLocaleDateString()}</p>
                  </div>
                )}
                <div>
                  <p className="text-xs text-text-grey dark:text-text-grey-dark uppercase tracking-wide">Role ID</p>
                  <p className="font-mono text-xs text-text-dark dark:text-text-dark-light">{viewRole.role_id}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Role Modal */}
      {isEditModalOpen && editRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Edit Role</h2>
              <button onClick={() => { setIsEditModalOpen(false); setEditRole(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Role Name</label>
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="input-field w-full"
                  placeholder="Enter role name"
                />
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
                <p className="text-xs text-text-grey dark:text-text-grey-dark">Users with this role</p>
                <p className="font-semibold text-text-dark dark:text-text-dark-light">{editRole.user_count || 0}</p>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsEditModalOpen(false); setEditRole(null); }} className="btn-outline">Cancel</button>
                <button onClick={handleSaveEdit} className="btn-primary">Save Changes</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Role Modal */}
      {isDeleteModalOpen && deleteRole && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-red-600">Delete Role</h2>
              <button onClick={() => { setIsDeleteModalOpen(false); setDeleteRole(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-text-dark dark:text-text-dark-light">
                Are you sure you want to delete the role <strong>"{deleteRole.name}"</strong>?
              </p>
              {(deleteRole.user_count || 0) > 0 && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                  <p className="text-sm text-red-700 dark:text-red-400">
                    This role has {deleteRole.user_count} user(s) assigned. You must reassign or remove these users before deleting the role.
                  </p>
                </div>
              )}
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsDeleteModalOpen(false); setDeleteRole(null); }} className="btn-outline">Cancel</button>
                <button onClick={handleConfirmDelete} className="btn-danger">Delete Role</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Create Role Modal */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Create New Role</h2>
              <button onClick={() => { setIsCreateModalOpen(false); setNewRoleName(''); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Role Name</label>
                <input
                  type="text"
                  value={newRoleName}
                  onChange={(e) => setNewRoleName(e.target.value)}
                  className="input-field w-full"
                  placeholder="e.g., Department Supervisor"
                  onKeyDown={(e) => { if (e.key === 'Enter') handleAddRole(); }}
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsCreateModalOpen(false); setNewRoleName(''); }} className="btn-outline">Cancel</button>
                <button onClick={handleAddRole} disabled={isCreating || !newRoleName.trim()} className="btn-primary">
                  {isCreating ? 'Creating...' : 'Create Role'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Roles;
