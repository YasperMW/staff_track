import React, { useState, useEffect } from 'react';
import type { Department } from '../services/api';
import { departmentsApi } from '../services/api';
import DataTable from '../components/DataTable';
import type { Column, Action } from '../components/DataTable';
import { Plus, Building2, Edit, Trash2, Eye, Users, Settings, MapPin } from 'lucide-react';

const Departments: React.FC = () => {
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });

  useEffect(() => {
    loadDepartments();
  }, [pagination.page, pagination.perPage]);

  const loadDepartments = async () => {
    try {
      setLoading(true);
      const response = await departmentsApi.getAllDepartments();
      setDepartments(response.items || []);
      setPagination(prev => ({ ...prev, total: response.total_count || 0 }));
    } catch (error) {
      console.error('Error loading departments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEditDepartment = (department: Department) => {
    console.log('Edit department:', department);
    // TODO: Open edit modal
  };

  const handleDeleteDepartment = (department: Department) => {
    console.log('Delete department:', department);
    // TODO: Show confirmation dialog
  };

  const handleViewDepartment = (department: Department) => {
    console.log('View department:', department);
    // TODO: Open department details modal
  };

  const handleManageDesignations = (department: Department) => {
    console.log('Manage designations:', department);
    // TODO: Open designations management modal
  };

  const handleAddDepartment = () => {
    console.log('Add new department');
    // TODO: Open add department modal
  };

  const getDepartmentColor = (index: number) => {
    const colors = [
      'bg-sky-blue',
      'bg-light-gold',
      'bg-pale-red',
      'bg-green-500',
      'bg-purple-500',
      'bg-indigo-500',
      'bg-pink-500',
      'bg-teal-500'
    ];
    return colors[index % colors.length];
  };

  const getDepartmentInitials = (name: string) => {
    return name
      .split(' ')
      .map(word => word.charAt(0))
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const columns: Column<Department>[] = [
    {
      key: 'name',
      label: 'Department',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="flex items-center space-x-3">
          <div className={`w-10 h-10 ${getDepartmentColor(departments.indexOf(row))} rounded-xl flex items-center justify-center`}>
            <span className="text-white text-sm font-bold">
              {getDepartmentInitials(row.name)}
            </span>
          </div>
          <div>
            <p className="font-medium text-text-dark dark:text-text-dark-light">
              {row.name}
            </p>
            <p className="text-sm text-text-grey dark:text-text-grey-dark">
              {row.description || 'No description'}
            </p>
          </div>
        </div>
      )
    },
    {
      key: 'designations',
      label: 'Designations',
      sortable: false,
      filterable: false,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
            {Array.isArray(value) ? value.length : 0}
          </span>
          <span className="text-xs text-text-grey dark:text-text-grey-dark">
            positions
          </span>
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

  const actions: Action<Department>[] = [
    {
      label: 'View',
      icon: <Eye className="w-4 h-4" />,
      onClick: handleViewDepartment,
      variant: 'primary'
    },
    {
      label: 'Edit',
      icon: <Edit className="w-4 h-4" />,
      onClick: handleEditDepartment,
      variant: 'secondary'
    },
    {
      label: 'Manage Designations',
      icon: <Settings className="w-4 h-4" />,
      onClick: handleManageDesignations,
      variant: 'secondary'
    },
    {
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteDepartment,
      variant: 'danger'
    }
  ];

  // Calculate statistics
  const totalDesignations = departments.reduce((sum, dept) => sum + (dept.designations?.length || 0), 0);
  const avgDesignationsPerDept = departments.length > 0 ? Math.round(totalDesignations / departments.length) : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Department Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage hospital departments and job designations
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <button className="btn-outline flex items-center space-x-2">
            <MapPin className="w-4 h-4" />
            <span>Department Map</span>
          </button>
          <button 
            onClick={handleAddDepartment}
            className="btn-primary flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Department</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Departments</p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {departments.length}
              </p>
            </div>
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <Building2 className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Designations</p>
              <p className="text-2xl font-bold text-light-gold">
                {totalDesignations}
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Avg. Designations</p>
              <p className="text-2xl font-bold text-green-600">
                {avgDesignationsPerDept}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
              <Settings className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Active Departments</p>
              <p className="text-2xl font-bold text-purple-600">
                {departments.length}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <MapPin className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Departments Grid View */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {departments.slice(0, 6).map((department, index) => (
          <div key={department.department_id} className="card hover:shadow-card-hover transition-all duration-200 cursor-pointer">
            <div className="flex items-start justify-between mb-4">
              <div className={`w-12 h-12 ${getDepartmentColor(index)} rounded-xl flex items-center justify-center`}>
                <span className="text-white text-lg font-bold">
                  {getDepartmentInitials(department.name)}
                </span>
              </div>
              <div className="flex items-center space-x-1">
                <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors">
                  <Edit className="w-4 h-4 text-text-grey" />
                </button>
                <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors">
                  <Trash2 className="w-4 h-4 text-pale-red" />
                </button>
              </div>
            </div>
            
            <h3 className="font-semibold text-text-dark dark:text-text-dark-light mb-2">
              {department.name}
            </h3>
            
            <p className="text-sm text-text-grey dark:text-text-grey-dark mb-4 line-clamp-2">
              {department.description || 'No description available'}
            </p>
            
            <div className="flex items-center justify-between pt-4 border-t border-gray-100 dark:border-gray-700">
              <div className="flex items-center space-x-2">
                <Users className="w-4 h-4 text-text-grey" />
                <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
                  {department.designations?.length || 0}
                </span>
                <span className="text-xs text-text-grey dark:text-text-grey-dark">
                  designations
                </span>
              </div>
              <button className="text-sky-blue hover:text-sky-blue-dark text-sm font-medium">
                Manage →
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Departments Table */}
      <DataTable
        data={departments}
        columns={columns}
        actions={actions}
        loading={loading}
        pagination={{
          ...pagination,
          onPageChange: (page) => setPagination(prev => ({ ...prev, page })),
          onPerPageChange: (perPage) => setPagination(prev => ({ ...prev, perPage, page: 1 }))
        }}
        emptyMessage="No departments found. Create your first department to get started."
      />
    </div>
  );
};

export default Departments;
