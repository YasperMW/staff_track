import React, { useState, useEffect } from 'react';
import { reportsApi, type DepartmentOption, type EmployeeOption, type StaffReportPreview, type DepartmentReportPreview, type StaffRecord } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { 
  FileText, 
  Download, 
  Calendar, 
  Building, 
  User,
  Loader2,
  ChevronDown,
  Clock
} from 'lucide-react';

type ReportType = 'department' | 'staff';

const Reports: React.FC = () => {
  const { success, error: showError } = useToast();
  const [downloading, setDownloading] = useState(false);
  const [loadingPreview, setLoadingPreview] = useState(false);
  
  const [reportType, setReportType] = useState<ReportType>('department');
  const [startDate, setStartDate] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return d.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => {
    const d = new Date();
    return d.toISOString().split('T')[0];
  });
  const [selectedDepartment, setSelectedDepartment] = useState<string>('');
  const [selectedEmployee, setSelectedEmployee] = useState<string>('');
  
  const [departments, setDepartments] = useState<DepartmentOption[]>([]);
  const [employees, setEmployees] = useState<EmployeeOption[]>([]);
  const [loadingDepartments, setLoadingDepartments] = useState(false);
  const [loadingEmployees, setLoadingEmployees] = useState(false);

  const [staffPreview, setStaffPreview] = useState<StaffReportPreview | null>(null);
  const [deptPreview, setDeptPreview] = useState<DepartmentReportPreview | null>(null);
  const [showPreview, setShowPreview] = useState(false);

  useEffect(() => {
    loadDepartments();
  }, []);

  useEffect(() => {
    if (selectedDepartment) {
      loadEmployees(selectedDepartment);
    } else {
      loadEmployees();
    }
    setSelectedEmployee('');
  }, [selectedDepartment]);

  useEffect(() => {
    setShowPreview(false);
    setStaffPreview(null);
    setDeptPreview(null);
  }, [reportType]);

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

  const handleGeneratePreview = async () => {
    if (!startDate || !endDate) {
      showError('Please select a date range');
      return;
    }
    if (startDate > endDate) {
      showError('Start date must be before end date');
      return;
    }
    if (reportType === 'staff' && !selectedEmployee) {
      showError('Please select an employee');
      return;
    }

    try {
      setLoadingPreview(true);
      setShowPreview(false);

      if (reportType === 'department') {
        const data = await reportsApi.getDepartmentPreview(startDate, endDate, selectedDepartment || undefined);
        setDeptPreview(data);
      } else {
        const data = await reportsApi.getStaffPreview(selectedEmployee, startDate, endDate);
        setStaffPreview(data);
      }
      setShowPreview(true);
    } catch (err: any) {
      console.error('Error loading preview:', err);
      showError(err.response?.data?.detail || 'Failed to load report data');
    } finally {
      setLoadingPreview(false);
    }
  };

  const handleDownloadPdf = async () => {
    if (!startDate || !endDate) {
      showError('Please select a date range');
      return;
    }
    if (startDate > endDate) {
      showError('Start date must be before end date');
      return;
    }
    if (reportType === 'staff' && !selectedEmployee) {
      showError('Please select an employee');
      return;
    }

    try {
      setDownloading(true);

      if (reportType === 'department') {
        await reportsApi.downloadDepartmentPdf(startDate, endDate, selectedDepartment || undefined);
        const deptName = departments.find(d => d.department_id === selectedDepartment)?.name || 'All Departments';
        success(`Downloading ${deptName} attendance report`);
      } else {
        const empName = employees.find(e => e.user_id === selectedEmployee)?.name || 'Staff';
        await reportsApi.downloadStaffPdf(selectedEmployee, empName, startDate, endDate);
        success(`Downloading attendance report for ${empName}`);
      }
    } catch (err: any) {
      console.error('Error downloading report:', err);
      showError(err.response?.data?.detail || 'Failed to download report');
    } finally {
      setDownloading(false);
    }
  };

  const renderDepartmentPreview = () => {
    if (!deptPreview) return null;

    return (
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
              {deptPreview.department_name} — Staff Attendance Summary
            </h2>
            <p className="text-sm text-text-grey dark:text-text-grey-dark">
              {deptPreview.start_date} to {deptPreview.end_date} · {deptPreview.total_staff} total staff · {deptPreview.staff_records.length} with records
            </p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">#</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Employee Name</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Days Present</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Days Absent</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">On Time</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Late</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Early Out</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Total Hours</th>
                <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Avg Hours</th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
              {deptPreview.staff_records.length === 0 ? (
                <tr><td colSpan={9} className="px-4 py-8 text-center text-text-grey">No attendance records found for this period</td></tr>
              ) : (
                deptPreview.staff_records.map((record: StaffRecord, i: number) => (
                  <tr key={i} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                    <td className="px-4 py-3 text-sm text-gray-500">{i + 1}</td>
                    <td className="px-4 py-3 text-sm font-medium text-gray-900 dark:text-gray-100">{record.staff_name}</td>
                    <td className="px-4 py-3 text-center text-sm text-green-600 font-medium">{record.days_present}</td>
                    <td className="px-4 py-3 text-center text-sm text-red-600 font-medium">{record.days_absent}</td>
                    <td className="px-4 py-3 text-center text-sm text-gray-900 dark:text-gray-100">{record.on_time}</td>
                    <td className="px-4 py-3 text-center text-sm text-yellow-600 font-medium">{record.late}</td>
                    <td className="px-4 py-3 text-center text-sm text-orange-600 font-medium">{record.early_out}</td>
                    <td className="px-4 py-3 text-center text-sm text-gray-900 dark:text-gray-100">{record.total_hours.toFixed(1)}h</td>
                    <td className="px-4 py-3 text-center text-sm text-gray-900 dark:text-gray-100">{record.avg_hours.toFixed(1)}h</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  };

  const renderStaffPreview = () => {
    if (!staffPreview) return null;
    const { summary, records } = staffPreview;

    return (
      <>
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
                {staffPreview.user_name} — Attendance Summary
              </h2>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">
                {staffPreview.department || 'No department'} · {staffPreview.start_date} to {staffPreview.end_date}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-4 mb-6">
            {[
              { label: 'Days Present', value: summary.present_days, color: 'text-green-600' },
              { label: 'Days Absent', value: summary.absent_days, color: 'text-red-600' },
              { label: 'On Time', value: summary.on_time, color: 'text-sky-blue' },
              { label: 'Late', value: summary.late, color: 'text-yellow-600' },
              { label: 'Early Out', value: summary.early_out, color: 'text-orange-600' },
              { label: 'Total Hours', value: `${summary.total_work_hours.toFixed(1)}h`, color: 'text-text-dark dark:text-text-dark-light' },
              { label: 'Avg Hours', value: `${summary.avg_hours.toFixed(1)}h`, color: 'text-text-dark dark:text-text-dark-light' },
            ].map((stat, i) => (
              <div key={i} className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 text-center">
                <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
                <p className="text-xs text-text-grey dark:text-text-grey-dark mt-1">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <div className="flex items-center space-x-2 mb-4">
            <Clock className="w-4 h-4 text-sky-blue" />
            <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
              Detailed Attendance Records
            </h2>
            <span className="text-sm text-text-grey dark:text-text-grey-dark">({records.length} records)</span>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">#</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Date</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Check In</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Check Out</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Shift</th>
                  <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Hours</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Late Reason</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Early Out Reason</th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                {records.length === 0 ? (
                  <tr><td colSpan={8} className="px-4 py-8 text-center text-text-grey">No attendance records found for this period</td></tr>
                ) : (
                  records.map((record, i: number) => (
                    <tr key={i} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                      <td className="px-4 py-3 text-sm text-gray-500">{i + 1}</td>
                      <td className="px-4 py-3 text-sm text-gray-900 dark:text-gray-100">{record.date}</td>
                      <td className="px-4 py-3 text-sm text-gray-900 dark:text-gray-100">{record.check_in_time}</td>
                      <td className="px-4 py-3 text-sm text-gray-900 dark:text-gray-100">{record.check_out_time || '—'}</td>
                      <td className="px-4 py-3 text-sm text-gray-900 dark:text-gray-100">{record.shift_type || 'Day Shift'}</td>
                      <td className="px-4 py-3 text-center text-sm font-medium text-gray-900 dark:text-gray-100">
                        {record.work_hours ? `${record.work_hours.toFixed(1)}h` : '—'}
                      </td>
                      <td className="px-4 py-3 text-sm text-yellow-600 max-w-[200px] truncate" title={record.late_reason || ''}>
                        {record.late_reason || '—'}
                      </td>
                      <td className="px-4 py-3 text-sm text-orange-600 max-w-[200px] truncate" title={record.early_checkout_reason || ''}>
                        {record.early_checkout_reason || '—'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">Attendance Reports</h1>
        <p className="text-text-grey dark:text-text-grey-dark">Generate PDF reports for departments or individual staff</p>
      </div>

      {/* Report Configuration */}
      <div className="card">
        <div className="flex items-center space-x-2 mb-6">
          <FileText className="w-5 h-5 text-sky-blue" />
          <h2 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">Report Configuration</h2>
        </div>

        {/* Report Type Selector */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">Report Type</label>
          <div className="flex gap-3">
            <button
              onClick={() => setReportType('department')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-all ${
                reportType === 'department'
                  ? 'border-sky-blue bg-sky-blue/10 text-sky-blue'
                  : 'border-gray-200 dark:border-gray-700 text-text-grey hover:border-gray-300 dark:hover:border-gray-600'
              }`}
            >
              <Building className="w-5 h-5" />
              <span className="font-medium">Department Report</span>
            </button>
            <button
              onClick={() => setReportType('staff')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-all ${
                reportType === 'staff'
                  ? 'border-sky-blue bg-sky-blue/10 text-sky-blue'
                  : 'border-gray-200 dark:border-gray-700 text-text-grey hover:border-gray-300 dark:hover:border-gray-600'
              }`}
            >
              <User className="w-5 h-5" />
              <span className="font-medium">Staff Report</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Start Date */}
          <div>
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Calendar className="w-4 h-4 inline mr-1" />Start Date
            </label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="input-field w-full"
            />
          </div>

          {/* End Date */}
          <div>
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Calendar className="w-4 h-4 inline mr-1" />End Date
            </label>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="input-field w-full"
            />
          </div>

          {/* Department */}
          <div>
            <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
              <Building className="w-4 h-4 inline mr-1" />Department
            </label>
            <div className="relative">
              <select
                value={selectedDepartment}
                onChange={(e) => setSelectedDepartment(e.target.value)}
                className="input-field w-full appearance-none pr-10"
                disabled={loadingDepartments}
              >
                <option value="">All Departments</option>
                {departments.map((dept) => (
                  <option key={dept.department_id} value={dept.department_id}>{dept.name}</option>
                ))}
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
            </div>
          </div>

          {/* Employee */}
          {reportType === 'staff' && (
            <div>
              <label className="block text-sm font-medium text-text-dark dark:text-text-dark-light mb-2">
                <User className="w-4 h-4 inline mr-1" />Employee
              </label>
              <div className="relative">
                <select
                  value={selectedEmployee}
                  onChange={(e) => setSelectedEmployee(e.target.value)}
                  className="input-field w-full appearance-none pr-10"
                  disabled={loadingEmployees}
                >
                  <option value="">Select Employee</option>
                  {employees.map((emp) => (
                    <option key={emp.user_id} value={emp.user_id}>{emp.name}</option>
                  ))}
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 mt-6">
          <button
            onClick={handleGeneratePreview}
            disabled={loadingPreview}
            className="btn-primary flex items-center justify-center space-x-2 w-full sm:w-auto"
          >
            {loadingPreview ? <Loader2 className="w-4 h-4 animate-spin" /> : <FileText className="w-4 h-4" />}
            <span>Generate Preview</span>
          </button>
          <button
            onClick={handleDownloadPdf}
            disabled={downloading}
            className="btn-outline flex items-center justify-center space-x-2 w-full sm:w-auto"
          >
            {downloading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
            <span>Download PDF</span>
          </button>
        </div>
      </div>

      {/* Preview Tables */}
      {loadingPreview && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-sky-blue" />
          <span className="ml-3 text-text-grey">Loading report data...</span>
        </div>
      )}
      {showPreview && reportType === 'department' && renderDepartmentPreview()}
      {showPreview && reportType === 'staff' && renderStaffPreview()}
    </div>
  );
};

export default Reports;
