import React, { useState, useEffect } from 'react';
import type { Designation, Department } from '../services/api';
import { designationsApi, departmentsApi } from '../services/api';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import DesignationForm from '../components/DesignationForm';
import type { Column, Action } from '../components/DataTable';
import { Plus, Briefcase, Edit, Trash2, Eye, Building2, Users } from 'lucide-react';

const Designations: React.FC = () => {
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

  const handleDeleteDesignation = async (designation: Designation) => {
    if (!window.confirm(`Are you sure you want to delete the designation "${designation.name}"? This action cannot be undone.`)) {
      return;
    }

    try {
      await designationsApi.deleteDesignation(designation.designation_id);
      loadDesignations();
    } catch (error: any) {
      console.error('Error deleting designation:', error);
      const errorMessage = error.response?.data?.detail || 'Failed to delete designation';
      alert(errorMessage);
    }
  };

  const handleViewDesignation = (designation: Designation) => {
    const departmentName = designation.department_name || 'Unknown Department';
    alert(`
Designation Details:

Name: ${designation.name}
Department: ${departmentName}
Description: ${designation.description || 'No description'}
Created: ${designation.created_at ? new Date(designation.created_at).toLocaleDateString() : 'N/A'}
    `.trim());
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
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Designations</p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {totalDesignations}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-500 bg-opacity-10 rounded-xl flex items-center justify-center">
              <Briefcase className="w-6 h-6 text-purple-500" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Departments with Designations</p>
              <p className="text-2xl font-bold text-blue-600">
                {departmentsWithDesignations}
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center">
              <Building2 className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Avg. per Department</p>
              <p className="text-2xl font-bold text-green-600">
                {departmentsWithDesignations > 0 ? Math.round(totalDesignations / departmentsWithDesignations) : 0}
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Active Positions</p>
              <p className="text-2xl font-bold text-yellow-600">
                {totalDesignations}
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-xl flex items-center justify-center">
              <Briefcase className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
          </div>
        </div>
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
    </div>
  );
};

export default Designations;
