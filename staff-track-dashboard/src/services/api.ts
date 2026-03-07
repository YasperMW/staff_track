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
  created_at: string;
  updated_at: string;
  deleted_at?: string;
  deleted_by?: string;
  role_name: string;
  department_name?: string;
}

export interface Role {
  role_id: string;
  name: string;
  created_at: string;
}

export interface Department {
  department_id: string;
  name: string;
  description?: string;
  created_at: string;
  designations: string[];
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
      if (error.response?.status === 401) {
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
    const response = await api.get('/auth/verify-token');
    return response.data;
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

  createUser: async (userData: Partial<User>): Promise<ApiResponse<User>> => {
    const response = await api.post('/users/register', userData);
    return response.data;
  },

  updateUser: async (userId: string, userData: Partial<User>): Promise<ApiResponse<User>> => {
    const response = await api.put(`/users/users/${userId}`, userData);
    return response.data;
  },

  deleteUser: async (userId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/users/users/${userId}`);
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
    const response = await api.get('/lookup/roles');
    return response.data;
  },

  createRole: async (roleData: Partial<Role>): Promise<ApiResponse<Role>> => {
    const response = await api.post('/lookup/roles', roleData);
    return response.data;
  },

  updateRole: async (roleId: string, roleData: Partial<Role>): Promise<ApiResponse<Role>> => {
    const response = await api.put(`/lookup/roles/${roleId}`, roleData);
    return response.data;
  },

  deleteRole: async (roleId: string): Promise<ApiResponse<null>> => {
    const response = await api.delete(`/lookup/roles/${roleId}`);
    return response.data;
  },
};

// Attendance API
export const attendanceApi = {
  getTodayAttendance: async (): Promise<any> => {
    const response = await api.get('/attendance/today');
    return response.data;
  },

  getTeamTodaySummary: async (): Promise<any> => {
    const response = await api.get('/attendance/team/today/summary');
    return response.data;
  },

  getTeamTodayList: async (): Promise<any> => {
    const response = await api.get('/attendance/team/today/list');
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

  createAnnouncement: async (announcementData: any): Promise<ApiResponse<any>> => {
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

export default api;
