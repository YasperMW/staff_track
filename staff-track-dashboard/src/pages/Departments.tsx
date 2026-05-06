import React, { useState, useEffect } from 'react';
import type { Department } from '../services/api';
import { departmentsApi } from '../services/api';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import DepartmentForm from '../components/DepartmentForm';
import DepartmentDesignationsModal from '../components/DepartmentDesignationsModal';
import StatsCard from '../components/StatsCard';
import type { Column, Action } from '../components/DataTable';
import { Plus, Building2, Edit, Trash2, Eye, Users, Settings, MapPin } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';

const Departments: React.FC = () => {
  const { success, error: showError } = useToast();
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDesignationsModalOpen, setIsDesignationsModalOpen] = useState(false);
  const [selectedDepartment, setSelectedDepartment] = useState<Department | null>(null);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });
  const [deleteDepartment, setDeleteDepartment] = useState<Department | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [viewDepartment, setViewDepartment] = useState<Department | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [isMapModalOpen, setIsMapModalOpen] = useState(false);

  useEffect(() => {
    loadDepartments();
  }, [pagination.page, pagination.perPage]);

  const loadDepartments = async () => {
    try {
      setLoading(true);
      const response = await departmentsApi.getAllDepartments();
      console.log('API Response:', response);
      console.log('Response departments:', response.departments);
      console.log('Response total:', response.total_count);
      setDepartments(response.departments || []);
      setPagination(prev => ({ ...prev, total: response.total_count || 0 }));
    } catch (error) {
      console.error('Error loading departments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEditDepartment = (department: Department) => {
    setSelectedDepartment(department);
    setIsModalOpen(true);
  };

  const handleDeleteDepartment = (department: Department) => {
    setDeleteDepartment(department);
    setIsDeleteModalOpen(true);
  };

  const confirmDeleteDepartment = async () => {
    if (!deleteDepartment) return;
    try {
      await departmentsApi.deleteDepartment(deleteDepartment.department_id);
      success('Department deleted successfully');
      loadDepartments();
    } catch (error: any) {
      console.error('Error deleting department:', error);
      showError(error.response?.data?.detail || 'Failed to delete department');
    } finally {
      setIsDeleteModalOpen(false);
      setDeleteDepartment(null);
    }
  };

  const handleViewDepartment = (department: Department) => {
    setViewDepartment(department);
    setIsViewModalOpen(true);
  };

  const handleManageDesignations = (department: Department) => {
    setSelectedDepartment(department);
    setIsDesignationsModalOpen(true);
  };

  const handleAddDepartment = () => {
    setSelectedDepartment(null);
    setIsModalOpen(true);
  };

  const handleModalClose = () => {
    setIsModalOpen(false);
    setSelectedDepartment(null);
  };

  const handleModalSave = () => {
    loadDepartments();
  };

  const handleDesignationsModalClose = () => {
    setIsDesignationsModalOpen(false);
    setSelectedDepartment(null);
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
          <button 
            onClick={() => setIsMapModalOpen(true)}
            className="btn-outline flex items-center space-x-2"
          >
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
        <StatsCard
          label="Total Departments"
          value={departments.length}
          icon={<Building2 className="w-6 h-6 text-sky-blue" />}
          iconBgColor="bg-sky-blue"
        />
        <StatsCard
          label="Total Designations"
          value={totalDesignations}
          icon={<Users className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />}
          iconBgColor="bg-yellow-100 dark:bg-yellow-900"
          valueColor="text-light-gold"
        />
        <StatsCard
          label="Avg. Designations"
          value={avgDesignationsPerDept}
          icon={<Settings className="w-6 h-6 text-green-600 dark:text-green-400" />}
          iconBgColor="bg-green-100 dark:bg-green-900"
          valueColor="text-green-600"
        />
        <StatsCard
          label="Active Departments"
          value={departments.length}
          icon={<MapPin className="w-6 h-6 text-purple-600 dark:text-purple-400" />}
          iconBgColor="bg-purple-100 dark:bg-purple-900"
          valueColor="text-purple-600"
        />
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
                <button 
                  onClick={() => handleEditDepartment(department)}
                  className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
                >
                  <Edit className="w-4 h-4 text-text-grey" />
                </button>
                <button 
                  onClick={() => handleDeleteDepartment(department)}
                  className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
                >
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
              <button 
                onClick={() => handleManageDesignations(department)}
                className="text-sky-blue hover:text-sky-blue-dark text-sm font-medium"
              >
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

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={handleModalClose}
        title={selectedDepartment ? 'Edit Department' : 'Create Department'}
        size="md"
      >
        <DepartmentForm
          department={selectedDepartment}
          isOpen={isModalOpen}
          onClose={handleModalClose}
          onSave={handleModalSave}
        />
      </Modal>

      {/* Designations Modal */}
      <DepartmentDesignationsModal
        department={selectedDepartment}
        isOpen={isDesignationsModalOpen}
        onClose={handleDesignationsModalClose}
      />

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => { setIsDeleteModalOpen(false); setDeleteDepartment(null); }}
        title="Confirm Delete"
        size="sm"
      >
        <div className="space-y-4">
          <div className="flex items-center space-x-3 p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
            <Trash2 className="w-6 h-6 text-red-600 dark:text-red-400 flex-shrink-0" />
            <p className="text-sm text-gray-700 dark:text-gray-300">
              Are you sure you want to delete the department <strong>"{deleteDepartment?.name}"</strong>? This action cannot be undone.
            </p>
          </div>
          <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={() => { setIsDeleteModalOpen(false); setDeleteDepartment(null); }}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={confirmDeleteDepartment}
              className="px-4 py-2 bg-red-600 text-white hover:bg-red-700 rounded-lg transition-colors flex items-center space-x-2"
            >
              <Trash2 className="w-4 h-4" />
              <span>Delete</span>
            </button>
          </div>
        </div>
      </Modal>

      {/* View Details Modal */}
      <Modal
        isOpen={isViewModalOpen}
        onClose={() => { setIsViewModalOpen(false); setViewDepartment(null); }}
        title="Department Details"
        size="md"
      >
        {viewDepartment && (
          <div className="space-y-4">
            <div className="flex items-center space-x-3 p-4 bg-sky-blue/10 rounded-lg">
              <div className="w-10 h-10 bg-sky-blue rounded-xl flex items-center justify-center">
                <Building2 className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">{viewDepartment.name}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{viewDepartment.description || 'No description'}</p>
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-gray-100 dark:border-gray-700">
                <span className="text-sm text-gray-500 dark:text-gray-400">Designations</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">{viewDepartment.designations?.length || 0}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-gray-100 dark:border-gray-700">
                <span className="text-sm text-gray-500 dark:text-gray-400">Created</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">{viewDepartment.created_at ? new Date(viewDepartment.created_at).toLocaleDateString() : 'N/A'}</span>
              </div>
            </div>
          </div>
        )}
      </Modal>

      {/* Department Map Modal */}
      {isMapModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                Department Map
              </h2>
              <button
                onClick={() => setIsMapModalOpen(false)}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {departments.map((dept, index) => (
                  <div
                    key={dept.department_id}
                    className={`p-4 rounded-lg border-2 hover:shadow-lg transition-all cursor-pointer ${getDepartmentColor(index).replace('bg-', 'border-').replace('text-', 'border-')} bg-opacity-10`}
                    onClick={() => {
                      handleViewDepartment(dept);
                      setIsMapModalOpen(false);
                    }}
                  >
                    <div className="flex items-center space-x-3 mb-3">
                      <div className={`w-10 h-10 ${getDepartmentColor(index)} rounded-xl flex items-center justify-center`}>
                        <span className="text-white text-sm font-bold">
                          {getDepartmentInitials(dept.name)}
                        </span>
                      </div>
                      <div>
                        <h4 className="font-medium text-gray-900 dark:text-white">{dept.name}</h4>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {dept.designations?.length || 0} designations
                        </p>
                      </div>
                    </div>
                    <p className="text-xs text-gray-600 dark:text-gray-400 line-clamp-2">
                      {dept.description || 'No description available'}
                    </p>
                  </div>
                ))}
              </div>
              {departments.length === 0 && !loading && (
                <div className="text-center py-8">
                  <Building2 className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500 dark:text-gray-400">No departments found</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Departments;
