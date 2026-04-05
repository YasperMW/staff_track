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
  RefreshCw
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
  status: 'present' | 'absent' | 'late' | 'early_checkout';
  work_hours?: number;
  shift_type?: string;
  date: string;
}

const Attendance: React.FC = () => {
  const { success, error: showError } = useToast();
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [stats, setStats] = useState({
    total: 0,
    present: 0,
    absent: 0,
    late: 0,
    earlyCheckout: 0,
    averageHours: 0
  });

  useEffect(() => {
    loadAttendance();
  }, [selectedDate]);

  const loadAttendance = async () => {
    try {
      setLoading(true);
      
      // Get today's attendance summary
      const summaryResponse = await attendanceApi.getTodayAttendance();
      console.log('Attendance Summary:', summaryResponse);
      
      // Get team today list
      const teamListResponse = await attendanceApi.getTeamTodayList();
      console.log('Team List:', teamListResponse);
      
      // Process the data
      const attendanceData = [
        ...(teamListResponse?.staff?.map((staff: any) => ({
          id: staff.user_id,
          user_id: staff.user_id,
          user_name: `${staff.first_name} ${staff.surname || ''}`.trim(),
          employee_number: staff.employee_number,
          department: staff.department?.name || 'Unknown',
          check_in_time: staff.check_in_time,
          check_out_time: staff.check_out_time,
          status: staff.status || 'Unknown',
          work_hours: 8.0,
          date: new Date().toISOString().split('T')[0]
        })) || [])
      ];
      
      setAttendance(attendanceData);
      
      // Calculate stats from actual data
      const total = attendanceData.length;
      const present = attendanceData.filter(r => r.status === 'present').length;
      const absent = attendanceData.filter(r => r.status === 'absent').length;
      const late = attendanceData.filter(r => r.status === 'late').length;
      const earlyCheckout = attendanceData.filter(r => r.status === 'early_checkout').length;
      const avgHours = attendanceData.reduce((sum, r) => sum + (r.work_hours || 0), 0) / total;
      
      setStats({
        total,
        present,
        absent,
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
    // TODO: Implement export functionality
  };

  const handleRefresh = () => {
    loadAttendance();
    success('Attendance data refreshed');
  };

  const showInfo = (message: string) => {
    // TODO: Implement info toast when available
    console.log(message);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'present':
        return <CheckCircle className="w-5 h-5" />;
      case 'absent':
        return <XCircle className="w-5 h-5" />;
      case 'late':
        return <AlertTriangle className="w-5 h-5" />;
      case 'early_checkout':
        return <TrendingDown className="w-5 h-5" />;
      default:
        return <Clock className="w-5 h-5" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'present':
        return 'text-green-600 bg-green-100 dark:bg-green-900 dark:text-green-400';
      case 'absent':
        return 'text-red-600 bg-red-100 dark:bg-red-900 dark:text-red-400';
      case 'late':
        return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-400';
      case 'early_checkout':
        return 'text-orange-600 bg-orange-100 dark:bg-orange-900 dark:text-orange-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const formatTime = (timeString: string) => {
    return new Date(timeString).toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit'
    });
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
            {formatTime(value)}
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
        showInfo(`Viewing attendance details for ${record.user_name}`);
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
          <div className="flex items-center space-x-2">
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="input-field"
            />
            <button 
              onClick={handleRefresh}
              className="btn-outline flex items-center space-x-2"
            >
              <RefreshCw className="w-4 h-4" />
              <span>Refresh</span>
            </button>
          </div>
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Staff</p>
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Present</p>
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Absent</p>
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
    </div>
  );
};

export default Attendance;
