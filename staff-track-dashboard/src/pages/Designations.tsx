import React, { useState, useEffect } from 'react';
import type { Designation, Department } from '../services/api';
import { designationsApi, departmentsApi } from '../services/api';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import DesignationForm from '../components/DesignationForm';
import StatsCard from '../components/StatsCard';
import type { Column, Action } from '../components/DataTable';
import { Plus, Briefcase, Edit, Trash2, Eye, Building2, Users, X } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';

const Designations: React.FC = () => {
  const { success, error: showError } = useToast();
  const [designations, setDesignations] = useState<Designation[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingDepartments, setLoadingDepartments] = useState(false);
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedDesignation, setSelectedDesignation] = useState<Designation | undefined>();
  const [filterDepartment, setFilterDepartment] = useState('');
  const [deleteDesignation, setDeleteDesignation] = useState<Designation | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [viewDesignation, setViewDesignation] = useState<Designation | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);

  useEffect(() => {
    loadDesignations();
    loadDepartments();
  }, [pagination.page, pagination.perPage, filterDepartment]);

  const loadDesignations = async () => {
    try {
      setLoading(true);
      const response = await designationsApi.getAllDesignations();
      let allDesignations = response.designations || [];
      
      // Filter by department if selected
      if (filterDepartment) {
        allDesignations = allDesignations.filter(d => d.department_id === filterDepartment);
      }
      
      setDesignations(allDesignations);
      setPagination(prev => ({ ...prev, total: allDesignations.length }));
    } catch (error) {
      console.error('Error loading designations:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadDepartments = async () => {
    setLoadingDepartments(true);
    try {
      const response = await departmentsApi.getAllDepartments();
      setDepartments(response.departments || []);
    } catch (error) {
      console.error('Error loading departments:', error);
    } finally {
      setLoadingDepartments(false);
    }
  };

  const handleAddDesignation = () => {
    setSelectedDesignation(undefined);
    setIsModalOpen(true);
  };

  const handleEditDesignation = (designation: Designation) => {
    setSelectedDesignation(designation);
    setIsModalOpen(true);
  };

  const handleDeleteDesignation = (designation: Designation) => {
    setDeleteDesignation(designation);
    setIsDeleteModalOpen(true);
  };

  const confirmDeleteDesignation = async () => {
    if (!deleteDesignation) return;
    try {
      await designationsApi.deleteDesignation(deleteDesignation.designation_id);
      success('Designation deleted successfully');
      loadDesignations();
    } catch (error: any) {
      console.error('Error deleting designation:', error);
      showError(error.response?.data?.detail || 'Failed to delete designation');
    } finally {
      setIsDeleteModalOpen(false);
      setDeleteDesignation(null);
    }
  };

  const handleViewDesignation = (designation: Designation) => {
    setViewDesignation(designation);
    setIsViewModalOpen(true);
  };

  const handleModalClose = () => {
    setIsModalOpen(false);
    setSelectedDesignation(undefined);
  };

  const handleModalSave = () => {
    loadDesignations();
  };

  const getDesignationColor = (index: number) => {
    const colors = [
      'bg-purple-500',
      'bg-blue-500',
      'bg-green-500',
      'bg-yellow-500',
      'bg-red-500',
      'bg-indigo-500',
      'bg-pink-500',
      'bg-teal-500'
    ];
    return colors[index % colors.length];
  };

  const columns: Column<Designation>[] = [
    {
      key: 'name',
      label: 'Designation',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="flex items-center space-x-3">
          <div className={`w-10 h-10 ${getDesignationColor(designations.indexOf(row))} rounded-xl flex items-center justify-center`}>
            <Briefcase className="w-5 h-5 text-white" />
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
      key: 'department_name',
      label: 'Department',
      sortable: true,
      filterable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <Building2 className="w-4 h-4 text-text-grey" />
          <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
            {value || 'Unknown Department'}
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

  const actions: Action<Designation>[] = [
    {
      label: 'View',
      icon: <Eye className="w-4 h-4" />,
      onClick: handleViewDesignation,
      variant: 'primary'
    },
    {
      label: 'Edit',
      icon: <Edit className="w-4 h-4" />,
      onClick: handleEditDesignation,
      variant: 'secondary'
    },
    {
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteDesignation,
      variant: 'danger'
    }
  ];

  // Calculate statistics
  const totalDesignations = designations.length;
  const departmentsWithDesignations = new Set(designations.map(d => d.department_id)).size;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Designation Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage job designations and positions across departments
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          {/* Department Filter */}
          <select
            value={filterDepartment}
            onChange={(e) => setFilterDepartment(e.target.value)}
            className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            disabled={loadingDepartments}
          >
            <option value="">All Departments</option>
            {departments.map((dept) => (
              <option key={dept.department_id} value={dept.department_id}>
                {dept.name}
              </option>
            ))}
          </select>
          
          <button 
            onClick={handleAddDesignation}
            className="btn-primary flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Designation</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatsCard
          label="Total Designations"
          value={totalDesignations}
          icon={<Briefcase className="w-6 h-6 text-purple-500" />}
          iconBgColor="bg-purple-500"
        />
        <StatsCard
          label="Departments with Designations"
          value={departmentsWithDesignations}
          icon={<Building2 className="w-6 h-6 text-blue-600 dark:text-blue-400" />}
          iconBgColor="bg-blue-100 dark:bg-blue-900"
          valueColor="text-blue-600"
        />
        <StatsCard
          label="Avg. per Department"
          value={departmentsWithDesignations > 0 ? Math.round(totalDesignations / departmentsWithDesignations) : 0}
          icon={<Users className="w-6 h-6 text-green-600 dark:text-green-400" />}
          iconBgColor="bg-green-100 dark:bg-green-900"
          valueColor="text-green-600"
        />
        <StatsCard
          label="Active Positions"
          value={totalDesignations}
          icon={<Briefcase className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />}
          iconBgColor="bg-yellow-100 dark:bg-yellow-900"
          valueColor="text-yellow-600"
        />
      </div>

      {/* Designations Table */}
      <DataTable
        data={designations}
        columns={columns}
        actions={actions}
        loading={loading}
        pagination={{
          ...pagination,
          onPageChange: (page) => setPagination(prev => ({ ...prev, page })),
          onPerPageChange: (perPage) => setPagination(prev => ({ ...prev, perPage, page: 1 }))
        }}
        emptyMessage="No designations found. Create your first designation to get started."
      />

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={handleModalClose}
        title={selectedDesignation ? 'Edit Designation' : 'Create Designation'}
        size="md"
      >
        <DesignationForm
          designation={selectedDesignation}
          isOpen={isModalOpen}
          onClose={handleModalClose}
          onSave={handleModalSave}
        />
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => { setIsDeleteModalOpen(false); setDeleteDesignation(null); }}
        title="Confirm Delete"
        size="sm"
      >
        <div className="space-y-4">
          <div className="flex items-center space-x-3 p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
            <Trash2 className="w-6 h-6 text-red-600 dark:text-red-400 flex-shrink-0" />
            <p className="text-sm text-gray-700 dark:text-gray-300">
              Are you sure you want to delete the designation <strong>"{deleteDesignation?.name}"</strong>? This action cannot be undone.
            </p>
          </div>
          <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={() => { setIsDeleteModalOpen(false); setDeleteDesignation(null); }}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={confirmDeleteDesignation}
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
        onClose={() => { setIsViewModalOpen(false); setViewDesignation(null); }}
        title="Designation Details"
        size="md"
      >
        {viewDesignation && (
          <div className="space-y-4">
            <div className="flex items-center space-x-3 p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
              <div className="w-10 h-10 bg-purple-500 rounded-xl flex items-center justify-center">
                <Briefcase className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">{viewDesignation.name}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{viewDesignation.department_name || 'Unknown Department'}</p>
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-gray-100 dark:border-gray-700">
                <span className="text-sm text-gray-500 dark:text-gray-400">Description</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">{viewDesignation.description || 'No description'}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-gray-100 dark:border-gray-700">
                <span className="text-sm text-gray-500 dark:text-gray-400">Created</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">{viewDesignation.created_at ? new Date(viewDesignation.created_at).toLocaleDateString() : 'N/A'}</span>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default Designations;
