import React, { useState, useEffect } from 'react';
import type { Designation, Department } from '../services/api';
import { designationsApi } from '../services/api';
import DataTable from '../components/DataTable';
import Modal from '../components/Modal';
import DesignationForm from '../components/DesignationForm';
import type { Column, Action } from '../components/DataTable';
import { Briefcase, Plus, Edit, Trash2, Eye, Users, ArrowLeft } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';

interface DepartmentDesignationsModalProps {
  department: Department | null;
  isOpen: boolean;
  onClose: () => void;
}

const DepartmentDesignationsModal: React.FC<DepartmentDesignationsModalProps> = ({
  department,
  isOpen,
  onClose
}) => {
  const { success, error: showError } = useToast();
  const [designations, setDesignations] = useState<Designation[]>([]);
  const [loading, setLoading] = useState(true);
  const [isDesignationFormOpen, setIsDesignationFormOpen] = useState(false);
  const [selectedDesignation, setSelectedDesignation] = useState<Designation | undefined>();
  const [pagination, setPagination] = useState({
    page: 1,
    perPage: 25,
    total: 0
  });
  const [deleteDesignation, setDeleteDesignation] = useState<Designation | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [viewDesignation, setViewDesignation] = useState<Designation | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);

  useEffect(() => {
    if (isOpen && department) {
      loadDesignations();
    }
  }, [isOpen, department, pagination.page, pagination.perPage]);

  const loadDesignations = async () => {
    if (!department) return;
    
    try {
      setLoading(true);
      const response = await designationsApi.getAllDesignations();
      const departmentDesignations = response.designations?.filter(
        d => d.department_id === department.department_id
      ) || [];
      
      setDesignations(departmentDesignations);
      setPagination(prev => ({ ...prev, total: departmentDesignations.length }));
    } catch (error) {
      console.error('Error loading designations:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddDesignation = () => {
    setSelectedDesignation(undefined);
    setIsDesignationFormOpen(true);
  };

  const handleEditDesignation = (designation: Designation) => {
    setSelectedDesignation(designation);
    setIsDesignationFormOpen(true);
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

  const handleDesignationFormClose = () => {
    setIsDesignationFormOpen(false);
    setSelectedDesignation(undefined);
  };

  const handleDesignationFormSave = () => {
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

  if (!department) return null;

  return (
    <>
      <Modal
        isOpen={isOpen}
        onClose={onClose}
        title={`Manage Designations - ${department.name}`}
        size="xl"
      >
      <div className="space-y-6">
        {/* Header with back button */}
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5 text-gray-500 dark:text-gray-400" />
            </button>
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                {department.name} Designations
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Manage job positions within this department
              </p>
            </div>
          </div>
          
          <button 
            onClick={handleAddDesignation}
            className="btn-primary flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Designation</span>
          </button>
        </div>

        {/* Department Info */}
        <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <Briefcase className="w-6 h-6 text-sky-blue" />
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white">
                {department.name}
              </h4>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {department.description || 'No description available'}
              </p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Designations</p>
                <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                  {designations.length}
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
                <p className="text-sm text-text-grey dark:text-text-grey-dark">Active Positions</p>
                <p className="text-2xl font-bold text-blue-600">
                  {designations.length}
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center">
                <Users className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </div>
          
          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-text-grey dark:text-text-grey-dark">Department Status</p>
                <p className="text-2xl font-bold text-green-600">
                  Active
                </p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
                <Briefcase className="w-6 h-6 text-green-600 dark:text-green-400" />
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
          emptyMessage="No designations found for this department. Create your first designation to get started."
        />

          {/* Designation Form Modal */}
          <Modal
            isOpen={isDesignationFormOpen}
            onClose={handleDesignationFormClose}
            title={selectedDesignation ? 'Edit Designation' : 'Create Designation'}
            size="md"
          >
            <DesignationForm
              designation={selectedDesignation}
              isOpen={isDesignationFormOpen}
              onClose={handleDesignationFormClose}
              onSave={handleDesignationFormSave}
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
                    <p className="text-sm text-gray-500 dark:text-gray-400">{viewDesignation.department_name || department?.name || 'Unknown Department'}</p>
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
      </Modal>
    </>
  );
};

export default DepartmentDesignationsModal;
