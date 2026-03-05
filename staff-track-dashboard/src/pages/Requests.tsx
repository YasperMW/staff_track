import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import DataTable from '../components/DataTable';
import type { Column, Action } from '../components/DataTable';
import { 
  Calendar, 
  Clock, 
  FileText, 
  CheckCircle, 
  XCircle, 
  AlertCircle, 
  Eye,
  Home,
  RefreshCw,
  Filter
} from 'lucide-react';

interface Request {
  id: string;
  user_id: string;
  user_name: string;
  employee_number: string;
  department: string;
  type: 'leave' | 'wfh' | 'shift_change' | 'overtime' | 'other';
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  title: string;
  description: string;
  start_date: string;
  end_date?: string;
  duration?: number;
  reason?: string;
  approver_name?: string;
  approver_comment?: string;
  created_at: string;
  updated_at: string;
}

const Requests: React.FC = () => {
  const { success, error, warning, info } = useToast();
  const [requests, setRequests] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    leaveRequests: 0,
    wfhRequests: 0
  });

  useEffect(() => {
    loadRequests();
  }, [selectedFilter]);

  const loadRequests = async () => {
    try {
      setLoading(true);
      
      // Mock data for now - replace with actual API call
      const mockData: Request[] = [
        {
          id: '1',
          user_id: '1',
          user_name: 'John Doe',
          employee_number: 'EMP001',
          department: 'Emergency Department',
          type: 'leave',
          status: 'pending',
          title: 'Annual Leave Request',
          description: 'Requesting annual leave for family vacation',
          start_date: '2024-03-10',
          end_date: '2024-03-15',
          duration: 5,
          reason: 'Family vacation planned months ago',
          created_at: '2024-03-01T09:00:00',
          updated_at: '2024-03-01T09:00:00'
        },
        {
          id: '2',
          user_id: '2',
          user_name: 'Jane Smith',
          employee_number: 'EMP002',
          department: 'ICU',
          type: 'wfh',
          status: 'approved',
          title: 'Work From Home',
          description: 'Requesting to work from home due to health reasons',
          start_date: '2024-03-06',
          end_date: '2024-03-08',
          duration: 3,
          reason: 'Recovering from minor illness',
          approver_name: 'Dr. Wilson',
          approver_comment: 'Approved. Please maintain availability.',
          created_at: '2024-03-04T14:30:00',
          updated_at: '2024-03-05T10:15:00'
        },
        {
          id: '3',
          user_id: '3',
          user_name: 'Bob Johnson',
          employee_number: 'EMP003',
          department: 'Surgery',
          type: 'shift_change',
          status: 'rejected',
          title: 'Shift Change Request',
          description: 'Request to change from night shift to day shift',
          start_date: '2024-03-07',
          reason: 'Family responsibilities',
          approver_name: 'Dr. Wilson',
          approver_comment: 'Cannot approve at this time due to staffing constraints.',
          created_at: '2024-03-02T11:20:00',
          updated_at: '2024-03-03T16:45:00'
        },
        {
          id: '4',
          user_id: '4',
          user_name: 'Alice Brown',
          employee_number: 'EMP004',
          department: 'Pediatrics',
          type: 'overtime',
          status: 'pending',
          title: 'Overtime Request',
          description: 'Request overtime hours for weekend coverage',
          start_date: '2024-03-09',
          duration: 8,
          reason: 'Weekend staff shortage',
          created_at: '2024-03-05T08:45:00',
          updated_at: '2024-03-05T08:45:00'
        }
      ];
      
      // Filter requests based on selected filter
      const filteredRequests = selectedFilter === 'all' 
        ? mockData 
        : mockData.filter(req => req.status === selectedFilter);
      
      setRequests(filteredRequests);
      
      // Calculate stats
      const total = mockData.length;
      const pending = mockData.filter(r => r.status === 'pending').length;
      const approved = mockData.filter(r => r.status === 'approved').length;
      const rejected = mockData.filter(r => r.status === 'rejected').length;
      const leaveRequests = mockData.filter(r => r.type === 'leave').length;
      const wfhRequests = mockData.filter(r => r.type === 'wfh').length;
      
      setStats({
        total,
        pending,
        approved,
        rejected,
        leaveRequests,
        wfhRequests
      });
      
    } catch (error) {
      console.error('Error loading requests:', error);
      error('Failed to load requests data');
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = (request: Request) => {
    success(`Request from ${request.user_name} approved`);
    loadRequests();
  };

  const handleReject = (request: Request) => {
    warning(`Request from ${request.user_name} rejected`);
    loadRequests();
  };

  const handleViewDetails = (request: Request) => {
    info(`Viewing details for ${request.title}`);
  };

  const getRequestIcon = (type: string) => {
    switch (type) {
      case 'leave':
        return <Calendar className="w-5 h-5" />;
      case 'wfh':
        return <Home className="w-5 h-5" />;
      case 'shift_change':
        return <RefreshCw className="w-5 h-5" />;
      case 'overtime':
        return <Clock className="w-5 h-5" />;
      default:
        return <FileText className="w-5 h-5" />;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved':
        return <CheckCircle className="w-5 h-5" />;
      case 'rejected':
        return <XCircle className="w-5 h-5" />;
      case 'pending':
        return <AlertCircle className="w-5 h-5" />;
      default:
        return <FileText className="w-5 h-5" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved':
        return 'text-green-600 bg-green-100 dark:bg-green-900 dark:text-green-400';
      case 'rejected':
        return 'text-red-600 bg-red-100 dark:bg-red-900 dark:text-red-400';
      case 'pending':
        return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'leave':
        return 'text-blue-600 bg-blue-100 dark:bg-blue-900 dark:text-blue-400';
      case 'wfh':
        return 'text-purple-600 bg-purple-100 dark:bg-purple-900 dark:text-purple-400';
      case 'shift_change':
        return 'text-orange-600 bg-orange-100 dark:bg-orange-900 dark:text-orange-400';
      case 'overtime':
        return 'text-indigo-600 bg-indigo-100 dark:bg-indigo-900 dark:text-indigo-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const columns: Column<Request>[] = [
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
      key: 'type',
      label: 'Type',
      sortable: true,
      filterable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <div className={`p-1 rounded-full ${getTypeColor(value)}`}>
            {getRequestIcon(value)}
          </div>
          <span className="text-sm font-medium capitalize">
            {value.replace('_', ' ')}
          </span>
        </div>
      )
    },
    {
      key: 'title',
      label: 'Request',
      sortable: true,
      filterable: true,
      render: (value) => (
        <div>
          <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">
            {value}
          </p>
        </div>
      )
    },
    {
      key: 'start_date',
      label: 'Date Range',
      sortable: true,
      render: (_, row) => (
        <div className="text-sm">
          <p className="text-text-dark dark:text-text-dark-light">
            {formatDate(row.start_date)}
          </p>
          {row.end_date && row.end_date !== row.start_date && (
            <p className="text-text-grey dark:text-text-grey-dark">
              to {formatDate(row.end_date)}
            </p>
          )}
          {row.duration && (
            <p className="text-text-grey dark:text-text-grey-dark">
              {row.duration} days
            </p>
          )}
        </div>
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
            {value}
          </span>
        </div>
      )
    },
    {
      key: 'created_at',
      label: 'Submitted',
      sortable: true,
      render: (value) => (
        <span className="text-sm text-text-grey dark:text-text-grey-dark">
          {formatDate(value)}
        </span>
      )
    }
  ];

  const getActions = (request: Request): Action<Request>[] => {
    const baseActions: Action<Request>[] = [
      {
        label: 'View Details',
        icon: <Eye className="w-4 h-4" />,
        onClick: handleViewDetails,
        variant: 'primary'
      }
    ];

    if (request.status === 'pending') {
      baseActions.push(
        {
          label: 'Approve',
          icon: <CheckCircle className="w-4 h-4" />,
          onClick: handleApprove,
          variant: 'secondary'
        },
        {
          label: 'Reject',
          icon: <XCircle className="w-4 h-4" />,
          onClick: handleReject,
          variant: 'danger'
        }
      );
    }

    return baseActions;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Requests Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage employee requests for leave, work from home, and shift changes
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-2">
            <Filter className="w-4 h-4 text-text-grey" />
            <select
              value={selectedFilter}
              onChange={(e) => setSelectedFilter(e.target.value as any)}
              className="input-field"
            >
              <option value="all">All Requests</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total</p>
              <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
                {stats.total}
              </p>
            </div>
            <div className="w-12 h-12 bg-sky-blue bg-opacity-10 rounded-xl flex items-center justify-center">
              <FileText className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Pending</p>
              <p className="text-2xl font-bold text-yellow-600">
                {stats.pending}
              </p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-xl flex items-center justify-center">
              <AlertCircle className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Approved</p>
              <p className="text-2xl font-bold text-green-600">
                {stats.approved}
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Rejected</p>
              <p className="text-2xl font-bold text-red-600">
                {stats.rejected}
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Leave</p>
              <p className="text-2xl font-bold text-blue-600">
                {stats.leaveRequests}
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center">
              <Calendar className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">WFH</p>
              <p className="text-2xl font-bold text-purple-600">
                {stats.wfhRequests}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <Home className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Requests Table */}
      <DataTable
        data={requests}
        columns={columns}
        actions={getActions}
        loading={loading}
        emptyMessage="No requests found matching the selected filter."
      />
    </div>
  );
};

export default Requests;
