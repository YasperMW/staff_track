import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { attendanceApi, requestsApi, announcementsApi } from '../services/api';
import {
  Users,
  Clock,
  AlertTriangle,
  UserX,
  TrendingUp,
  Bell,
  RefreshCw,
  User,
  Calendar,
  Activity,
  Target,
  Eye,
  BarChart3,
  Filter,
  Download,
  ChevronRight,
  MoreVertical,
  Zap,
  Pause,
  Play,
} from 'lucide-react';
import {
  BarChart,
  LineChart,
  PieChart,
  ProgressRing,
  ActivityHeatmap
} from '../components/Charts';

interface DashboardStats {
  totalStaff: number;
  presentToday: number;
  lateToday: number;
  absentToday: number;
  pendingLeave: number;
  pendingWFH: number;
  pendingShiftChange: number;
}

interface RecentAnnouncement {
  id: string;
  title: string;
  type: string;
  target_audience: string;
  created_at: string;
}

interface TeamAttendanceMember {
  attendance_log_id: string;
  user_id: string;
  name: string;
  employee_number: string;
  check_in_time: string;
  check_out_time?: string;
  location?: string;
  work_hours?: number;
  shift_type?: string;
  status: string;
  department: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const animationTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [currentTime, setCurrentTime] = useState(new Date());
  const [stats, setStats] = useState<DashboardStats>({
    totalStaff: 0,
    presentToday: 0,
    lateToday: 0,
    absentToday: 0,
    pendingLeave: 0,
    pendingWFH: 0,
    pendingShiftChange: 0,
  });
  const [recentAnnouncements, setRecentAnnouncements] = useState<RecentAnnouncement[]>([]);
  const [teamAttendance, setTeamAttendance] = useState<TeamAttendanceMember[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedTimeRange, setSelectedTimeRange] = useState<'today' | 'week' | 'month'>('today');
  const [showNotifications, setShowNotifications] = useState(false);
  const [animatedStats, setAnimatedStats] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    loadDashboardData();
    // Trigger animations after data loads — store ref so we can clean up on unmount
    animationTimerRef.current = setTimeout(() => setAnimatedStats(true), 500);
    return () => {
      if (animationTimerRef.current) clearTimeout(animationTimerRef.current);
    };
  }, []);

  // Separate effect so the interval actually starts/stops when autoRefresh changes
  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(() => {
      loadDashboardData();
    }, 30000);
    return () => clearInterval(interval);
  }, [autoRefresh]);

  const loadDashboardData = async () => {
    setIsLoading(true);
    try {
      const [attendanceSummary, requestsSummary, announcements, recentCheckIns] = await Promise.all([
        attendanceApi.getTeamTodaySummary(),
        requestsApi.getRequestsSummary(),
        announcementsApi.getAnnouncements(3),
        attendanceApi.getRecentCheckIns(10), // Get 10 recent check-ins for dashboard
      ]);

      // Process attendance summary
      setStats(prev => ({
        ...prev,
        totalStaff: attendanceSummary.total_staff || 0,
        presentToday: attendanceSummary.present || 0,
        lateToday: attendanceSummary.late || 0,
        absentToday: attendanceSummary.absent || 0,
      }));

      // Process requests summary
      if (requestsSummary.byType) {
        const leaveCount = requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('leave'))?.count || 0;
        const wfhCount = requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('wfh'))?.count || 0;
        const shiftCount = requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('shift'))?.count || 0;
        
        setStats(prev => ({
          ...prev,
          pendingLeave: leaveCount,
          pendingWFH: wfhCount,
          pendingShiftChange: shiftCount,
        }));
      }

      // Process announcements - handle different response formats
      const announcementsData = Array.isArray(announcements) ? announcements : (announcements.items || []);
      setRecentAnnouncements(announcementsData.slice(0, 3));

      // Process recent check-ins - handle different response formats
      const checkInsData = Array.isArray(recentCheckIns) ? recentCheckIns : (recentCheckIns.recent_check_ins || []);
      setTeamAttendance(checkInsData);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setIsLoading(false);
      setLastUpdated(new Date());
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true,
    });
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const handleNavigateToAnnouncements = () => navigate('/announcements');
  const handleNavigateToAttendance = () => navigate('/attendance');
  const handleNavigateToRequests = () => navigate('/requests');

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'present':
      case 'active':
        return 'status-present';
      case 'absent':
        return 'status-absent';
      case 'late':
        return 'status-late';
      case 'checked out':
        return 'bg-gray-100 text-gray-600';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  };

  const getAnnouncementIcon = (type: string) => {
    switch (type.toLowerCase()) {
      case 'urgent':
        return <AlertTriangle className="w-4 h-4" />;
      case 'policy':
        return <Bell className="w-4 h-4" />;
      default:
        return <Bell className="w-4 h-4" />;
    }
  };

  const getAnnouncementColor = (type: string) => {
    switch (type.toLowerCase()) {
      case 'urgent':
        return 'text-red-600 bg-red-100';
      case 'policy':
        return 'text-blue-600 bg-blue-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  return (
    <div className="space-y-6">
      {/* Enhanced Header - Mobile Optimized */}
      <div className="header-gradient rounded-2xl p-4 md:p-8 text-white shadow-2xl">
        <div className="flex flex-col space-y-4 md:space-y-0 md:flex-row md:items-center md:justify-between">
          <div className="mb-4 md:mb-0">
            <div className="flex items-center space-x-3 md:space-x-4 mb-3">
              <div className="w-10 h-10 md:w-12 md:h-12 bg-white bg-opacity-20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                <User className="w-5 h-5 md:w-6 md:h-6" />
              </div>
              <div>
                <h1 className="text-xl md:text-3xl font-bold">Admin Dashboard</h1>
                <p className="text-blue-100 text-sm md:text-base">Welcome back, {user?.first_name || 'Admin'}!</p>
              </div>
            </div>
            <div className="flex flex-col md:flex-row md:items-center md:space-x-6 text-blue-100 space-y-2 md:space-y-0">
              <div className="flex items-center space-x-2">
                <Calendar className="w-4 h-4" />
                <span className="text-xs md:text-sm">{formatDate(currentTime)}</span>
              </div>
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4" />
                <span className="text-xs md:text-sm font-mono">{formatTime(currentTime)}</span>
              </div>
              <div className="flex items-center space-x-2">
                <Activity className="w-4 h-4" />
                <span className="text-xs md:text-sm">Updated {formatTime(lastUpdated)}</span>
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-2 md:space-x-3">
            <div className="flex bg-white bg-opacity-20 rounded-xl p-1 backdrop-blur-sm">
              {(['today', 'week', 'month'] as const).map((range) => (
                <button
                  key={range}
                  onClick={() => setSelectedTimeRange(range)}
                  className={`px-2 md:px-4 py-2 rounded-lg text-xs md:text-sm font-medium transition-all ${
                    selectedTimeRange === range
                      ? 'bg-white text-blue-600'
                      : 'text-blue-100 hover:bg-white hover:bg-opacity-10'
                  }`}
                >
                  {range.charAt(0).toUpperCase() + range.slice(1)}
                </button>
              ))}
            </div>
            
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`w-8 h-8 md:w-10 md:h-10 rounded-xl flex items-center justify-center transition-all backdrop-blur-sm ${
                autoRefresh 
                  ? 'bg-green-500 bg-opacity-30 text-white' 
                  : 'bg-white bg-opacity-20 text-blue-100 hover:bg-opacity-30'
              }`}
              title={autoRefresh ? 'Pause auto-refresh' : 'Resume auto-refresh'}
            >
              {autoRefresh ? (
                <Pause className="w-4 h-4 md:w-5 md:h-5" />
              ) : (
                <Play className="w-4 h-4 md:w-5 md:h-5" />
              )}
            </button>
            
            <button
              onClick={() => setShowNotifications(!showNotifications)}
              className="relative w-8 h-8 md:w-10 md:h-10 bg-white bg-opacity-20 rounded-xl flex items-center justify-center hover:bg-opacity-30 transition-all backdrop-blur-sm"
            >
              <Bell className="w-4 h-4 md:w-5 md:h-5" />
              {recentAnnouncements.length > 0 && (
                <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full animate-pulse" />
              )}
            </button>
            
            <button
              onClick={loadDashboardData}
              disabled={isLoading}
              className="w-8 h-8 md:w-10 md:h-10 bg-white bg-opacity-20 rounded-xl flex items-center justify-center hover:bg-opacity-30 transition-all backdrop-blur-sm disabled:opacity-50"
              title="Refresh data now"
            >
              <RefreshCw className={`w-4 h-4 md:w-5 md:h-5 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Auto-refresh paused banner */}
      {!autoRefresh && (
        <div className="flex items-center space-x-3 px-4 py-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-700 rounded-xl text-amber-700 dark:text-amber-300">
          <Pause className="w-4 h-4 flex-shrink-0" />
          <p className="text-sm font-medium">
            Auto-refresh paused — data may be stale. Last updated at{' '}
            <span className="font-semibold">{formatTime(lastUpdated)}</span>.
          </p>
          <button
            onClick={() => setAutoRefresh(true)}
            className="ml-auto text-xs font-semibold px-3 py-1 bg-amber-100 dark:bg-amber-800 hover:bg-amber-200 dark:hover:bg-amber-700 rounded-lg transition-colors flex-shrink-0"
          >
            Resume
          </button>
        </div>
      )}

      {/* Today's Summary Card - Management View */}
      <div className="relative bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-2xl md:rounded-3xl p-4 md:p-8 text-white shadow-2xl overflow-hidden group">
        <div className="absolute top-0 right-0 w-32 h-32 md:w-40 md:h-40 bg-white opacity-10 rounded-full -mr-16 md:-mr-20 -mt-16 md:-mt-20 group-hover:scale-110 transition-transform duration-500" />
        <div className="absolute bottom-0 left-0 w-24 h-24 md:w-32 md:h-32 bg-white opacity-10 rounded-full -ml-12 md:-ml-16 -mb-12 md:-mb-16 group-hover:scale-110 transition-transform duration-500" />

        <div className="relative z-10">
          <div className="flex items-center justify-between mb-4 md:mb-6">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 md:w-10 md:h-10 bg-white bg-opacity-20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                <Calendar className="w-4 h-4 md:w-5 md:h-5" />
              </div>
              <p className="font-semibold text-sm md:text-base opacity-90">Today's Attendance Snapshot</p>
            </div>
            <div className="px-2 py-1 md:px-3 md:py-1 bg-white bg-opacity-20 rounded-full text-xs font-semibold backdrop-blur-sm">
              {currentTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
            </div>
          </div>

          <div className="mb-4 md:mb-6">
            <p className="text-xl md:text-2xl font-bold mb-2">Staff Attendance Overview</p>
            <p className="text-sm md:text-base opacity-90">Real-time attendance statistics for today</p>
          </div>

          <div className="grid grid-cols-4 gap-2 md:gap-4">
            <div className="text-center bg-white bg-opacity-10 rounded-xl p-3">
              <p className="text-xl md:text-3xl font-bold">{stats.totalStaff}</p>
              <p className="text-xs md:text-xs opacity-80">Total Staff</p>
            </div>
            <div className="text-center bg-white bg-opacity-10 rounded-xl p-3">
              <p className="text-xl md:text-3xl font-bold text-green-300">{stats.presentToday}</p>
              <p className="text-xs md:text-xs opacity-80">Present</p>
            </div>
            <div className="text-center bg-white bg-opacity-10 rounded-xl p-3">
              <p className="text-xl md:text-3xl font-bold text-yellow-300">{stats.lateToday}</p>
              <p className="text-xs md:text-xs opacity-80">Late</p>
            </div>
            <div className="text-center bg-white bg-opacity-10 rounded-xl p-3">
              <p className="text-xl md:text-3xl font-bold text-red-300">{stats.absentToday}</p>
              <p className="text-xs md:text-xs opacity-80">Absent</p>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced Quick Actions - Mobile Optimized */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
        <div className="card p-4 md:p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base md:text-lg font-bold text-gray-900 dark:text-gray-100">Quick Actions</h3>
            <div className="w-6 h-6 md:w-8 md:h-8 bg-blue-100 rounded-lg flex items-center justify-center">
              <Zap className="w-3 h-3 md:w-4 md:h-4 text-blue-600" />
            </div>
          </div>
          <div className="space-y-2 md:space-y-3">
            <button 
              onClick={handleNavigateToRequests}
              className="w-full btn-outline flex items-center justify-between group hover:bg-blue-50 hover:border-blue-300 transition-all py-2 md:py-3"
            >
              <div className="flex items-center space-x-2 md:space-x-3">
                <AlertTriangle className="w-4 h-4 text-orange-500" />
                <span className="font-medium text-sm md:text-base">Pending Requests</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="px-2 py-1 bg-orange-100 text-orange-600 rounded-full text-xs font-semibold">
                  {stats.pendingLeave + stats.pendingWFH + stats.pendingShiftChange}
                </span>
                <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-blue-500" />
              </div>
            </button>
            <button 
              onClick={handleNavigateToAttendance}
              className="w-full btn-outline flex items-center justify-between group hover:bg-green-50 hover:border-green-300 transition-all py-2 md:py-3"
            >
              <div className="flex items-center space-x-2 md:space-x-3">
                <Clock className="w-4 h-4 text-green-500" />
                <span className="font-medium text-sm md:text-base">Attendance Report</span>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-green-500" />
            </button>
            <button 
              onClick={handleNavigateToAnnouncements}
              className="w-full btn-outline flex items-center justify-between group hover:bg-purple-50 hover:border-purple-300 transition-all py-2 md:py-3"
            >
              <div className="flex items-center space-x-2 md:space-x-3">
                <Bell className="w-4 h-4 text-purple-500" />
                <span className="font-medium text-sm md:text-base">Manage Announcements</span>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-purple-500" />
            </button>
          </div>
        </div>
        
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Analytics</h3>
            <div className="flex items-center space-x-2">
              <span className="px-2 py-0.5 text-xs font-semibold bg-amber-100 text-amber-700 rounded-full">Demo data</span>
              <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                <BarChart3 className="w-4 h-4 text-green-600" />
              </div>
            </div>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Weekly Trend</span>
              <div className="flex items-center space-x-1 text-green-600">
                <span className="text-sm font-semibold">↑ 12%</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Efficiency Rate</span>
              <div className="flex items-center space-x-1 text-blue-600">
                <span className="text-sm font-semibold">94%</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-400">Active Projects</span>
              <div className="flex items-center space-x-1 text-purple-600">
                <span className="text-sm font-semibold">8</span>
              </div>
            </div>
            <button className="w-full btn-primary flex items-center justify-center space-x-2">
              <Eye className="w-4 h-4" />
              <span>View Detailed Analytics</span>
            </button>
          </div>
        </div>
        
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Team Performance</h3>
            <div className="flex items-center space-x-2">
              <span className="px-2 py-0.5 text-xs font-semibold bg-amber-100 text-amber-700 rounded-full">Demo data</span>
              <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                <Target className="w-4 h-4 text-purple-600" />
              </div>
            </div>
          </div>
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-600 dark:text-gray-400">Productivity</span>
                <span className="text-sm font-semibold">87%</span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div className="bg-purple-500 h-2 rounded-full" style={{ width: '87%' }} />
              </div>
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-600 dark:text-gray-400">Attendance</span>
                <span className="text-sm font-semibold">92%</span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: '92%' }} />
              </div>
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-600 dark:text-gray-400">Satisfaction</span>
                <span className="text-sm font-semibold">95%</span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div className="bg-blue-500 h-2 rounded-full" style={{ width: '95%' }} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className={`card p-6 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 ${animatedStats ? 'animate-fade-in-up' : 'opacity-0'}`}>
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 avatar-gradient rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.presentToday}/{stats.totalStaff}</p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Staff Present</p>
          </div>
        </div>
        
        <div className={`card p-6 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 ${animatedStats ? 'animate-fade-in-up animation-delay-100' : 'opacity-0'}`}>
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-amber-400 to-amber-600 rounded-xl flex items-center justify-center">
              <Clock className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.lateToday}</p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Late Arrivals</p>
          </div>
        </div>
        
        <div className={`card p-6 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 ${animatedStats ? 'animate-fade-in-up animation-delay-200' : 'opacity-0'}`}>
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-red-400 to-red-600 rounded-xl flex items-center justify-center">
              <UserX className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.absentToday}</p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Absent</p>
          </div>
        </div>
        
        <div className={`card p-6 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 ${animatedStats ? 'animate-fade-in-up animation-delay-300' : 'opacity-0'}`}>
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-green-400 to-green-600 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">
              {stats.totalStaff > 0 ? Math.round((stats.presentToday / stats.totalStaff) * 100) : 0}%
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Attendance Rate</p>
          </div>
          <div className="mt-4 h-12">
            <svg width="100%" height="100%" className="overflow-visible">
              <polyline
                points="0,30 20,25 40,20 60,22 80,15 100,18 120,10"
                fill="none"
                stroke="#10B981"
                strokeWidth="2"
                className="transition-all duration-500"
              />
            </svg>
          </div>
        </div>
      </div>

      {/* Enhanced Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Weekly Attendance Trend</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Staff presence over the last 7 days</p>
            </div>
            <div className="flex items-center space-x-2">
              <span className="px-2 py-0.5 text-xs font-semibold bg-amber-100 text-amber-700 rounded-full">Demo data</span>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                <MoreVertical className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>
          <LineChart
            data={[
              { label: 'Mon', value: 45 },
              { label: 'Tue', value: 52 },
              { label: 'Wed', value: 48 },
              { label: 'Thu', value: 58 },
              { label: 'Fri', value: 62 },
              { label: 'Sat', value: 35 },
              { label: 'Sun', value: 28 }
            ]}
            height={200}
            color="#3B82F6"
          />
        </div>
        
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Department Distribution</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Current staffing across departments</p>
            </div>
            <div className="flex items-center space-x-2">
              <span className="px-2 py-0.5 text-xs font-semibold bg-amber-100 text-amber-700 rounded-full">Demo data</span>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                <MoreVertical className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>
          <PieChart
            data={[
              { label: 'Emergency', value: 25, color: '#3B82F6' },
              { label: 'ICU', value: 18, color: '#10B981' },
              { label: 'Surgery', value: 22, color: '#F59E0B' },
              { label: 'Pediatrics', value: 15, color: '#8B5CF6' },
              { label: 'Other', value: 20, color: '#6B7280' }
            ]}
            size={200}
          />
        </div>
      </div>

      {/* Enhanced Request Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Pending Requests</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Current pending requests</p>
            </div>
            <div className="px-2 py-1 bg-orange-100 text-orange-600 rounded-full text-xs font-semibold">
              {stats.pendingLeave + stats.pendingWFH + stats.pendingShiftChange}
            </div>
          </div>
          <BarChart
            data={[
              { label: 'Leave', value: stats.pendingLeave, color: '#3B82F6' },
              { label: 'WFH', value: stats.pendingWFH, color: '#10B981' },
              { label: 'Shift Change', value: stats.pendingShiftChange, color: '#F59E0B' }
            ]}
            height={150}
          />
        </div>
        
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Attendance Rate</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Today's staff presence</p>
            </div>
          </div>
          <ProgressRing
            value={stats.presentToday}
            maxValue={stats.totalStaff}
            size={150}
            color="#3B82F6"
          />
        </div>
        
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Weekly Activity</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Total activities this week</p>
            </div>
            <div className="flex items-center space-x-2">
              <span className="px-2 py-0.5 text-xs font-semibold bg-amber-100 text-amber-700 rounded-full">Demo data</span>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                <Download className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>
          <BarChart
            data={[
              { label: 'Check-ins', value: 156, color: '#10B981' },
              { label: 'Check-outs', value: 142, color: '#F59E0B' },
              { label: 'Overtime', value: 28, color: '#8B5CF6' }
            ]}
            height={150}
          />
        </div>
      </div>

      {/* Enhanced Activity Heatmap */}
      <div className="card p-6 hover:shadow-lg transition-shadow">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Staff Activity Heatmap</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">Daily activity patterns over the last 4 weeks</p>
          </div>
          <div className="flex items-center space-x-2">
            <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
              <Filter className="w-4 h-4 text-gray-500" />
            </button>
            <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
              <Download className="w-4 h-4 text-gray-500" />
            </button>
          </div>
        </div>
        <ActivityHeatmap
          data={[
            [5, 8, 12, 15, 18, 8, 3],    // Week 1
            [7, 10, 14, 16, 20, 12, 5],   // Week 2
            [6, 9, 11, 18, 22, 10, 4],    // Week 3
            [8, 12, 15, 20, 19, 11, 6],   // Week 4
          ]}
        />
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Enhanced Recent Announcements */}
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Recent Announcements</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Latest updates and notifications</p>
            </div>
            <div className="flex items-center space-x-2">
              <span className="px-3 py-1 bg-gradient-to-r from-sky-blue to-light-gold bg-opacity-20 text-white rounded-full text-xs font-semibold" 
                    style={{ background: 'linear-gradient(135deg, rgba(2, 132, 199, 0.2), rgba(245, 158, 11, 0.2))' }}>
                {recentAnnouncements.length} New
              </span>
              <button 
                onClick={handleNavigateToAnnouncements}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
              >
                <ChevronRight className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>

          {recentAnnouncements.length === 0 ? (
            <div className="text-center py-8">
              <div className="w-12 h-12 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-4">
                <Bell className="w-6 h-6 text-gray-400" />
              </div>
              <p className="text-gray-500 dark:text-gray-400">No announcements yet</p>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">Check back later for updates</p>
            </div>
          ) : (
            <div className="space-y-4 mb-6">
              {recentAnnouncements.map((announcement) => (
                <div 
                  key={announcement.id} 
                  className="flex items-center space-x-3 p-4 bg-gray-50 dark:bg-gray-800 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer group"
                  onClick={handleNavigateToAnnouncements}
                >
                  <div className={`p-3 rounded-xl ${getAnnouncementColor(announcement.type)} group-hover:scale-110 transition-transform`}>
                    {getAnnouncementIcon(announcement.type)}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-gray-100 text-sm group-hover:text-blue-600 transition-colors">
                      {announcement.title}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{announcement.target_audience}</p>
                  </div>
                  <div className="text-right">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getAnnouncementColor(announcement.type)}`}>
                      {announcement.type}
                    </span>
                    <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                      {new Date(announcement.created_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}

          <button onClick={handleNavigateToAnnouncements} className="btn-primary w-full flex items-center justify-center space-x-2">
            <Eye className="w-4 h-4" />
            <span>View All Announcements</span>
          </button>
        </div>

        {/* Enhanced Team Attendance */}
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Team Attendance</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Recent check-ins across all departments</p>
            </div>
            <div className="flex items-center space-x-2">
              <button 
                onClick={handleNavigateToAttendance}
                className="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 text-sm font-medium flex items-center space-x-1 px-3 py-1 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-all"
              >
                <Activity className="w-4 h-4" />
                <span>Live View</span>
              </button>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                <MoreVertical className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          </div>

          {teamAttendance.length === 0 ? (
            <div className="text-center py-8">
              <div className="w-12 h-12 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="w-6 h-6 text-gray-400" />
              </div>
              <p className="text-gray-500 dark:text-gray-400">No recent check-ins available</p>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">Recent check-ins will appear here</p>
            </div>
          ) : (
            <div className="space-y-3">
              {teamAttendance.slice(0, 5).map((member) => (
                <div 
                  key={member.attendance_log_id} 
                  className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-all cursor-pointer group"
                  onClick={handleNavigateToAttendance}
                >
                  <div className="flex items-center space-x-3">
                    <div className="relative">
                      <div className="w-10 h-10 avatar-gradient rounded-full flex items-center justify-center text-white font-semibold text-sm">
                        {member.name ? member.name.split(' ').map(n => n[0]).join('') : '??'}
                      </div>
                      <div
                        aria-label={`Status: ${member.status}`}
                        role="img"
                        className={`absolute -bottom-1 -right-1 w-3 h-3 rounded-full border-2 border-white dark:border-gray-800 ${
                          member.status.toLowerCase() === 'active' ? 'bg-green-500' :
                          member.status.toLowerCase() === 'present' ? 'bg-green-500' :
                          member.status.toLowerCase() === 'late' ? 'bg-amber-500' :
                          member.status.toLowerCase() === 'absent' ? 'bg-red-500' :
                          member.status.toLowerCase() === 'checked out' ? 'bg-gray-400' :
                          'bg-gray-400'
                        }`}
                      />
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-gray-100 text-sm group-hover:text-blue-600 transition-colors">
                        {member.name}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {member.department}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`status-badge ${getStatusColor(member.status)}`}>
                      {member.status}
                    </span>
                    {member.check_in_time && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        <Clock className="w-3 h-3 inline mr-1" />
                        {new Date(member.check_in_time).toLocaleTimeString('en-US', { 
                          hour: '2-digit', 
                          minute: '2-digit' 
                        })}
                      </p>
                    )}
                    {member.work_hours && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {member.work_hours.toFixed(1)}h
                      </p>
                    )}
                  </div>
                </div>
              ))}
              
              {teamAttendance.length > 5 && (
                <button 
                  onClick={handleNavigateToAttendance}
                  className="w-full text-center py-3 text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-all"
                >
                  View {teamAttendance.length - 5} more team members
                  <ChevronRight className="w-4 h-4 inline ml-1" />
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
