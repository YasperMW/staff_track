import React, { useState, useEffect } from 'react';
import { reportsApi, type MonthlyReportRequest, type MonthlyReportResponse, type DepartmentOption, type EmployeeOption } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { 
  FileText, 
  Download, 
  Calendar, 
  Users, 
  Building, 
  User,
  Filter,
  Loader2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  TrendingDown,
  Clock
} from 'lucide-react';

const Reports: React.FC = () => {
  const { success, error: showError } = useToast();
  const [loading, setLoading] = useState(false);
  const [generatingReport, setGeneratingReport] = useState(false);
  
  // Form state
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [selectedDepartment, setSelectedDepartment] = useState<string>('');
  const [selectedEmployee, setSelectedEmployee] = useState<string>('');
  
  // Options
  const [departments, setDepartments] = useState<DepartmentOption[]>([]);
  const [employees, setEmployees] = useState<EmployeeOption[]>([]);
  const [loadingDepartments, setLoadingDepartments] = useState(false);
  const [loadingEmployees, setLoadingEmployees] = useState(false);
  
  // Report data
  const [reportData, setReportData] = useState<MonthlyReportResponse | null>(null);
  const [showReport, setShowReport] = useState(false);

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  useEffect(() => {
    loadDepartments();
  }, []);

  useEffect(() => {
    if (selectedDepartment) {
      loadEmployees(selectedDepartment);
    } else {
      loadEmployees();
    }
  }, [selectedDepartment]);

  const loadDepartments = async () => {
    try {
      setLoadingDepartments(true);
      const data = await reportsApi.getDepartments();
      setDepartments(data);
    } catch (err: any) {
      console.error('Error loading departments:', err);
      showError('Failed to load departments');
    } finally {
      setLoadingDepartments(false);
    }
  };

  const loadEmployees = async (departmentId?: string) => {
    try {
      setLoadingEmployees(true);
      const data = await reportsApi.getEmployees(departmentId);
      setEmployees(data);
    } catch (err: any) {
      console.error('Error loading employees:', err);
      showError('Failed to load employees');
    } finally {
      setLoadingEmployees(false);
    }
  };

  const handleGenerateReport = async (format: 'json' | 'pdf') => {
    if (!year || !month) {
      showError('Please select year and month');
      return;
    }

    try {
      setGeneratingReport(true);
      
      const request: MonthlyReportRequest = {
        year,
        month,
        department_id: selectedDepartment || undefined,
        user_id: selectedEmployee || undefined
      };

      if (format === 'pdf') {
        // For PDF, handle as blob download
        const response = await reportsApi.getMonthlyReport(request, 'pdf');
        const blob = new Blob([response as Blob], { type: 'application/pdf' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `attendance_report_${year}_${month.toString().padStart(2, '0')}.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        success('PDF report downloaded successfully');
      } else {
        // For JSON, display in UI
        const data = await reportsApi.getMonthlyReport(request, 'json') as MonthlyReportResponse;
        setReportData(data);
        setShowReport(true);
        success('Report generated successfully');
      }
    } catch (err: any) {
      console.error('Error generating report:', err);
      showError(err.response?.data?.detail || 'Failed to generate report');
    } finally {
      setGeneratingReport(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'present':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'absent':
        return <XCircle className="w-4 h-4 text-red-600" />;
      case 'late':
        return <AlertTriangle className="w-4 h-4 text-yellow-600" />;
      case 'early_checkout':
      case 'late_early_checkout':
        return <TrendingDown className="w-4 h-4 text-orange-600" />;
      default:
        return <Clock className="w-4 h-4 text-gray-600" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'present':
        return 'text-green-600 bg-green-100';
      case 'absent':
        return 'text-red-600 bg-red-100';
      case 'late':
        return 'text-yellow-600 bg-yellow-100';
      case 'early_checkout':
      case 'late_early_checkout':
        return 'text-orange-600 bg-orange-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const formatTime = (timeString: string) => {
    return new Date(timeString).toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            Monthly Reports
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Generate and download monthly attendance reports
          </p>
        </div>
      </div>

      {/* Report Configuration */}
      <div className="card">
        <div className="flex items-center space-x-2 mb-6">
          <FileText className="w-5 h-5 text-sky-blue" />
          <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
            Report Configuration
          </h2>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Year */}
          <div>
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Calendar className="w-4 h-4 inline mr-1" />
              Year
            </label>
            <select
              value={year}
              onChange={(e) => setYear(parseInt(e.target.value))}
              className="input-field w-full"
            >
              {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - i).map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </div>

          {/* Month */}
          <div>
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Calendar className="w-4 h-4 inline mr-1" />
              Month
            </label>
            <select
              value={month}
              onChange={(e) => setMonth(parseInt(e.target.value))}
              className="input-field w-full"
            >
              {monthNames.map((name, index) => (
                <option key={index + 1} value={index + 1}>
                  {name}
                </option>
              ))}
            </select>
          </div>

          {/* Department */}
          <div className="lg:col-span-1">
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Building className="w-4 h-4 inline mr-1" />
              Department
            </label>
            <select
              value={selectedDepartment}
              onChange={(e) => {
                setSelectedDepartment(e.target.value);
                setSelectedEmployee(''); // Reset employee when department changes
              }}
              className="input-field w-full"
              disabled={loadingDepartments}
            >
              <option value="">All Departments</option>
              {departments.map((dept) => (
                <option key={dept.department_id} value={dept.department_id}>
                  {dept.name}
                </option>
              ))}
            </select>
          </div>

          {/* Employee */}
          <div className="lg:col-span-1">
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <User className="w-4 h-4 inline mr-1" />
              Employee
            </label>
            <select
              value={selectedEmployee}
              onChange={(e) => setSelectedEmployee(e.target.value)}
              className="input-field w-full"
              disabled={loadingEmployees}
            >
              <option value="">All Employees</option>
              {employees.map((emp) => (
                <option key={emp.user_id} value={emp.user_id}>
                  {emp.name} ({emp.employee_number})
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 mt-6">
          <button
            onClick={() => handleGenerateReport('json')}
            disabled={generatingReport}
            className="btn-primary flex items-center justify-center space-x-2 w-full sm:w-auto"
          >
            {generatingReport ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Filter className="w-4 h-4" />
            )}
            <span>Generate Report</span>
          </button>
          
          <button
            onClick={() => handleGenerateReport('pdf')}
            disabled={generatingReport}
            className="btn-outline flex items-center justify-center space-x-2 w-full sm:w-auto"
          >
            {generatingReport ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Download className="w-4 h-4" />
            )}
            <span>Download PDF</span>
          </button>
        </div>
      </div>

      {/* Report Results */}
      {showReport && reportData && (
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center space-x-2">
              <FileText className="w-5 h-5 text-sky-blue" />
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                Monthly Attendance Report - {monthNames[reportData.month - 1]} {reportData.year}
              </h2>
            </div>
            <div className="text-sm text-text-grey dark:text-text-grey-dark">
              Total Employees: {reportData.total_employees}
            </div>
          </div>

          {/* Summary Table */}
          <div className="overflow-x-auto bg-white dark:bg-gray-900 rounded-lg shadow">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Employee
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider hidden sm:table-cell">
                    Department
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Present
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Absent
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Late
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Early Out
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Total Hours
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Avg Hours
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                {reportData.data.map((employee) => (
                  <React.Fragment key={employee.employee_name}>
                    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="px-4 py-3 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate max-w-[150px]">
                            {employee.employee_name}
                          </div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">
                            {employee.employee_number}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100 hidden sm:table-cell">
                        <span className="truncate max-w-[120px] block">
                          {employee.department}
                        </span>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.present_days}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.absent_days}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.late_days}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.early_checkout_days}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.total_hours.toFixed(1)}h
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-center text-sm text-gray-900 dark:text-gray-100">
                        {employee.average_hours.toFixed(1)}h
                      </td>
                    </tr>
                    
                    {/* Detailed Records */}
                    <tr>
                      <td colSpan={8} className="px-4 py-0">
                        <div className="bg-gray-50 dark:bg-gray-800 rounded-lg m-1">
                          <div className="px-3 py-2">
                            <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-2">
                              Detailed Attendance Records
                            </h4>
                            <div className="overflow-x-auto">
                              <table className="min-w-full text-sm">
                                <thead>
                                  <tr className="border-b border-gray-200 dark:border-gray-700">
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Date</th>
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Check In</th>
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Check Out</th>
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Status</th>
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Hours</th>
                                    <th className="text-left py-2 px-2 text-gray-600 dark:text-gray-400">Shift</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {employee.attendance_records.map((record, index) => (
                                    <tr key={index} className="border-b border-gray-100 dark:border-gray-700">
                                      <td className="py-2 px-2 text-gray-900 dark:text-gray-100">
                                        {new Date(record.date).toLocaleDateString()}
                                      </td>
                                      <td className="py-2 px-2 text-gray-900 dark:text-gray-100">
                                        {formatTime(record.check_in_time)}
                                      </td>
                                      <td className="py-2 px-2 text-gray-900 dark:text-gray-100">
                                        {record.check_out_time ? formatTime(record.check_out_time) : 'N/A'}
                                      </td>
                                      <td className="py-2 px-2">
                                        <div className={`inline-flex items-center space-x-1 px-2 py-1 rounded-full text-xs ${getStatusColor(record.status)}`}>
                                          {getStatusIcon(record.status)}
                                          <span className="capitalize">
                                            {record.status.replace('_', ' ')}
                                          </span>
                                        </div>
                                      </td>
                                      <td className="py-2 px-2 text-gray-900 dark:text-gray-100">
                                        {record.work_hours.toFixed(1)}h
                                      </td>
                                      <td className="py-2 px-2 text-gray-900 dark:text-gray-100">
                                        {record.shift_type || 'N/A'}
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        </div>
                      </td>
                    </tr>
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default Reports;
