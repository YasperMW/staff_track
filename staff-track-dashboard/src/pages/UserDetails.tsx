import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Calendar, Clock, MapPin, Mail, Phone, User as UserIcon, Building, TrendingUp, Minus, FileText, Download, Eye, Lock, Unlock, Trash2 } from 'lucide-react';
import type { User, UserDocument } from '../services/api';
import { usersApi } from '../services/api';
import EmptyState from '../components/EmptyState';
import { useSystemAdmin } from '../hooks/useSystemAdmin';
import { useToast } from '../contexts/ToastContext';

interface AttendanceRecord {
  attendance_log_id: string;
  date: string;
  check_in_time: string;
  check_out_time?: string;
  work_hours?: number;
  status: string;
  shift_type?: string;
  location?: string;
}

const UserDetails: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const { isSystemAdmin } = useSystemAdmin();
  const toast = useToast();
  const [user, setUser] = useState<User | null>(null);
  const [documents, setDocuments] = useState<UserDocument[]>([]);
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'details' | 'attendance' | 'documents'>('details');
  const [showLockModal, setShowLockModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [lockDuration, setLockDuration] = useState<string>('');
  const [lockPassword, setLockPassword] = useState('');
  const [deletePassword, setDeletePassword] = useState('');
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    if (userId) {
      loadUserDetails();
      loadAttendanceHistory();
    }
  }, [userId]);

  const loadUserDetails = async () => {
    try {
      setLoading(true);
      // Use the new API endpoint
      const response = await usersApi.getUserDetails(userId!);
      setUser(response.user);
      setDocuments(response.documents);
    } catch (error) {
      console.error('Error loading user details:', error);
      // Optionally navigate back to users page
      navigate('/users');
    } finally {
      setLoading(false);
    }
  };

  const loadAttendanceHistory = async () => {
    try {
      setLoading(true);
      // Mock attendance data for demonstration
      const mockAttendance: AttendanceRecord[] = [
        {
          attendance_log_id: '1',
          date: '2024-03-14',
          check_in_time: '08:45',
          check_out_time: '17:30',
          work_hours: 8.75,
          status: 'present',
          shift_type: 'Day Shift',
          location: 'Office - Main Building'
        },
        {
          attendance_log_id: '2',
          date: '2024-03-13',
          check_in_time: '09:15',
          check_out_time: '17:45',
          work_hours: 8.5,
          status: 'late',
          shift_type: 'Day Shift',
          location: 'Office - Main Building'
        },
        {
          attendance_log_id: '3',
          date: '2024-03-12',
          check_in_time: '08:30',
          check_out_time: '17:00',
          work_hours: 8.5,
          status: 'present',
          shift_type: 'Day Shift',
          location: 'Office - Main Building'
        },
        {
          attendance_log_id: '4',
          date: '2024-03-11',
          check_in_time: '08:50',
          check_out_time: undefined,
          work_hours: undefined,
          status: 'absent',
          shift_type: undefined,
          location: undefined
        },
        {
          attendance_log_id: '5',
          date: '2024-03-10',
          check_in_time: '08:40',
          check_out_time: '17:20',
          work_hours: 8.67,
          status: 'present',
          shift_type: 'Day Shift',
          location: 'Office - Main Building'
        }
      ];
      setAttendance(mockAttendance);
    } catch (error) {
      console.error('Error loading attendance history:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusColors = {
      'present': 'status-present',
      'late': 'status-late',
      'absent': 'status-absent',
      'half_day': 'status-pending'
    };
    
    return (
      <span className={`status-badge ${statusColors[status as keyof typeof statusColors] || statusColors.present}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const getRoleBadge = (roleName: string) => {
    const roleColors = {
      'admin': 'bg-gradient-to-r from-purple-400 to-purple-600 text-white',
      'hr': 'bg-gradient-to-r from-blue-400 to-blue-600 text-white',
      'manager': 'bg-gradient-to-r from-indigo-400 to-indigo-600 text-white',
      'employee': 'bg-gradient-to-r from-gray-400 to-gray-600 text-white'
    };
    
    return (
      <span className={`status-badge ${roleColors[roleName.toLowerCase() as keyof typeof roleColors] || roleColors.employee}`}>
        {roleName}
      </span>
    );
  };

  const formatDate = (dateString: string | null | undefined) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'short',
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const calculateStats = () => {
    const totalDays = attendance.length;
    const presentDays = attendance.filter(a => a.status === 'present').length;
    const lateDays = attendance.filter(a => a.status === 'late').length;
    const absentDays = attendance.filter(a => a.status === 'absent').length;
    const totalHours = attendance.reduce((sum, a) => sum + (a.work_hours || 0), 0);
    const avgHours = totalDays > 0 ? totalHours / presentDays : 0;

    return {
      totalDays,
      presentDays,
      lateDays,
      absentDays,
      totalHours: Math.round(totalHours * 100) / 100,
      avgHours: Math.round(avgHours * 100) / 100,
      attendanceRate: totalDays > 0 ? Math.round((presentDays / totalDays) * 100) : 0
    };
  };

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-pulse">
          <div className="w-16 h-16 bg-gray-200 rounded-full"></div>
        </div>
      </div>
    );
  }

  const handleLockAccount = async () => {
    if (!lockPassword) {
      toast.error('Please enter your password to confirm');
      return;
    }
    setProcessing(true);
    try {
      const duration = lockDuration ? parseInt(lockDuration) : null;
      await usersApi.lockUserAccount(userId!, duration, lockPassword);
      toast.success(duration ? `Account locked for ${duration} minutes` : 'Account lock removed');
      setShowLockModal(false);
      setLockDuration('');
      setLockPassword('');
      loadUserDetails();
    } catch (error: any) {
      toast.error(error.response?.data?.detail || 'Failed to lock account');
    } finally {
      setProcessing(false);
    }
  };

  const handleDeleteAccount = async () => {
    if (!deletePassword) {
      toast.error('Please enter your password to confirm');
      return;
    }
    setProcessing(true);
    try {
      await usersApi.hardDeleteUserAccount(userId!, deletePassword);
      toast.success('Account permanently deleted');
      navigate('/users');
    } catch (error: any) {
      toast.error(error.response?.data?.detail || 'Failed to delete account');
    } finally {
      setProcessing(false);
    }
  };

  const stats = calculateStats();

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="header-gradient">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate(-1)}
                className="p-2 hover:bg-white hover:bg-opacity-10 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5 text-white" />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-white">User Details</h1>
                <p className="text-blue-100">Complete profile and attendance information</p>
              </div>
            </div>
            <div className="w-12 h-12 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
              <span className="text-white text-lg font-bold">
                {user.first_name.charAt(0)}{user.surname.charAt(0)}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* User Info Card */}
        <div className="card mb-8">
          <div className="flex flex-col lg:flex-row gap-8">
            {/* Left Column - Basic Info */}
            <div className="flex-1">
              <div className="flex items-center space-x-6 mb-6">
                <div className="w-20 h-20 avatar-gradient rounded-full flex items-center justify-center">
                  <span className="text-white text-2xl font-bold">
                    {user.first_name.charAt(0)}{user.surname.charAt(0)}
                  </span>
                </div>
                <div>
                  <h2 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
                    {user.first_name} {user.surname}
                  </h2>
                  <p className="text-lg text-gray-600 dark:text-gray-400">{user.employee_number}</p>
                   <div className="flex items-center space-x-3 mt-2">
                     {getRoleBadge(user.role_name)}
                     <span className={`status-badge ${user.status === 'active' ? 'status-active' : 'status-inactive'}`}>
                       {user.status.charAt(0).toUpperCase() + user.status.slice(1)}
                     </span>
                   </div>
                 </div>
               </div>

               {isSystemAdmin && (
                 <div className="flex items-center space-x-3 mb-6">
                   <button
                     onClick={() => setShowLockModal(true)}
                     className="flex items-center space-x-2 px-4 py-2 bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition-colors"
                   >
                     {user.locked_until ? <Unlock className="w-4 h-4" /> : <Lock className="w-4 h-4" />}
                     <span>{user.locked_until ? 'Unlock Account' : 'Lock Account'}</span>
                   </button>
                   <button
                     onClick={() => setShowDeleteModal(true)}
                     className="flex items-center space-x-2 px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
                   >
                     <Trash2 className="w-4 h-4" />
                     <span>Delete Account</span>
                   </button>
                 </div>
               )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Contact Information</h3>
                  <div className="space-y-4">
                    <div className="flex items-center space-x-3">
                      <Mail className="w-5 h-5 text-gray-400" />
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Email</p>
                        <p className="font-medium text-gray-900 dark:text-gray-100">{user.email}</p>
                      </div>
                    </div>
                    {user.contact_number && (
                      <div className="flex items-center space-x-3">
                        <Phone className="w-5 h-5 text-gray-400" />
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">Phone</p>
                          <p className="font-medium text-gray-900 dark:text-gray-100">{user.contact_number}</p>
                        </div>
                      </div>
                    )}
                    {user.current_address && (
                      <div className="flex items-center space-x-3">
                        <MapPin className="w-5 h-5 text-gray-400" />
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">Address</p>
                          <p className="font-medium text-gray-900 dark:text-gray-100">{user.current_address}</p>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Work Information</h3>
                  <div className="space-y-4">
                    <div className="flex items-center space-x-3">
                      <Building className="w-5 h-5 text-gray-400" />
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Department</p>
                        <p className="font-medium text-gray-900 dark:text-gray-100">
                          {user.department_name || 'Unassigned'}
                        </p>
                      </div>
                    </div>
                    {user.designation && (
                      <div className="flex items-center space-x-3">
                        <UserIcon className="w-5 h-5 text-gray-400" />
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">Designation</p>
                          <p className="font-medium text-gray-900 dark:text-gray-100">{user.designation}</p>
                        </div>
                      </div>
                    )}
                    <div className="flex items-center space-x-3">
                      <Calendar className="w-5 h-5 text-gray-400" />
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Employment Date</p>
                        <p className="font-medium text-gray-900 dark:text-gray-100">
                          {user.date_of_employment ? new Date(user.date_of_employment).toLocaleDateString() : 'N/A'}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-8">
          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Total Days</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">{stats.totalDays}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center">
                <Calendar className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Present Days</p>
                <p className="text-2xl font-bold text-green-600">{stats.presentDays}</p>
              </div>
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Late Days</p>
                <p className="text-2xl font-bold text-amber-600">{stats.lateDays}</p>
              </div>
              <div className="w-12 h-12 bg-amber-100 dark:bg-amber-900 rounded-xl flex items-center justify-center">
                <Clock className="w-6 h-6 text-amber-600 dark:text-amber-400" />
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Absent Days</p>
                <p className="text-2xl font-bold text-red-600">{stats.absentDays}</p>
              </div>
              <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-xl flex items-center justify-center">
                <Minus className="w-6 h-6 text-red-600 dark:text-red-400" />
              </div>
            </div>
          </div>

          <div className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Attendance Rate</p>
                <p className="text-2xl font-bold text-purple-600">{stats.attendanceRate}%</p>
              </div>
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="card">
          <div className="border-b border-gray-200 dark:border-gray-700">
            <nav className="flex space-x-8">
              <button
                onClick={() => setActiveTab('details')}
                className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === 'details'
                    ? 'border-sky-blue text-sky-blue'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                Personal Details
              </button>
              <button
                onClick={() => setActiveTab('attendance')}
                className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === 'attendance'
                    ? 'border-sky-blue text-sky-blue'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                Attendance History
              </button>
              <button
                onClick={() => setActiveTab('documents')}
                className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === 'documents'
                    ? 'border-sky-blue text-sky-blue'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                Documents
              </button>
            </nav>
          </div>

          {/* Tab Content */}
          <div className="p-6">
            {activeTab === 'details' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Additional Information</h3>
                  <div className="space-y-3">
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Date of Birth</p>
                      <p className="font-medium text-gray-900 dark:text-gray-100">
                        {user.date_of_birth ? new Date(user.date_of_birth).toLocaleDateString() : 'N/A'}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Gender</p>
                      <p className="font-medium text-gray-900 dark:text-gray-100">{user.gender || 'N/A'}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Last Login</p>
                      <p className="font-medium text-gray-900 dark:text-gray-100">
                        {user.last_login_at ? new Date(user.last_login_at).toLocaleString() : 'Never'}
                      </p>
                    </div>
                  </div>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">System Information</h3>
                  <div className="space-y-3">
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Registration Date</p>
                      <p className="font-medium text-gray-900 dark:text-gray-100">
                        {new Date(user.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Head of Department</p>
                      <p className="font-medium text-gray-900 dark:text-gray-100">
                        {user.is_head_of_department ? 'Yes' : 'No'}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">Account Status</p>
                      <span className={`status-badge ${user.status === 'active' ? 'status-active' : 'status-inactive'}`}>
                        {user.status.charAt(0).toUpperCase() + user.status.slice(1)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'attendance' && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">Attendance History</h3>
                {loading ? (
                  <div className="space-y-4">
                    {[...Array(5)].map((_, i) => (
                      <div key={i} className="h-20 bg-gray-200 dark:bg-gray-700 rounded-lg animate-pulse"></div>
                    ))}
                  </div>
                ) : attendance.length === 0 ? (
                  <EmptyState variant="attendance" />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b border-gray-200 dark:border-gray-700">
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Date</th>
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Check In</th>
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Check Out</th>
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Hours</th>
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Status</th>
                          <th className="text-left p-3 font-medium text-gray-700 dark:text-gray-300">Shift</th>
                        </tr>
                      </thead>
                      <tbody>
                        {attendance.map((record) => (
                          <tr key={record.attendance_log_id} className="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800">
                            <td className="p-3">{formatDate(record.date)}</td>
                            <td className="p-3">{record.check_in_time}</td>
                            <td className="p-3">{record.check_out_time || '-'}</td>
                            <td className="p-3">{record.work_hours || '-'}</td>
                            <td className="p-3">{getStatusBadge(record.status)}</td>
                            <td className="p-3">{record.shift_type || '-'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'documents' && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">User Documents</h3>
                {loading ? (
                  <div className="space-y-4">
                    {[...Array(3)].map((_, i) => (
                      <div key={i} className="h-24 bg-gray-200 dark:bg-gray-700 rounded-lg animate-pulse"></div>
                    ))}
                  </div>
                ) : documents.length === 0 ? (
                  <EmptyState variant="default" title="No documents uploaded" description="Documents will appear here once uploaded." />
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {documents.map((doc) => (
                      <div key={doc.document_id} className="card p-6 hover:shadow-lg transition-shadow">
                        <div className="flex items-start justify-between mb-4">
                          <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                            <FileText className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                          </div>
                        </div>
                        <h4 className="font-semibold text-gray-900 dark:text-gray-100 mb-2">
                          {doc.file_name}
                        </h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                          {doc.document_type}
                        </p>
                        <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mb-4">
                          <span>Uploaded</span>
                          <span>{new Date(doc.upload_date).toLocaleDateString()}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <button className="flex items-center space-x-1 px-3 py-2 text-sm bg-sky-blue text-white rounded-lg hover:bg-sky-blue/90 transition-colors">
                            <Eye className="w-4 h-4" />
                            <span>View</span>
                          </button>
                          <button className="flex items-center space-x-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                            <Download className="w-4 h-4" />
                            <span>Download</span>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Lock Account Modal */}
      {showLockModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-screen items-center justify-center p-4">
            <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowLockModal(false)} />
            <div className="relative w-full max-w-md bg-white dark:bg-gray-800 rounded-xl shadow-xl">
              <div className="p-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                  {user.locked_until ? 'Unlock Account' : 'Lock Account'}
                </h2>
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  {user.locked_until
                    ? `Remove the lock on ${user.first_name} ${user.surname}'s account?`
                    : `Set a temporary lock on ${user.first_name} ${user.surname}'s account.`}
                </p>
                {!user.locked_until && (
                  <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Lock Duration (minutes) - leave empty to unlock manually later
                    </label>
                    <input
                      type="number"
                      value={lockDuration}
                      onChange={(e) => setLockDuration(e.target.value)}
                      placeholder="e.g. 30"
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                      min="1"
                    />
                  </div>
                )}
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Your Password (confirmation)
                  </label>
                  <input
                    type="password"
                    value={lockPassword}
                    onChange={(e) => setLockPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  />
                </div>
                <div className="flex justify-end space-x-3">
                  <button
                    onClick={() => { setShowLockModal(false); setLockDuration(''); setLockPassword(''); }}
                    className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                    disabled={processing}
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleLockAccount}
                    className="px-4 py-2 bg-amber-500 text-white rounded-lg hover:bg-amber-600 disabled:opacity-50"
                    disabled={processing}
                  >
                    {processing ? 'Processing...' : user.locked_until ? 'Unlock' : 'Lock'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Account Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-screen items-center justify-center p-4">
            <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowDeleteModal(false)} />
            <div className="relative w-full max-w-md bg-white dark:bg-gray-800 rounded-xl shadow-xl">
              <div className="p-6">
                <h2 className="text-xl font-semibold text-red-600 mb-4">
                  Delete Account Permanently
                </h2>
                <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                  <p className="text-sm text-red-800 dark:text-red-300">
                    Warning: This action cannot be undone. This will permanently delete the account
                    <strong> {user.first_name} {user.surname}</strong> ({user.email}) and all associated data.
                  </p>
                </div>
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Your Password (confirmation)
                  </label>
                  <input
                    type="password"
                    value={deletePassword}
                    onChange={(e) => setDeletePassword(e.target.value)}
                    placeholder="Enter your password"
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  />
                </div>
                <div className="flex justify-end space-x-3">
                  <button
                    onClick={() => { setShowDeleteModal(false); setDeletePassword(''); }}
                    className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                    disabled={processing}
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleDeleteAccount}
                    className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                    disabled={processing}
                  >
                    {processing ? 'Processing...' : 'Delete Permanently'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserDetails;
