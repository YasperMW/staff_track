import React, { useState, useEffect } from 'react';
import type { Grade } from '../services/api';
import { gradesApi } from '../services/api';
import DataTable from '../components/DataTable';
import StatsCard from '../components/StatsCard';
import type { Column, Action } from '../components/DataTable';
import { Plus, Award, Edit, Trash2, Eye, X, Calendar } from 'lucide-react';
import { useToast } from '../contexts/ToastContext';

const Grades: React.FC = () => {
  const { success, error: showError } = useToast();
  const [grades, setGrades] = useState<Grade[]>([]);
  const [loading, setLoading] = useState(true);

  const [viewGrade, setViewGrade] = useState<Grade | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [editGrade, setEditGrade] = useState<Grade | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [editAnnualDays, setEditAnnualDays] = useState(21);
  const [deleteGrade, setDeleteGrade] = useState<Grade | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [newGradeName, setNewGradeName] = useState('');
  const [newAnnualDays, setNewAnnualDays] = useState(21);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  useEffect(() => {
    loadGrades();
  }, []);

  const loadGrades = async () => {
    try {
      setLoading(true);
      const data = await gradesApi.getAllGrades();
      setGrades(data || []);
    } catch (error) {
      console.error('Error loading grades:', error);
      showError('Failed to load grades');
    } finally {
      setLoading(false);
    }
  };

  const handleViewGrade = (grade: Grade) => {
    setViewGrade(grade);
    setIsViewModalOpen(true);
  };

  const handleEditGrade = (grade: Grade) => {
    setEditGrade(grade);
    setEditName(grade.name);
    setEditAnnualDays(grade.annual_leave_days);
    setIsEditModalOpen(true);
  };

  const handleSaveEdit = async () => {
    if (!editGrade || !editName.trim()) return;
    try {
      await gradesApi.updateGrade(editGrade.id, { name: editName.trim(), annual_leave_days: editAnnualDays });
      setGrades(prev => prev.map(g => g.id === editGrade.id ? { ...g, name: editName.trim(), annual_leave_days: editAnnualDays } : g));
      setIsEditModalOpen(false);
      setEditGrade(null);
      success('Grade updated successfully');
    } catch (err: any) {
      showError(err.response?.data?.detail || 'Failed to update grade');
    }
  };

  const handleDeleteGrade = (grade: Grade) => {
    setDeleteGrade(grade);
    setIsDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!deleteGrade) return;
    try {
      await gradesApi.deleteGrade(deleteGrade.id);
      setGrades(prev => prev.filter(g => g.id !== deleteGrade.id));
      setIsDeleteModalOpen(false);
      setDeleteGrade(null);
      success('Grade deleted successfully');
    } catch (err: any) {
      showError(err.response?.data?.detail || 'Failed to delete grade');
    }
  };

  const handleAddGrade = async () => {
    if (!newGradeName.trim()) return;
    try {
      setIsCreating(true);
      console.log('Creating grade with:', { name: newGradeName.trim(), annual_leave_days: newAnnualDays });
      const created = await gradesApi.createGrade({ name: newGradeName.trim(), annual_leave_days: newAnnualDays });
      console.log('Grade created response:', created);
      setGrades(prev => [...prev, created]);
      setIsCreateModalOpen(false);
      setNewGradeName('');
      setNewAnnualDays(21);
      success('Grade created successfully');
    } catch (err: any) {
      console.log('Grade create error:', err);
      console.log('Error response:', err.response);
      console.log('Error data:', err.response?.data);
      showError(err.response?.data?.detail || 'Failed to create grade');
    } finally {
      setIsCreating(false);
    }
  };

  const getGradeColor = (index: number) => {
    const colors = ['bg-sky-blue', 'bg-purple-500', 'bg-green-500', 'bg-yellow-500', 'bg-red-500', 'bg-indigo-500'];
    return colors[index % colors.length];
  };

  const columns: Column<Grade>[] = [
    {
      key: 'name',
      label: 'Grade',
      sortable: true,
      filterable: true,
      render: (_, row, index) => (
        <div className="flex items-center space-x-3">
          <div className={`w-10 h-10 ${getGradeColor(index)} rounded-xl flex items-center justify-center`}>
            <Award className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-medium text-text-dark dark:text-text-dark-light">
              {row.name}
            </p>
          </div>
        </div>
      )
    },
    {
      key: 'annual_leave_days',
      label: 'Annual Leave',
      sortable: true,
      filterable: false,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <Calendar className="w-4 h-4 text-text-grey dark:text-text-grey-dark" />
          <span className="text-text-dark dark:text-text-dark-light font-medium">
            {value} days
          </span>
        </div>
      )
    }
  ];

  const actions: Action<Grade>[] = [
    {
      label: 'View',
      icon: <Eye className="w-4 h-4" />,
      onClick: handleViewGrade,
      variant: 'primary'
    },
    {
      label: 'Edit',
      icon: <Edit className="w-4 h-4" />,
      onClick: handleEditGrade,
      variant: 'secondary'
    },
    {
      label: 'Delete',
      icon: <Trash2 className="w-4 h-4" />,
      onClick: handleDeleteGrade,
      variant: 'danger'
    }
  ];

  const totalLeaveDays = grades.reduce((sum, g) => sum + g.annual_leave_days, 0);
  const avgLeaveDays = grades.length > 0 ? Math.round(totalLeaveDays / grades.length) : 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Staff Grades
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage staff grades and annual leave entitlements
          </p>
        </div>
        <button
          onClick={() => setIsCreateModalOpen(true)}
          className="btn-primary flex items-center space-x-2"
        >
          <Plus className="w-4 h-4" />
          <span>Add Grade</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatsCard
          label="Total Grades"
          value={grades.length}
          icon={<Award className="w-6 h-6 text-sky-blue" />}
          iconBgColor="bg-sky-blue"
        />
        <StatsCard
          label="Avg Annual Leave"
          value={`${avgLeaveDays} days`}
          icon={<Calendar className="w-6 h-6 text-green-600 dark:text-green-400" />}
          iconBgColor="bg-green-100 dark:bg-green-900"
          valueColor="text-green-600"
        />
        <StatsCard
          label="Max Leave"
          value={`${Math.max(...grades.map(g => g.annual_leave_days), 0)} days`}
          icon={<Calendar className="w-6 h-6 text-purple-600 dark:text-purple-400" />}
          iconBgColor="bg-purple-100 dark:bg-purple-900"
          valueColor="text-purple-600"
        />
      </div>

      <DataTable
        data={grades}
        columns={columns}
        actions={actions}
        loading={loading}
        emptyMessage="No grades found. Create your first grade to get started."
      />

      {/* View Grade Modal */}
      {isViewModalOpen && viewGrade && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Grade Details</h2>
              <button onClick={() => { setIsViewModalOpen(false); setViewGrade(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 ${getGradeColor(grades.findIndex(g => g.id === viewGrade.id))} rounded-xl flex items-center justify-center`}>
                  <Award className="w-6 h-6 text-white" />
                </div>
                <div>
                  <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{viewGrade.name}</p>
                  <p className="text-sm text-text-grey dark:text-text-grey-dark">Annual Leave: {viewGrade.annual_leave_days} days</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Grade Modal */}
      {isEditModalOpen && editGrade && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Edit Grade</h2>
              <button onClick={() => { setIsEditModalOpen(false); setEditGrade(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Grade Name</label>
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="input-field w-full"
                  placeholder="Enter grade name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Annual Leave Days</label>
                <input
                  type="number"
                  value={editAnnualDays}
                  onChange={(e) => setEditAnnualDays(parseInt(e.target.value) || 0)}
                  className="input-field w-full"
                  min="0"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsEditModalOpen(false); setEditGrade(null); }} className="btn-outline">Cancel</button>
                <button onClick={handleSaveEdit} className="btn-primary">Save Changes</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Grade Modal */}
      {isDeleteModalOpen && deleteGrade && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-red-600">Delete Grade</h2>
              <button onClick={() => { setIsDeleteModalOpen(false); setDeleteGrade(null); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-text-dark dark:text-text-dark-light">
                Are you sure you want to delete the grade <strong>"{deleteGrade.name}"</strong>?
              </p>
              <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                <p className="text-sm text-red-700 dark:text-red-400">
                  This will remove {deleteGrade.annual_leave_days} days annual leave from all staff with this grade.
                </p>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsDeleteModalOpen(false); setDeleteGrade(null); }} className="btn-outline">Cancel</button>
                <button onClick={handleConfirmDelete} className="btn-danger">Delete Grade</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Create Grade Modal */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">Create New Grade</h2>
              <button onClick={() => { setIsCreateModalOpen(false); setNewGradeName(''); setNewAnnualDays(21); }} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Grade Name</label>
                <input
                  type="text"
                  value={newGradeName}
                  onChange={(e) => setNewGradeName(e.target.value)}
                  className="input-field w-full"
                  placeholder="e.g., Grade 1, Senior Staff"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Annual Leave Days</label>
                <input
                  type="number"
                  value={newAnnualDays}
                  onChange={(e) => setNewAnnualDays(parseInt(e.target.value) || 0)}
                  className="input-field w-full"
                  min="0"
                  onKeyDown={(e) => { if (e.key === 'Enter') handleAddGrade(); }}
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => { setIsCreateModalOpen(false); setNewGradeName(''); setNewAnnualDays(21); }} className="btn-outline">Cancel</button>
                <button onClick={handleAddGrade} disabled={isCreating || !newGradeName.trim()} className="btn-primary">
                  {isCreating ? 'Creating...' : 'Create Grade'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Grades;