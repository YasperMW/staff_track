import React, { useState, useEffect } from 'react';
import { attendanceApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import DataTable from '../components/DataTable';
import type { Column, Action } from '../components/DataTable';
import { 
  Clock, 
  Users, 
  TrendingDown, 
  AlertTriangle, 
  CheckCircle, 
  XCircle,
  Download,
  RefreshCw,
  X,
  MapPin,
  User,
  Building,
  Calendar,
  List,
  Table
} from 'lucide-react';

interface AttendanceRecord {
  id: string;
  user_id: string;
  user_name: string;
  employee_number: string;
  department: string;
  check_in_time: string;
  check_out_time?: string;
  check_in_location?: string;
  check_out_location?: string;
  status: 'present' | 'absent' | 'late' | 'early_checkout' | 'active' | 'completed';
  work_hours?: number;
  shift_type?: string;
  late_reason?: string;
  early_checkout_reason?: string;
  date: string;
}

const Attendance: React.FC = () => {
  const { success, error: showError } = useToast();
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedRecord, setSelectedRecord] = useState<AttendanceRecord | null>(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [stats, setStats] = useState({
    total: 0,
    present: 0,
    absent: 0,
    late: 0,
    earlyCheckout: 0,
    averageHours: 0
  });
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 100,
    total: 0
  });
  const [viewType, setViewType] = useState<'summary' | 'full'>('summary');

  useEffect(() => {
    loadAttendance();
  }, [startDate, endDate, viewType]);

  useEffect(() => {
    // No need to update work hours periodically since API provides them
    return () => {};
  }, []);

  const loadAttendance = async () => {
    try {
      setLoading(true);
      
      // Use new endpoint with date filtering and view type
      const response = await attendanceApi.getAllStaffAttendance(startDate, endDate, viewType, pagination.page, pagination.limit);
      console.log('Attendance Response:', response);
      
      // Process based on view type
      let attendanceData: AttendanceRecord[] = [];
      
      if (viewType === 'full') {
        // Full view - all individual records
        attendanceData = (response?.records || []).map((record: any) => {
          console.log('Full record:', record);
          let status: string = record.status?.toLowerCase() || 'absent';
          if (status === 'active') status = 'present';
          if (status === 'completed') status = 'present';
          
          return {
            id: record.attendance_log_id || record.user_id,
            user_id: record.user_id,
            user_name: record.name || 'Unknown',
            employee_number: record.employee_number || 'N/A',
            department: record.department || 'Unknown',
            check_in_time: record.check_in_time,
            check_out_time: record.check_out_time,
            status: status,
            work_hours: record.work_hours || 0,
            shift_type: record.shift_type,
            late_reason: record.late_reason,
            early_checkout_reason: record.early_checkout_reason,
            date: record.date || startDate
          };
        });
      } else {
        // Summary view - one row per employee
        attendanceData = (response?.staff || []).map((staff: any) => {
          console.log('Summary staff:', staff);
          let status: string = staff.status?.toLowerCase() || 'absent';
          if (status === 'active') status = 'present';
          if (status === 'completed') status = 'present';
          
          return {
            id: staff.user_id,
            user_id: staff.user_id,
            user_name: staff.name || 'Unknown',
            employee_number: staff.employee_number || 'N/A',
            department: staff.department || 'Unknown',
            check_in_time: staff.check_in_time,
            check_out_time: staff.check_out_time,
            status: status,
            work_hours: staff.work_hours || 0,
            shift_type: staff.shift_type,
            late_reason: staff.late_reason,
            early_checkout_reason: staff.early_checkout_reason,
            date: staff.date || startDate
          };
        });
      }
      
      console.log('Attendance data:', attendanceData);
      
      setAttendance(attendanceData);
      
      // Update pagination info
      setPagination(prev => ({
        ...prev,
        page: response.page || 1,
        total: response.total || 0
      }));
      
      // Calculate stats
      const totalCount = viewType === 'summary' 
        ? (response.total || 0)  // Total staff for summary
        : attendanceData.length;  // Total records for full view
      
      const completed = attendanceData.filter(r => r.status === 'completed').length;
      const active = attendanceData.filter(r => r.status === 'active').length;
      const late = attendanceData.filter(r => r.status === 'late').length;
      const absent = attendanceData.filter(r => r.status === 'absent').length;
      const earlyCheckout = attendanceData.filter(r => r.early_checkout_reason).length;
      const avgHours = attendanceData.length > 0 ? attendanceData.reduce((sum, r) => sum + (r.work_hours || 0), 0) / attendanceData.length : 0;
      
      setStats({
        total: totalCount,
        present: viewType === 'summary' ? (completed + active + late) : completed,
        absent: viewType === 'summary' ? absent : active,  // full view shows incomplete (no checkout)
        late,
        earlyCheckout,
        averageHours: avgHours
      });
      
    } catch (err) {
      console.error('Error loading attendance:', err);
      showError('Failed to load attendance data');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = () => {
    try {
      // Export attendance data as CSV
      const headers = ['Employee Name', 'Employee Number', 'Department', 'Check-in Time', 'Check-out Time', 'Status', 'Work Hours', 'Shift Type', 'Date'];
      
      const csvData = attendance.map(record => [
        record.user_name,
        record.employee_number,
        record.department,
        record.check_in_time || 'N/A',
        record.check_out_time || 'Not checked out',
        record.status,
        record.work_hours?.toFixed(2) || '0.00',
        record.shift_type || 'N/A',
        record.date || startDate
      ]);
      
      // Create CSV content
      const csvContent = [
        headers.join(','),
        ...csvData.map(row => row.map(cell => `"${cell}"`).join(','))
      ].join('\n');
      
      // Create and download file
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', `attendance_${startDate}_to_${endDate}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      success('Attendance data exported successfully');
    } catch (err: any) {
      showError('Failed to export attendance data');
    }
  };

  const handleRefresh = () => {
    loadAttendance();
    success('Attendance data refreshed');
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'present':
      case 'completed':
        return <CheckCircle className="w-5 h-5" />;
      case 'absent':
        return <XCircle className="w-5 h-5" />;
      case 'late':
        return <AlertTriangle className="w-5 h-5" />;
      case 'early_checkout':
        return <TrendingDown className="w-5 h-5" />;
      case 'active':
        return <Clock className="w-5 h-5" />;
      default:
        return <Clock className="w-5 h-5" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'present':
      case 'completed':
        return 'text-green-600 bg-green-100 dark:bg-green-900 dark:text-green-400';
      case 'absent':
        return 'text-red-600 bg-red-100 dark:bg-red-900 dark:text-red-400';
      case 'late':
        return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-400';
      case 'early_checkout':
        return 'text-orange-600 bg-orange-100 dark:bg-orange-900 dark:text-orange-400';
      case 'active':
        return 'text-blue-600 bg-blue-100 dark:bg-blue-900 dark:text-blue-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const formatTime = (timeString: string | null | undefined) => {
    if (!timeString) return '—';
    // If it's already in "HH:MM" format, return it directly
    if (/^\d{2}:\d{2}$/.test(timeString)) {
      return timeString;
    }
    // Otherwise try to parse as date
    try {
      const date = new Date(timeString);
      if (isNaN(date.getTime())) return timeString;
      return date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return timeString;
    }
  };

  const columns: Column<AttendanceRecord>[] = [
    {
      key: 'user_name',
      label: 'Employee',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-sky-blue rounded-full flex items-center justify-center">
            <span className="text-white text-xs font-bold">
              {row.user_name.split(' ').map(n => n[0]).join('')}
            </span>
          </div>
          <div>
            <p className="font-medium text-text-dark dark:text-text-dark-light">
              {row.user_name}
            </p>
            <p className="text-sm text-text-grey dark:text-text-grey-dark">
              {row.employee_number}
            </p>
          </div>
        </div>
      )
    },
    {
      key: 'department',
      label: 'Department',
      sortable: true,
      filterable: true,
      render: (value) => (
        <span className="text-sm text-text-dark dark:text-text-dark-light">
          {value}
        </span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      filterable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <div className={`p-1 rounded-full ${getStatusColor(value)}`}>
            {getStatusIcon(value)}
          </div>
          <span className="text-sm font-medium capitalize">
            {value.replace('_', ' ')}
          </span>
        </div>
      )
    },
    {
      key: 'check_in_time',
      label: 'Check In',
      sortable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <Clock className="w-4 h-4 text-text-grey" />
          <span className="text-sm text-text-dark dark:text-text-dark-light">
            {value ? formatTime(value) : '—'}
          </span>
        </div>
      )
    },
    {
      key: 'check_out_time',
      label: 'Check Out',
      sortable: true,
      render: (value) => value ? (
        <div className="flex items-center space-x-2">
          <Clock className="w-4 h-4 text-text-grey" />
          <span className="text-sm text-text-dark dark:text-text-dark-light">
            {formatTime(value)}
          </span>
        </div>
      ) : (
        <span className="text-sm text-text-grey dark:text-text-grey-dark">
          Not checked out
        </span>
      )
    },
    {
      key: 'shift_type',
      label: 'Shift',
      sortable: true,
      filterable: true,
      render: (value) => (
        <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
          {value || 'Not assigned'}
        </span>
      )
    },
    {
      key: 'work_hours',
      label: 'Hours',
      sortable: true,
      render: (value) => (
        <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
          {value?.toFixed(2) || '0.00'}h
        </span>
      )
    }
  ];

  const actions: Action<AttendanceRecord>[] = [
    {
      label: 'View Details',
      icon: <Users className="w-4 h-4" />,
      onClick: (record) => {
        setSelectedRecord(record);
        setIsDetailModalOpen(true);
      },
      variant: 'primary'
    }
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Attendance Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Monitor and manage employee attendance records
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          {/* Single date picker for Summary, dual for Full */}
          {viewType === 'summary' ? (
            <div className="relative">
              <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-text-grey" />
              <input
                type="date"
                value={startDate}
                onChange={(e) => {
                  setStartDate(e.target.value);
                  setEndDate(e.target.value);
                }}
                className="input-field pl-10"
              />
            </div>
          ) : (
            <div className="flex items-center space-x-2">
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-text-grey" />
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="input-field pl-10"
                  max={endDate}
                />
              </div>
              <span className="text-text-grey">to</span>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-text-grey" />
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="input-field pl-10"
                  min={startDate}
                />
              </div>
            </div>
          )}
          
          {/* View Toggle */}
          <div className="flex items-center bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
            <button
              onClick={() => setViewType('summary')}
              className={`flex items-center space-x-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                viewType === 'summary'
                  ? 'bg-white dark:bg-gray-700 text-sky-blue shadow-sm'
                  : 'text-text-grey dark:text-text-grey-dark hover:text-text-dark dark:hover:text-text-dark-light'
              }`}
            >
              <Table className="w-4 h-4" />
              <span>Summary</span>
            </button>
            <button
              onClick={() => setViewType('full')}
              className={`flex items-center space-x-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                viewType === 'full'
                  ? 'bg-white dark:bg-gray-700 text-sky-blue shadow-sm'
                  : 'text-text-grey dark:text-text-grey-dark hover:text-text-dark dark:hover:text-text-dark-light'
              }`}
            >
              <List className="w-4 h-4" />
              <span>Full Records</span>
            </button>
          </div>
          
          <button 
            onClick={handleRefresh}
            className="btn-outline flex items-center space-x-2"
          >
            <RefreshCw className="w-4 h-4" />
            <span>Refresh</span>
          </button>
          <button 
            onClick={handleExport}
            className="btn-outline flex items-center space-x-2"
          >
            <Download className="w-4 h-4" />
            <span>Export</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">
                {viewType === 'summary' ? 'Total Staff' : 'Total Records'}
              </p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {stats.total}
              </p>
            </div>
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">
                {viewType === 'summary' ? 'Present' : 'Completed'}
              </p>
              <p className="text-2xl font-bold text-green-600">
                {stats.present}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">
                {viewType === 'summary' ? 'Absent' : 'Incomplete'}
              </p>
              <p className="text-2xl font-bold text-red-600">
                {stats.absent}
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-xl flex items-center justify-center">
              <XCircle className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Late</p>
              <p className="text-2xl font-bold text-yellow-600">
                {stats.late}
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-xl flex items-center justify-center">
              <AlertTriangle className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Avg Hours</p>
              <p className="text-2xl font-bold text-purple-600">
                {stats.averageHours.toFixed(1)}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <Clock className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Attendance Table */}
      <DataTable
        data={attendance}
        columns={columns}
        actions={actions}
        loading={loading}
        emptyMessage="No attendance records found for the selected date."
      />

      {/* Detail Modal */}
      {isDetailModalOpen && selectedRecord && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold text-text-dark dark:text-text-dark-light">
                Attendance Details
              </h2>
              <button
                onClick={() => { setIsDetailModalOpen(false); setSelectedRecord(null); }}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-text-grey" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* Employee Info */}
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4">
                <h3 className="text-sm font-semibold text-text-grey dark:text-text-grey-dark uppercase tracking-wide mb-3">Employee Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex items-center gap-3">
                    <User className="w-4 h-4 text-sky-blue" />
                    <div>
                      <p className="text-xs text-text-grey dark:text-text-grey-dark">Name</p>
                      <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.user_name}</p>
                    </div>
                  </div>
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Employee ID</p>
                    <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.employee_number}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <Building className="w-4 h-4 text-sky-blue" />
                    <div>
                      <p className="text-xs text-text-grey dark:text-text-grey-dark">Department</p>
                      <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.department}</p>
                    </div>
                  </div>
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Shift</p>
                    <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.shift_type || 'Not assigned'}</p>
                  </div>
                </div>
              </div>

              {/* Status */}
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4">
                <h3 className="text-sm font-semibold text-text-grey dark:text-text-grey-dark uppercase tracking-wide mb-3">Status</h3>
                <div className="flex items-center gap-2">
                  <div className={`p-2 rounded-full ${getStatusColor(selectedRecord.status)}`}>
                    {getStatusIcon(selectedRecord.status)}
                  </div>
                  <span className="text-lg font-medium capitalize">{selectedRecord.status.replace('_', ' ')}</span>
                </div>
              </div>

              {/* Times */}
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4">
                <h3 className="text-sm font-semibold text-text-grey dark:text-text-grey-dark uppercase tracking-wide mb-3">Attendance Times</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Check In</p>
                    <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                      {selectedRecord.check_in_time ? formatTime(selectedRecord.check_in_time) : '—'}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Check Out</p>
                    <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                      {selectedRecord.check_out_time ? formatTime(selectedRecord.check_out_time) : '—'}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Total Hours</p>
                    <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                      {(selectedRecord.work_hours || 0).toFixed(2)}h
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">Date</p>
                    <p className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{selectedRecord.date}</p>
                  </div>
                </div>
              </div>

              {/* Late Reason */}
              {selectedRecord.late_reason && (
                <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-xl p-4">
                  <h3 className="text-sm font-semibold text-yellow-700 dark:text-yellow-400 uppercase tracking-wide mb-2 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4" />
                    Late Check-in Reason
                  </h3>
                  <p className="text-yellow-900 dark:text-yellow-200">{selectedRecord.late_reason}</p>
                </div>
              )}

              {/* Early Checkout Reason */}
              {selectedRecord.early_checkout_reason && (
                <div className="bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800 rounded-xl p-4">
                  <h3 className="text-sm font-semibold text-orange-700 dark:text-orange-400 uppercase tracking-wide mb-2 flex items-center gap-2">
                    <TrendingDown className="w-4 h-4" />
                    Early Check-out Reason
                  </h3>
                  <p className="text-orange-900 dark:text-orange-200">{selectedRecord.early_checkout_reason}</p>
                </div>
              )}

              {/* Locations */}
              {(selectedRecord.check_in_location || selectedRecord.check_out_location) && (
                <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4">
                  <h3 className="text-sm font-semibold text-text-grey dark:text-text-grey-dark uppercase tracking-wide mb-3 flex items-center gap-2">
                    <MapPin className="w-4 h-4" />
                    Locations
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-text-grey dark:text-text-grey-dark">Check-in Location</p>
                      <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.check_in_location || '—'}</p>
                    </div>
                    <div>
                      <p className="text-xs text-text-grey dark:text-text-grey-dark">Check-out Location</p>
                      <p className="font-medium text-text-dark dark:text-text-dark-light">{selectedRecord.check_out_location || '—'}</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Attendance;
