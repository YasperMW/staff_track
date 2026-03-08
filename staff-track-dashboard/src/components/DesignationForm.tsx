import React, { useState, useEffect } from 'react';
import type { Designation, Department } from '../services/api';
import { designationsApi, departmentsApi } from '../services/api';
import { Briefcase, Save, X } from 'lucide-react';

interface DesignationFormProps {
  designation?: Designation;
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
  preselectedDepartmentId?: string;
}

const DesignationForm: React.FC<DesignationFormProps> = ({
  designation,
  isOpen,
  onClose,
  onSave,
  preselectedDepartmentId
}) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    department_id: ''
  });
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingDepartments, setLoadingDepartments] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (isOpen) {
      loadDepartments();
    }
  }, [isOpen]);

  useEffect(() => {
    if (designation) {
      setFormData({
        name: designation.name,
        description: designation.description || '',
        department_id: designation.department_id
      });
    } else {
      setFormData({
        name: '',
        description: '',
        department_id: preselectedDepartmentId || ''
      });
    }
    setErrors({});
  }, [designation, isOpen, preselectedDepartmentId]);

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

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Clear error for this field
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Designation name is required';
    } else if (formData.name.trim().length < 2) {
      newErrors.name = 'Designation name must be at least 2 characters';
    } else if (formData.name.trim().length > 150) {
      newErrors.name = 'Designation name must be less than 150 characters';
    }

    if (!formData.department_id) {
      newErrors.department_id = 'Department is required';
    }

    if (formData.description && formData.description.length > 500) {
      newErrors.description = 'Description must be less than 500 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    try {
      if (designation) {
        // Update existing designation
        await designationsApi.updateDesignation(designation.designation_id, formData);
      } else {
        // Create new designation
        await designationsApi.createDesignation(formData);
      }
      
      onSave();
      onClose();
    } catch (error: any) {
      console.error('Error saving designation:', error);
      const errorMessage = error.response?.data?.detail || 'Failed to save designation';
      setErrors({ submit: errorMessage });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-3 mb-6">
        <div className="w-12 h-12 bg-purple-500 bg-opacity-10 rounded-xl flex items-center justify-center">
          <Briefcase className="w-6 h-6 text-purple-500" />
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            {designation ? 'Edit Designation' : 'Create New Designation'}
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {designation ? 'Update designation information' : 'Add a new job designation to the organization'}
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Department Selection */}
        <div>
          <label htmlFor="department_id" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Department <span className="text-red-500">*</span>
          </label>
          <select
            id="department_id"
            name="department_id"
            value={formData.department_id}
            onChange={handleInputChange}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
              errors.department_id ? 'border-red-500' : 'border-gray-300'
            }`}
            disabled={loading || loadingDepartments}
          >
            <option value="">Select a department</option>
            {departments.map((dept) => (
              <option key={dept.department_id} value={dept.department_id}>
                {dept.name}
              </option>
            ))}
          </select>
          {errors.department_id && (
            <p className="mt-1 text-sm text-red-500">{errors.department_id}</p>
          )}
        </div>

        {/* Designation Name */}
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Designation Name <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
              errors.name ? 'border-red-500' : 'border-gray-300'
            }`}
            placeholder="e.g., Senior Nurse"
            disabled={loading}
          />
          {errors.name && (
            <p className="mt-1 text-sm text-red-500">{errors.name}</p>
          )}
        </div>

        {/* Description */}
        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Description
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            rows={4}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white resize-none ${
              errors.description ? 'border-red-500' : 'border-gray-300'
            }`}
            placeholder="Provide a brief description of the role's responsibilities and requirements..."
            disabled={loading}
          />
          {errors.description && (
            <p className="mt-1 text-sm text-red-500">{errors.description}</p>
          )}
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            {formData.description.length}/500 characters
          </p>
        </div>

        {/* Error Message */}
        {errors.submit && (
          <div className="p-4 bg-red-50 dark:bg-red-900 border border-red-200 dark:border-red-700 rounded-lg">
            <p className="text-sm text-red-600 dark:text-red-400">{errors.submit}</p>
          </div>
        )}

        {/* Actions */}
        <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200 dark:border-gray-700">
          <button
            type="button"
            onClick={onClose}
            disabled={loading}
            className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
          >
            <X className="w-4 h-4" />
            <span>Cancel</span>
          </button>
          <button
            type="submit"
            disabled={loading || loadingDepartments}
            className="px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
          >
            <Save className="w-4 h-4" />
            <span>{loading ? 'Saving...' : (designation ? 'Update Designation' : 'Create Designation')}</span>
          </button>
        </div>
      </form>
    </div>
  );
};

export default DesignationForm;
