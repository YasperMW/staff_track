import axios from 'axios';
import type { AxiosInstance, AxiosResponse } from 'axios';

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8888';

// Types based on FastAPI models
export interface User {
  user_id: string;
  employee_number: string;
  national_id?: string;
  first_name: string;
  surname: string;
  other_names?: string;
  suffix?: string;
  date_of_birth?: string;
  gender?: string;
  home_of_origin?: string;
  traditional_authority?: string;
  district?: string;
  current_address?: string;
  contact_number?: string;
  email: string;
  marital_status?: string;
  spouse_name?: string;
  spouse_contact?: string;
  date_of_employment?: string;
  designation_id?: string;
  designation?: string;
  department_id?: string;
  is_head_of_department: boolean;
  phone?: string;
  role_id: string;
  status: string;
  profile_photo_url?: string;
  blacklisted_at?: string;
  blacklisted_reason?: string;
  registration_timestamp?: string;
  selfie_verified: boolean;
  last_login_at?: string;
  failed_login_attempts?: number;
  locked_until?: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
  deleted_by?: string;
  role_name: string;
  role?: string;
  department_name?: string;
  grade_id?: string;
  grade_name?: string;
}

export interface UserDocument {
  document_id: string;
  user_id: string;
  document_type: string;
  file_path: string;
  file_name: string;
  upload_date: string;
}

export interface UserDetailsResponse {
  user: User;
  documents: UserDocument[];
}

export interface Role {
  role_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at?: string;
  user_count?: number;
}

export interface Department {
  department_id: string;
  name: string;
  description?: string;
  created_at: string;
  designations: string[];
}

export interface Designation {
  designation_id: string;
  name: string;
  description?: string;
  department_id: string;
  department_name?: string;
  created_at: string;
}

export interface Grade {
  id: string;
  name: string;
  annual_leave_days: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  token?: string;
  user?: User;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
}

export interface PaginatedResponse<T> {
  success: boolean;
  message: string;
  items: T[];  // For general endpoints
  users: T[];  // For users endpoints  
  departments: T[];  // For departments endpoints
  roles: T[];  // For roles endpoints
  designations: T[];  // For designations endpoints
  total_count: number;
  page?: number;
  per_page?: number;
  total_pages?: number;
}

// Create axios instance
const createApiInstance = (): AxiosInstance => {
  const instance = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  // Request interceptor to add auth token
  instance.interceptors.request.use(
    (config) => {
      const token = localStorage.getItem('auth_token');
      console.log('Token being sent:', token ? 'Bearer ' + token.substring(0, 20) + '...' : 'No token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  // Response interceptor for error handling
  instance.interceptors.response.use(
    (response: AxiosResponse) => {
      return response;
    },
    (error) => {
      console.error('API Error:', error.response?.status, error.response?.data);
      
      // Only redirect to login on 401 errors for protected endpoints
      // Don't redirect for token verification endpoint itself or login endpoint
      if (error.response?.status === 401 && 
          !error.config?.url?.includes('/verify-token') && 
          !error.config?.url?.includes('/auth/login')) {
        // Token expired or invalid
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user_data');
        window.location.href = '/login';
      }
      return Promise.reject(error);
    }
  );

  return instance;
};

export const api = createApiInstance();

// Authentication API
export const authApi = {
  login: async (credentials: LoginRequest): Promise<LoginResponse> => {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  },

  logout: async (): Promise<ApiResponse<null>> => {
    const response = await api.post('/auth/logout');
    return response.data;
  },

  getCurrentUser: async (): Promise<User> => {
    const response = await api.get('/users/profile');
    return response.data;
  },

  verifyToken: async (): Promise<ApiResponse<null>> => {
    try {
      const response = await api.get('/auth/verify-token');
      return response.data;
    } catch (error: any) {
      // If verify token endpoint fails with network error or server error
      // don't treat it as authentication failure
      if (error.code === 'NETWORK_ERROR' || error.response?.status >= 500) {
        console.warn('Token verification endpoint unavailable, assuming token is valid');
        return { success: true, message: 'Token verification skipped due to server unavailability' };
      }
      throw error;
    }
  },
};

// Users API
export const usersApi = {
  debugToken: async (): Promise<any> => {
    const response = await api.get('/users/debug-token');
    return response.data;
  },

  getCurrentUserProfile: async (): Promise<any> => {
    const response = await api.get('/users/profile');
    return response.data;
  },

  getCompleteUserProfile: async (): Promise<any> => {
    const response = await api.get('/users/profile/complete');
    return response.data;
  },

  getAllUsers: async (): Promise<PaginatedResponse<User>> => {
    const response = await api.get('/users/users');
    return response.data;
  },

  getActiveUsers: async (): Promise<PaginatedResponse<User>> => {
    const response = await api.get('/users/users/active');
    return response.data;
  },

  getUsersByDepartment: async (departmentName: string): Promise<PaginatedResponse<User>> => {
    const response = await api.get(`/users/users/by-department/${departmentName}`);
    return response.data;
  },

  getUserDetails: async (userId: string): Promise<UserDetailsResponse> => {
    const response = await api.get(`/users/users/${userId}`);
    return response.data;
  },

  createUser: async (userData: Partial<User>): Promise<ApiResponse<User>> => {
    const response = await api.post('/users/register', userData);
    return response.data;
  },

  updateUser: async (userId: string, userData: Partial<User>): Promise<ApiResponse<User>> => {
    const response = await api.put(`/users/users/${userId}`, userData);
    return response.data;
  },

  updateUserRole: async (userId: string, roleId: string): Promise<ApiResponse<User>> => {
    const response = await api.put(`/users/users/${userId}/role`, { role_id: roleId });
    return response.data;
  },

  deleteUser: async (userId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/users/users/${userId}`);
    return response.data;
  },

  lockUserAccount: async (userId: string, lockDurationMinutes: number | null, passwordConfirmation: string): Promise<ApiResponse<null>> => {
    const response = await api.put(`/users/users/${userId}/lock`, {
      lock_duration_minutes: lockDurationMinutes,
      password_confirmation: passwordConfirmation,
    });
    return response.data;
  },

  hardDeleteUserAccount: async (userId: string, passwordConfirmation: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/users/users/${userId}/hard-delete`, {
      data: { password_confirmation: passwordConfirmation },
    });
    return response.data;
  },
};

// Departments API
export const departmentsApi = {
  getAllDepartments: async (): Promise<PaginatedResponse<Department>> => {
    const response = await api.get('/lookup/departments');
    return response.data;
  },

  createDepartment: async (departmentData: Partial<Department>): Promise<ApiResponse<Department>> => {
    const response = await api.post('/lookup/departments', departmentData);
    return response.data;
  },

  updateDepartment: async (departmentId: string, departmentData: Partial<Department>): Promise<ApiResponse<Department>> => {
    const response = await api.put(`/lookup/departments/${departmentId}`, departmentData);
    return response.data;
  },

  deleteDepartment: async (departmentId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/lookup/departments/${departmentId}`);
    return response.data;
  },
};

// Roles API
export const rolesApi = {
  getAllRoles: async (): Promise<PaginatedResponse<Role>> => {
    const response = await api.get('/roles/');
    return response.data;
  },

  getRole: async (roleId: string): Promise<Role> => {
    const response = await api.get(`/roles/${roleId}`);
    return response.data;
  },

  createRole: async (roleData: { name: string; description?: string }): Promise<Role> => {
    const response = await api.post('/roles/', roleData);
    return response.data;
  },

  updateRole: async (roleId: string, roleData: { name?: string; description?: string }): Promise<Role> => {
    const response = await api.put(`/roles/${roleId}`, roleData);
    return response.data;
  },

  deleteRole: async (roleId: string): Promise<void> => {
    await api.delete(`/roles/${roleId}`);
  },
};

// Grades API
export const gradesApi = {
  getAllGrades: async (): Promise<Grade[]> => {
    const response = await api.get('/auth/grades');
    return response.data;
  },

  createGrade: async (gradeData: { name: string; annual_leave_days: number }): Promise<Grade> => {
    const response = await api.post('/api/grades', gradeData);
    return response.data;
  },

  updateGrade: async (gradeId: string, gradeData: { name?: string; annual_leave_days?: number }): Promise<Grade> => {
    const response = await api.put(`/api/grades/${gradeId}`, gradeData);
    return response.data;
  },

  deleteGrade: async (gradeId: string): Promise<void> => {
    await api.delete(`/api/grades/${gradeId}`);
  },

  updateUserGrade: async (userId: string, gradeId: string): Promise<any> => {
    const response = await api.put(`/users/${userId}/grade`, { grade_id: gradeId });
    return response.data;
  },
};

// Attendance API
export const attendanceApi = {
  getTodayAttendance: async (): Promise<any> => {
    const response = await api.get('/attendance/today');
    return response.data;
  },

  getTeamTodaySummary: async (date?: string): Promise<any> => {
    const url = date ? `/attendance/team/today/summary?date=${date}` : '/attendance/team/today/summary';
    const response = await api.get(url);
    return response.data;
  },

  getTeamTodayList: async (): Promise<any> => {
    const response = await api.get('/attendance/team/today/list');
    return response.data;
  },

  getRecentCheckIns: async (limit?: number): Promise<any> => {
    const url = limit ? `/attendance/recent-check-ins?limit=${limit}` : '/attendance/recent-check-ins';
    const response = await api.get(url);
    return response.data;
  },

  checkIn: async (locationData: any): Promise<ApiResponse<any>> => {
    const response = await api.post('/attendance/checkin', locationData);
    return response.data;
  },

  checkOut: async (locationData: any): Promise<ApiResponse<any>> => {
    const response = await api.post('/attendance/checkout', locationData);
    return response.data;
  },

  // New endpoint for all staff attendance with date filtering
  getAllStaffAttendance: async (startDate?: string, endDate?: string, viewType: string = 'summary', page: number = 1, limit: number = 100): Promise<any> => {
    const params = new URLSearchParams();
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    params.append('view_type', viewType);
    params.append('page', page.toString());
    params.append('limit', limit.toString());
    const response = await api.get(`/attendance/all?${params.toString()}`);
    return response.data;
  },
};

// Requests API
export const requestsApi = {
  getRequestsSummary: async (): Promise<any> => {
    const response = await api.get('/requests/summary');
    return response.data;
  },

  getAllRequests: async (): Promise<any> => {
    const response = await api.get('/requests');
    return response.data;
  },

  approveRequest: async (requestId: string): Promise<ApiResponse<any>> => {
    const response = await api.put(`/requests/${requestId}/approve`);
    return response.data;
  },

  rejectRequest: async (requestId: string, reason: string): Promise<ApiResponse<any>> => {
    const response = await api.put(`/requests/${requestId}/reject`, { reason });
    return response.data;
  },
};

// Announcements API
export const announcementsApi = {
  getAnnouncements: async (limit?: number): Promise<any> => {
    const url = limit ? `/api/announcements?limit=${limit}` : '/api/announcements';
    const response = await api.get(url);
    return response.data;
  },

  createAnnouncement: async (announcementData: any): Promise<any> => {
    const response = await api.post('/api/announcements', announcementData);
    return response.data;
  },

  updateAnnouncement: async (announcementId: string, announcementData: any): Promise<ApiResponse<any>> => {
    const response = await api.put(`/api/announcements/${announcementId}`, announcementData);
    return response.data;
  },

  deleteAnnouncement: async (announcementId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/api/announcements/${announcementId}`);
    return response.data;
  },
};

// Designations API
export const designationsApi = {
  getAllDesignations: async (): Promise<PaginatedResponse<Designation>> => {
    const response = await api.get('/lookup/designations');
    return response.data;
  },

  createDesignation: async (designationData: Partial<Designation>): Promise<ApiResponse<Designation>> => {
    const response = await api.post('/lookup/designations', designationData);
    return response.data;
  },

  updateDesignation: async (designationId: string, designationData: Partial<Designation>): Promise<ApiResponse<Designation>> => {
    const response = await api.put(`/lookup/designations/${designationId}`, designationData);
    return response.data;
  },

  deleteDesignation: async (designationId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/lookup/designations/${designationId}`);
    return response.data;
  },
};

// Notifications API
export interface BroadcastNotificationRequest {
  title: string;
  body: string;
  notification_type: string;
  target: 'all' | 'department' | 'role';
  target_value?: string;
  data?: Record<string, string>;
}

export interface AdvancedBroadcastNotificationRequest {
  title: string;
  body: string;
  notification_type: string;
  data?: Record<string, string>;
  target_audience?: string;
  specific_users?: string[];
  department_filter?: string;
  role_filter?: string;
  user_type_filter?: string[];
  status_filter?: string;
}

export interface NotificationType {
  value: string;
  label: string;
  description: string;
}

export interface BroadcastTypesResponse {
  notification_types: NotificationType[];
  targets: { value: string; label: string }[];
}

export interface BroadcastResponse {
  status: string;
  message: string;
  target?: string;
  target_value?: string;
  recipients: {
    total: number;
    by_role: Record<string, number>;
  };
  fcm_sent: number;
  fcm_failed: number;
  in_app_created: number;
  fcm_responses?: any[];
}

export interface TargetingDepartment {
  department_id: string;
  name: string;
  active_users: number;
}

export interface TargetingRole {
  role_id: string;
  name: string;
  active_users: number;
}

export interface UserStatistics {
  overall: {
    total_users: number;
    active_users: number;
    inactive_users: number;
    users_with_fcm_tokens: number;
  };
  by_role: Array<{
    role_name: string;
    active_users: number;
  }>;
  by_department: Array<{
    department_name: string;
    active_users: number;
  }>;
}

export interface BroadcastLog {
  broadcast_id: string;
  broadcast_type: string;
  title: string;
  body: string;
  notification_type: string;
  target_audience: string;
  targeting_criteria: any;
  recipients_summary: any;
  fcm_sent: number;
  fcm_failed: number;
  created_at: string;
  created_by?: string;
}

export interface BroadcastLogsResponse {
  broadcasts: BroadcastLog[];
  total: number;
  page: number;
  per_page: number;
  pages: number;
}

export const notificationsApi = {
  getBroadcastTypes: async (): Promise<BroadcastTypesResponse> => {
    const response = await api.get('/notifications/broadcast/types');
    return response.data;
  },

  sendBroadcast: async (notification: BroadcastNotificationRequest): Promise<BroadcastResponse> => {
    const response = await api.post('/notifications/broadcast', notification);
    return response.data;
  },

  sendAdvancedBroadcast: async (notification: AdvancedBroadcastNotificationRequest): Promise<BroadcastResponse> => {
    const response = await api.post('/notifications/broadcast-advanced', notification);
    return response.data;
  },

  // Targeting helper endpoints
  getTargetingDepartments: async (): Promise<{ departments: TargetingDepartment[]; count: number }> => {
    const response = await api.get('/notifications/targeting/departments');
    return response.data;
  },

  getTargetingRoles: async (): Promise<{ roles: TargetingRole[]; count: number }> => {
    const response = await api.get('/notifications/targeting/roles');
    return response.data;
  },

  getUserStatistics: async (): Promise<UserStatistics> => {
    const response = await api.get('/notifications/targeting/user-stats');
    return response.data;
  },

  // Broadcast logs for audit
  getBroadcastLogs: async (page: number = 1, perPage: number = 20, broadcastType?: string, notificationType?: string): Promise<BroadcastLogsResponse> => {
    const params = new URLSearchParams({
      page: page.toString(),
      per_page: perPage.toString(),
    });
    if (broadcastType) params.append('broadcast_type', broadcastType);
    if (notificationType) params.append('notification_type', notificationType);
    
    const response = await api.get(`/notifications/broadcast-logs?${params.toString()}`);
    return response.data;
  },

  getBroadcastLogDetail: async (broadcastId: string): Promise<BroadcastLog> => {
    const response = await api.get(`/notifications/broadcast-logs/${broadcastId}`);
    return response.data;
  },

  testPushNotification: async (title?: string, body?: string): Promise<ApiResponse<any>> => {
    const params = new URLSearchParams();
    if (title) params.append('title', title);
    if (body) params.append('body', body);
    const response = await api.post(`/notifications/test-push?${params.toString()}`);
    return response.data;
  },
};

// Reports API
export interface MonthlyReportRequest {
  year: number;
  month: number;
  department_id?: string;
  user_id?: string;
}

export interface MonthlyReportData {
  employee_name: string;
  employee_number: string;
  department: string;
  total_days: number;
  present_days: number;
  absent_days: number;
  late_days: number;
  early_checkout_days: number;
  total_hours: number;
  average_hours: number;
  attendance_records: Array<{
    date: string;
    check_in_time: string;
    check_out_time?: string;
    status: string;
    work_hours: number;
    shift_type?: string;
  }>;
}

export interface MonthlyReportResponse {
  year: number;
  month: number;
  total_employees: number;
  data: MonthlyReportData[];
}

export interface DepartmentOption {
  department_id: string;
  name: string;
}

export interface EmployeeOption {
  user_id: string;
  name: string;
  employee_number: string;
  department: string;
}

export interface AttendanceRecord {
  date: string;
  check_in_time: string;
  check_out_time: string;
  work_hours: number | null;
  shift_type: string;
  late_reason: string | null;
  early_checkout_reason: string | null;
}

export interface AttendanceSummary {
  total_days: number;
  present_days: number;
  absent_days: number;
  on_time: number;
  late: number;
  early_out: number;
  total_work_hours: number;
  avg_hours: number;
}

export interface StaffReportPreview {
  user_name: string;
  department: string | null;
  start_date: string;
  end_date: string;
  summary: AttendanceSummary;
  records: AttendanceRecord[];
}

export interface StaffRecord {
  staff_name: string;
  days_present: number;
  days_absent: number;
  on_time: number;
  late: number;
  early_out: number;
  total_hours: number;
  avg_hours: number;
}

export interface DepartmentReportPreview {
  department_name: string;
  start_date: string;
  end_date: string;
  total_staff: number;
  staff_records: StaffRecord[];
}

export const reportsApi = {
  getMonthlyReport: async (request: MonthlyReportRequest, format: 'json' | 'pdf' = 'json'): Promise<MonthlyReportResponse | Blob> => {
    const params = new URLSearchParams({ format });
    const response = await api.post(`/reports/monthly-attendance?${params.toString()}`, request, {
      responseType: format === 'pdf' ? 'blob' : 'json'
    });
    return response.data;
  },

  getDepartments: async (): Promise<DepartmentOption[]> => {
    const response = await api.get('/reports/departments');
    return response.data;
  },

  getEmployees: async (departmentId?: string): Promise<EmployeeOption[]> => {
    const params = departmentId ? `?department_id=${departmentId}` : '';
    const response = await api.get(`/reports/employees${params}`);
    return response.data;
  },

  downloadDepartmentPdf: async (startDate: string, endDate: string, departmentId?: string): Promise<void> => {
    const params = new URLSearchParams({ start_date: startDate, end_date: endDate });
    if (departmentId) {
      params.append('department_id', departmentId);
    }
    const response = await api.get(`/attendance/reports/department/pdf?${params.toString()}`, {
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/pdf' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    const deptName = departmentId ? `department_${departmentId}` : 'all_departments';
    a.download = `${deptName}_attendance_${startDate}_to_${endDate}.pdf`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  },

  getDepartmentPreview: async (startDate: string, endDate: string, departmentId?: string): Promise<DepartmentReportPreview> => {
    const params = new URLSearchParams({ start_date: startDate, end_date: endDate });
    if (departmentId) {
      params.append('department_id', departmentId);
    }
    const response = await api.get(`/attendance/reports/department?${params.toString()}`);
    return response.data;
  },

  getStaffPreview: async (userId: string, startDate: string, endDate: string): Promise<StaffReportPreview> => {
    const params = new URLSearchParams({ user_id: userId, start_date: startDate, end_date: endDate });
    const response = await api.get(`/attendance/reports/attendance?${params.toString()}`);
    return response.data;
  },

  downloadStaffPdf: async (userId: string, userName: string, startDate: string, endDate: string): Promise<void> => {
    const params = new URLSearchParams({ start_date: startDate, end_date: endDate });
    const response = await api.get(`/attendance/reports/attendance/pdf/${userId}?${params.toString()}`, {
      responseType: 'blob'
    });
    const blob = new Blob([response.data], { type: 'application/pdf' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    const safeName = userName.replace(/\s+/g, '_');
    a.download = `${safeName}_attendance_${startDate}_to_${endDate}.pdf`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  },
};

// Shift Configuration Types
export interface ShiftConfiguration {
  shift_config_id: string;
  shift_name: string;
  shift_type: string;
  check_in_earliest: string;
  check_in_latest: string;
  official_start_time: string;
  check_out_earliest: string;
  check_out_latest: string;
  official_end_time: string;
  extended_start_time: string;
  late_threshold: string;
  is_active: boolean;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface ShiftConfigurationCreate {
  shift_name: string;
  shift_type: string;
  check_in_earliest: string;
  check_in_latest: string;
  official_start_time: string;
  check_out_earliest: string;
  check_out_latest: string;
  official_end_time: string;
  extended_start_time: string;
  late_threshold: string;
  description?: string;
}

export interface ShiftConfigurationUpdate {
  shift_name?: string;
  check_in_earliest?: string;
  check_in_latest?: string;
  official_start_time?: string;
  check_out_earliest?: string;
  check_out_latest?: string;
  official_end_time?: string;
  extended_start_time?: string;
  late_threshold?: string;
  is_active?: boolean;
  description?: string;
}

// Shift Configurations API
export const shiftConfigurationsApi = {
  getAll: async (): Promise<ShiftConfiguration[]> => {
    const response = await api.get('/shift-configurations/');
    return response.data;
  },

  getByType: async (shiftType: string): Promise<ShiftConfiguration> => {
    const response = await api.get(`/shift-configurations/${shiftType}`);
    return response.data;
  },

  create: async (config: ShiftConfigurationCreate): Promise<ShiftConfiguration> => {
    const response = await api.post('/shift-configurations/', config);
    return response.data;
  },

  update: async (id: string, config: ShiftConfigurationUpdate): Promise<ShiftConfiguration> => {
    const response = await api.put(`/shift-configurations/${id}`, config);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/shift-configurations/${id}`);
  },
};

// Dashboard API
export interface WeeklyTrendData {
  label: string;
  date: string;
  value: number;
}

export interface DepartmentDistributionData {
  label: string;
  value: number;
  color: string;
}

export interface AnalyticsStats {
  weekly_trend_change: number;
  efficiency_rate: number;
  active_requests: number;
}

export interface PerformanceMetrics {
  productivity: number;
  attendance: number;
  satisfaction: number;
}

export interface WeeklyActivity {
  check_ins: number;
  check_outs: number;
  overtime: number;
}

export interface ActivityHeatmap {
  heatmap_data: number[][];
}

export const dashboardApi = {
  getWeeklyTrend: async (): Promise<WeeklyTrendData[]> => {
    const response = await api.get('/dashboard/weekly-trend');
    return response.data;
  },

  getDepartmentDistribution: async (): Promise<DepartmentDistributionData[]> => {
    const response = await api.get('/dashboard/department-distribution');
    return response.data;
  },

  getAnalyticsStats: async (): Promise<AnalyticsStats> => {
    const response = await api.get('/dashboard/analytics-stats');
    return response.data;
  },

  getPerformanceMetrics: async (): Promise<PerformanceMetrics> => {
    const response = await api.get('/dashboard/performance-metrics');
    return response.data;
  },

  getWeeklyActivity: async (): Promise<WeeklyActivity> => {
    const response = await api.get('/dashboard/weekly-activity');
    return response.data;
  },

  getActivityHeatmap: async (): Promise<ActivityHeatmap> => {
    const response = await api.get('/dashboard/activity-heatmap');
    return response.data;
  },
};

export default api;
