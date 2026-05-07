import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import { usersApi, rolesApi, departmentsApi, designationsApi, gradesApi } from '../services/api';
import type { User, Role, Department, Designation, Grade } from '../services/api';
import { X, Save, AlertTriangle, Shield, Briefcase } from 'lucide-react';
import Modal from './Modal';

interface UserEditModalProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: (updatedUser: User) => void;
}

const UserEditModal: React.FC<UserEditModalProps> = ({ user, isOpen, onClose, onSave }) => {
  const { success, error: showError } = useToast();
  const [loading, setLoading] = useState(false);
  const [roles, setRoles] = useState<Role[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [designations, setDesignations] = useState<Designation[]>([]);
  const [filteredDesignations, setFilteredDesignations] = useState<Designation[]>([]);
  const [grades, setGrades] = useState<Grade[]>([]);

  // Form state
  const [formData, setFormData] = useState({
    first_name: '',
    surname: '',
    other_names: '',
    email: '',
    phone: '',
    role_id: '',
    department_id: '',
    designation_id: '',
    grade_id: '',
    status: 'active',
    is_head_of_department: false
  });

  const [originalRole, setOriginalRole] = useState('');
  const [originalDepartment, setOriginalDepartment] = useState('');
  const [originalGrade, setOriginalGrade] = useState('');
  const [pendingSubmit, setPendingSubmit] = useState(false);
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);
  const [confirmMessage, setConfirmMessage] = useState('');

  useEffect(() => {
    if (isOpen) {
      loadDropdownData();
      if (user) {
        setFormData({
          first_name: user.first_name || '',
          surname: user.surname || '',
          other_names: user.other_names || '',
          email: user.email || '',
          phone: user.phone || '',
          role_id: user.role_id || '',
          department_id: user.department_id || '',
          designation_id: user.designation_id || '',
          grade_id: (user as any).grade_id || '',
          status: user.status || 'active',
          is_head_of_department: user.is_head_of_department || false
        });
        setOriginalRole(user.role_id || '');
        setOriginalDepartment(user.department_id || '');
        setOriginalGrade((user as any).grade_id || '');
      } else {
        setFormData({
          first_name: '',
          surname: '',
          other_names: '',
          email: '',
          phone: '',
          role_id: '',
          department_id: '',
          designation_id: '',
          grade_id: '',
          status: 'active',
          is_head_of_department: false
        });
        setOriginalRole('');
        setOriginalDepartment('');
        setOriginalGrade('');
      }
    }
  }, [isOpen, user]);

  useEffect(() => {
    // Filter designations based on selected department
    if (formData.department_id) {
      const filtered = designations.filter(
        d => d.department_id === formData.department_id
      );
      setFilteredDesignations(filtered);
      
      // Reset designation if it doesn't belong to the new department
      if (formData.designation_id && !filtered.some(d => d.designation_id === formData.designation_id)) {
        setFormData(prev => ({ ...prev, designation_id: '' }));
      }
    } else {
      setFilteredDesignations(designations);
    }
  }, [formData.department_id, designations]);

  const loadDropdownData = async () => {
    try {
      const [rolesRes, departmentsRes, designationsRes, gradesRes] = await Promise.all([
        rolesApi.getAllRoles(),
        departmentsApi.getAllDepartments(),
        designationsApi.getAllDesignations(),
        gradesApi.getAllGrades()
      ]);

      setRoles(rolesRes.roles || []);
      setDepartments(departmentsRes.departments || []);
      setDesignations(designationsRes.designations || []);
      setGrades(gradesRes || []);
    } catch (err) {
      console.error('Error loading dropdown data:', err);
      showError('Failed to load dropdown options');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!user) return;

    // Check if role or department is being changed
    const roleChanged = formData.role_id !== originalRole;
    const departmentChanged = formData.department_id !== originalDepartment;
    
    // Show confirmation for sensitive changes
    const gradeChanged = formData.grade_id !== originalGrade;
    if (roleChanged || departmentChanged || gradeChanged) {
      const message = roleChanged 
        ? `Are you sure you want to change this user's role? This will affect their system permissions.`
        : gradeChanged
        ? `Are you sure you want to change this user's grade? This will affect their annual leave entitlement.`
        : `Are you sure you want to change this user's department?`;
      
      setConfirmMessage(message);
      setPendingSubmit(true);
      setIsConfirmModalOpen(true);
      return;
    }

    await performUpdate();
  };

  const performUpdate = async () => {
    if (!user) return;

    setLoading(true);
    try {
      const gradeChanged = formData.grade_id !== originalGrade;
      
      // Update user basic info
      const updateData = {
        first_name: formData.first_name,
        surname: formData.surname,
        other_names: formData.other_names || undefined,
        email: formData.email,
        phone: formData.phone || undefined,
        role_id: formData.role_id,
        department_id: formData.department_id || undefined,
        designation_id: formData.designation_id || undefined,
        status: formData.status,
        is_head_of_department: formData.is_head_of_department
      };

      const response = await usersApi.updateUser(user.user_id, updateData);
      
      // Update grade separately if changed
      if (gradeChanged && formData.grade_id) {
        await gradesApi.updateUserGrade(user.user_id, formData.grade_id);
      }
      
      if (response.success) {
        success('User updated successfully!');
        onSave(response.data!);
        onClose();
      } else {
        showError(response.message || 'Failed to update user');
      }
    } catch (err: any) {
      console.error('Error updating user:', err);
      showError(err?.response?.data?.detail || 'Failed to update user');
    } finally {
      setLoading(false);
    }
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
      'hr': <Shield className="w-5 h-5" />,
      'manager': <Shield className="w-5 h-5" />,
      'employee': <Shield className="w-5 h-5" />,
      'staff': <Shield className="w-5 h-5" />,
      'doctor': <Shield className="w-5 h-5" />,
      'nurse': <Shield className="w-5 h-5" />
    };
    return roleIcons[roleName.toLowerCase() as keyof typeof roleIcons] || <Shield className="w-5 h-5" />;
  };

  if (!isOpen || !user) return null;

  return (
    <>
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center space-x-3">
            <div className={`w-10 h-10 ${getRoleColor(user.role_name)} rounded-xl flex items-center justify-center`}>
              <span className="text-white">
                {getRoleIcon(user.role_name)}
              </span>
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                Edit User
              </h2>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {user.first_name} {user.surname}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Personal Information */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center">
              <Shield className="w-5 h-5 mr-2 text-blue-500" />
              Personal Information
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  First Name *
                </label>
                <input
                  type="text"
                  name="first_name"
                  value={formData.first_name}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Surname *
                </label>
                <input
                  type="text"
                  name="surname"
                  value={formData.surname}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Other Names
                </label>
                <input
                  type="text"
                  name="other_names"
                  value={formData.other_names}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Email *
                </label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Phone
                </label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Status
                </label>
                <select
                  name="status"
                  value={formData.status}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                >
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                  <option value="blacklisted">Blacklisted</option>
                </select>
              </div>
            </div>
          </div>

          {/* Job Information */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center">
              <Briefcase className="w-5 h-5 mr-2 text-green-500" />
              Job Information
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Role *
                </label>
                <select
                  name="role_id"
                  value={formData.role_id}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                >
                  <option value="">Select a role</option>
                  {roles.map(role => (
                    <option key={role.role_id} value={role.role_id}>
                      {role.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Department
                </label>
                <select
                  name="department_id"
                  value={formData.department_id}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                >
                  <option value="">Select a department</option>
                  {departments.map(dept => (
                    <option key={dept.department_id} value={dept.department_id}>
                      {dept.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Designation
                </label>
                <select
                  name="designation_id"
                  value={formData.designation_id}
                  onChange={handleInputChange}
                  disabled={!formData.department_id}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <option value="">Select a designation</option>
                  {filteredDesignations.map(designation => (
                    <option key={designation.designation_id} value={designation.designation_id}>
                      {designation.name}
                    </option>
                  ))}
                </select>
                {formData.department_id && filteredDesignations.length === 0 && (
                  <p className="text-sm text-yellow-600 mt-1">
                    No designations available for this department
                  </p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Grade
                </label>
                <select
                  name="grade_id"
                  value={formData.grade_id}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-gray-100"
                >
                  <option value="">Select a grade</option>
                  {grades.map(grade => (
                    <option key={grade.id} value={grade.id}>
                      {grade.name} ({grade.annual_leave_days} days)
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  name="is_head_of_department"
                  checked={formData.is_head_of_department}
                  onChange={handleInputChange}
                  className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                />
                <label className="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                  Head of Department
                </label>
              </div>
            </div>
          </div>

          {/* Warning for role changes */}
          {(formData.role_id !== originalRole || formData.department_id !== originalDepartment) && (
            <div className="bg-yellow-50 dark:bg-yellow-900 border border-yellow-200 dark:border-yellow-700 rounded-lg p-4">
              <div className="flex items-start">
                <AlertTriangle className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5 mr-3 flex-shrink-0" />
                <div>
                  <h4 className="text-sm font-semibold text-yellow-800 dark:text-yellow-200">
                    Important Change Detected
                  </h4>
                  <p className="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                    {formData.role_id !== originalRole && 'Changing the user\'s role will affect their system permissions and access levels.'}
                    {formData.role_id !== originalRole && formData.department_id !== originalDepartment && ' '}
                    {formData.department_id !== originalDepartment && 'Changing the department may affect the user\'s reporting structure and access to department-specific resources.'}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  <span>Saving...</span>
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  <span>Save Changes</span>
                </>
              )}
            </button>
          </div>
        </form>

        {/* Confirmation Modal */}
        <Modal
          isOpen={isConfirmModalOpen}
          onClose={() => { setIsConfirmModalOpen(false); setPendingSubmit(false); }}
          title="Confirm Changes"
          size="sm"
        >
          <div className="space-y-4">
            <div className="flex items-center space-x-3 p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-yellow-600 dark:text-yellow-400 flex-shrink-0" />
              <p className="text-sm text-gray-700 dark:text-gray-300">{confirmMessage}</p>
            </div>
            <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
              <button
                type="button"
                onClick={() => { setIsConfirmModalOpen(false); setPendingSubmit(false); }}
                className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={async () => {
                  setIsConfirmModalOpen(false);
                  if (pendingSubmit) {
                    await performUpdate();
                  }
                }}
                className="px-4 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg transition-colors flex items-center space-x-2"
              >
                <Save className="w-4 h-4" />
                <span>Confirm & Save</span>
              </button>
            </div>
          </div>
        </Modal>
      </div>
    </div>
    </>
  );
};

export default UserEditModal;
