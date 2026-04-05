import React, { useState, useEffect } from 'react';
import { X, AlertTriangle, Info, Megaphone, Bell } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';
import { announcementsApi, departmentsApi } from '../services/api';

interface CreateAnnouncementModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

interface Department {
  department_id: string;
  name: string;
  description?: string;
}

const CreateAnnouncementModal: React.FC<CreateAnnouncementModalProps> = ({
  isOpen,
  onClose,
  onSuccess
}) => {
  const { success, error } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [departments, setDepartments] = useState<Department[]>([]);
  
  // Form state
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    type: 'general',
    target_departments: [] as string[],
    target_role: '',
    is_active: true,
    expires_at: '',
    send_notifications: true
  });

  const announcementTypes = [
    { value: 'general', label: '📢 General', icon: Megaphone, color: 'blue' },
    { value: 'urgent', label: '🚨 Urgent', icon: AlertTriangle, color: 'red' },
    { value: 'policy', label: '📋 Policy Update', icon: Info, color: 'green' },
    { value: 'event', label: '🎉 Event', icon: Bell, color: 'purple' },
    { value: 'maintenance', label: '🔧 Maintenance', icon: AlertTriangle, color: 'orange' }
  ];

  const roles = [
    'Doctor', 'Nurse', 'Pharmacist', 'Lab Technician', 'Radiologist',
    'Administrator', 'Accountant', 'IT Support', 'HR Manager',
    'Facility Manager', 'Security Officer', 'Cleaner', 'Cook', 'Receptionist'
  ];

  useEffect(() => {
    if (isOpen) {
      loadDepartments();
      resetForm();
    }
  }, [isOpen]);

  const loadDepartments = async () => {
    try {
      const response = await departmentsApi.getAllDepartments();
      setDepartments(response.departments || []);
    } catch (err) {
      console.error('Failed to load departments:', err);
    }
  };

  const resetForm = () => {
    setFormData({
      title: '',
      message: '',
      type: 'general',
      target_departments: [],
      target_role: '',
      is_active: true,
      expires_at: '',
      send_notifications: true
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim() || !formData.message.trim()) {
      error('Please fill in all required fields');
      return;
    }

    setIsSubmitting(true);
    
    try {
      const announcementData = {
        ...formData,
        target_departments: formData.target_departments.length > 0 ? formData.target_departments : undefined,
        target_role: formData.target_role || undefined,
        expires_at: formData.expires_at || undefined
      };

      await announcementsApi.createAnnouncement(announcementData);
      success('Announcement created successfully');
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Failed to create announcement:', err);
      error(err.response?.data?.message || 'Failed to create announcement');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDepartmentToggle = (departmentName: string) => {
    setFormData(prev => ({
      ...prev,
      target_departments: prev.target_departments.includes(departmentName)
        ? prev.target_departments.filter(d => d !== departmentName)
        : [...prev.target_departments, departmentName]
    }));
  };

  
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            Create New Announcement
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Title *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              placeholder="Enter announcement title"
              required
            />
          </div>

          {/* Message */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Message *
            </label>
            <textarea
              value={formData.message}
              onChange={(e) => setFormData(prev => ({ ...prev, message: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              rows={4}
              placeholder="Enter announcement message"
              required
            />
          </div>

          {/* Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Type
            </label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {announcementTypes.map((type) => {
                const Icon = type.icon;
                return (
                  <button
                    key={type.value}
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, type: type.value }))}
                    className={`p-3 rounded-lg border-2 transition-all ${
                      formData.type === type.value
                        ? `border-${type.color}-500 bg-${type.color}-50 dark:bg-${type.color}-900/20`
                        : 'border-gray-200 dark:border-gray-600 hover:border-gray-300 dark:hover:border-gray-500'
                    }`}
                  >
                    <Icon className={`w-5 h-5 mx-auto mb-1 text-${type.color}-500`} />
                    <div className="text-xs font-medium text-gray-900 dark:text-white">
                      {type.label}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Target Departments */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Target Departments
            </label>
            <div className="space-y-2 max-h-32 overflow-y-auto border border-gray-200 dark:border-gray-600 rounded-lg p-3">
              {departments.map((department) => (
                <label key={department.department_id} className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.target_departments.includes(department.name)}
                    onChange={() => handleDepartmentToggle(department.name)}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    {department.name}
                  </span>
                </label>
              ))}
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Leave empty to target all staff
            </p>
          </div>

          {/* Target Role */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Target Role (Optional)
            </label>
            <select
              value={formData.target_role}
              onChange={(e) => setFormData(prev => ({ ...prev, target_role: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
            >
              <option value="">All Roles</option>
              {roles.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </select>
          </div>

          {/* Expiration Date */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Expiration Date (Optional)
            </label>
            <input
              type="datetime-local"
              value={formData.expires_at}
              onChange={(e) => setFormData(prev => ({ ...prev, expires_at: e.target.value }))}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              min={new Date().toISOString().slice(0, 16)}
            />
          </div>

          {/* Send Notifications */}
          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="send_notifications"
              checked={formData.send_notifications}
              onChange={(e) => setFormData(prev => ({ ...prev, send_notifications: e.target.checked }))}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <label htmlFor="send_notifications" className="text-sm text-gray-700 dark:text-gray-300">
              Send push notifications to target users
            </label>
          </div>

          {/* Actions */}
          <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Creating...</span>
                </>
              ) : (
                <span>Create Announcement</span>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateAnnouncementModal;
