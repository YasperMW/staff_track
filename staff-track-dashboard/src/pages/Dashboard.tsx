import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { attendanceApi, requestsApi, announcementsApi, dashboardApi } from '../services/api';
import type { WeeklyTrendData, DepartmentDistributionData } from '../services/api';
import {
  Clock,
  AlertTriangle,
  Bell,
  RefreshCw,
  Calendar,
  Eye,
  ChevronRight,
  Pause,
  Play,
} from 'lucide-react';
import {
  LineChart,
  PieChart,
} from '../components/Charts';
import { DashboardSkeleton } from '../components/LoadingSkeleton';

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
  check_in_time: string;
  work_hours?: number;
  status: string;
  department: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
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
  const [weeklyTrend, setWeeklyTrend] = useState<WeeklyTrendData[]>([]);
  const [departmentDistribution, setDepartmentDistribution] = useState<DepartmentDistributionData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    loadDashboardData();
  }, []);

  useEffect(() => {
    if (!autoRefresh) return;
    const interval = setInterval(() => loadDashboardData(), 30000);
    return () => clearInterval(interval);
  }, [autoRefresh]);

  const loadDashboardData = async () => {
    setIsLoading(true);
    try {
      const [
        attendanceSummary,
        requestsSummary,
        announcements,
        recentCheckIns,
        weeklyTrendData,
        deptDistData
      ] = await Promise.all([
        attendanceApi.getTeamTodaySummary(),
        requestsApi.getRequestsSummary(),
        announcementsApi.getAnnouncements(3),
        attendanceApi.getRecentCheckIns(10),
        dashboardApi.getWeeklyTrend(),
        dashboardApi.getDepartmentDistribution()
      ]);

      setStats(prev => ({
        ...prev,
        totalStaff: attendanceSummary.total_staff || 0,
        presentToday: attendanceSummary.present || 0,
        lateToday: attendanceSummary.late || 0,
        absentToday: attendanceSummary.absent || 0,
      }));

      if (requestsSummary.byType) {
        setStats(prev => ({
          ...prev,
          pendingLeave: requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('leave'))?.count || 0,
          pendingWFH: requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('wfh'))?.count || 0,
          pendingShiftChange: requestsSummary.byType.find((r: any) => r.type.toLowerCase().includes('shift'))?.count || 0,
        }));
      }

      const announcementsData = Array.isArray(announcements) ? announcements : (announcements.items || []);
      setRecentAnnouncements(announcementsData.slice(0, 3));

      const checkInsData = Array.isArray(recentCheckIns) ? recentCheckIns : (recentCheckIns.recent_check_ins || []);
      setTeamAttendance(checkInsData);

      setWeeklyTrend(weeklyTrendData);
      setDepartmentDistribution(deptDistData);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setIsLoading(false);
      setLastUpdated(new Date());
    }
  };

  const formatTime = (date: Date) =>
    date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });

  const formatDate = (date: Date) =>
    date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

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
      default:
        return 'bg-gray-100 text-gray-600';
    }
  };

  if (isLoading) {
    return <DashboardSkeleton />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="header-gradient rounded-2xl p-4 md:p-8 text-white shadow-2xl">
        <div className="flex flex-col space-y-4 md:space-y-0 md:flex-row md:items-center md:justify-between">
          <div className="mb-4 md:mb-0">
            <div className="flex items-center space-x-3 md:space-x-4 mb-3">
              <img src="/src/assets/logo.png" alt="Staff Track Logo" className="w-10 h-10 md:w-12 md:h-12 object-contain" />
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
                <Clock className="w-4 h-4" />
                <span className="text-xs md:text-sm">Updated {formatTime(lastUpdated)}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-2 md:space-x-3">
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`w-8 h-8 md:w-10 md:h-10 rounded-xl flex items-center justify-center transition-all backdrop-blur-sm ${
                autoRefresh ? 'bg-green-500 bg-opacity-30 text-white' : 'bg-white bg-opacity-20 text-blue-100'
              }`}
              title={autoRefresh ? 'Pause auto-refresh' : 'Resume auto-refresh'}
            >
              {autoRefresh ? <Pause className="w-4 h-4 md:w-5 md:h-5" /> : <Play className="w-4 h-4 md:w-5 md:h-5" />}
            </button>

            <button
              onClick={loadDashboardData}
              disabled={isLoading}
              className="w-8 h-8 md:w-10 md:h-10 bg-white bg-opacity-20 rounded-xl flex items-center justify-center hover:bg-opacity-30 transition-all disabled:opacity-50"
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
            Auto-refresh paused — data may be stale. Last updated at <span className="font-semibold">{formatTime(lastUpdated)}</span>.
          </p>
          <button onClick={() => setAutoRefresh(true)} className="ml-auto text-xs font-semibold px-3 py-1 bg-amber-100 dark:bg-amber-800 hover:bg-amber-200 dark:hover:bg-amber-700 rounded-lg transition-colors">
            Resume
          </button>
        </div>
      )}

      {/* Today's Summary */}
      <div className="relative bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-2xl md:rounded-3xl p-4 md:p-8 text-white shadow-2xl overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 md:w-40 md:h-40 bg-white opacity-10 rounded-full -mr-16 md:-mr-20 -mt-16 md:-mt-20" />
        <div className="absolute bottom-0 left-0 w-24 h-24 md:w-32 md:h-32 bg-white opacity-10 rounded-full -ml-12 md:-ml-16 -mb-12 md:-mb-16" />

        <div className="relative z-10">
          <div className="flex items-center justify-between mb-4 md:mb-6">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 md:w-10 md:h-10 bg-white bg-opacity-20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                <Calendar className="w-4 h-4 md:w-5 md:h-5" />
              </div>
              <p className="font-semibold text-sm md:text-base opacity-90">Today's Attendance</p>
            </div>
            <div className="px-2 py-1 md:px-3 md:py-1 bg-white bg-opacity-20 rounded-full text-xs font-semibold backdrop-blur-sm">
              {currentTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
            </div>
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

      {/* Quick Actions & Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
        <div className="dashboard-card p-4 md:p-6">
          <h3 className="text-base md:text-lg font-bold text-gray-900 dark:text-gray-100 mb-4">Quick Actions</h3>
          <div className="space-y-2 md:space-y-3">
            <button onClick={handleNavigateToRequests} className="w-full btn-outline flex items-center justify-between group hover:bg-blue-50 hover:border-blue-300 transition-all py-2 md:py-3">
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
            <button onClick={handleNavigateToAttendance} className="w-full btn-outline flex items-center justify-between group hover:bg-green-50 hover:border-green-300 transition-all py-2 md:py-3">
              <div className="flex items-center space-x-2 md:space-x-3">
                <Clock className="w-4 h-4 text-green-500" />
                <span className="font-medium text-sm md:text-base">Attendance Report</span>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-green-500" />
            </button>
            <button onClick={handleNavigateToAnnouncements} className="w-full btn-outline flex items-center justify-between group hover:bg-purple-50 hover:border-purple-300 transition-all py-2 md:py-3">
              <div className="flex items-center space-x-2 md:space-x-3">
                <Bell className="w-4 h-4 text-purple-500" />
                <span className="font-medium text-sm md:text-base">Manage Announcements</span>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-purple-500" />
            </button>
          </div>
        </div>

        <div className="dashboard-card p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4">Weekly Trend</h3>
          <LineChart data={weeklyTrend} height={200} color="#3B82F6" />
        </div>

        <div className="dashboard-card p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4">Department Distribution</h3>
          <PieChart data={departmentDistribution} size={200} />
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Announcements */}
        <div className="dashboard-card p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Recent Announcements</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Latest updates and notifications</p>
            </div>
            <button onClick={handleNavigateToAnnouncements} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
              <ChevronRight className="w-4 h-4 text-gray-500" />
            </button>
          </div>

          {recentAnnouncements.length === 0 ? (
            <div className="text-center py-8">
              <div className="w-12 h-12 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-4">
                <Bell className="w-6 h-6 text-gray-400" />
              </div>
              <p className="text-gray-500 dark:text-gray-400">No announcements yet</p>
            </div>
          ) : (
            <div className="space-y-4 mb-6">
              {recentAnnouncements.map((announcement) => (
                <div key={announcement.id} onClick={handleNavigateToAnnouncements} className="flex items-center space-x-3 p-4 bg-gray-50 dark:bg-gray-800 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer">
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-gray-100 text-sm hover:text-blue-600 transition-colors">{announcement.title}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{announcement.target_audience} • {new Date(announcement.created_at).toLocaleDateString()}</p>
                  </div>
                  <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-600">{announcement.type}</span>
                </div>
              ))}
            </div>
          )}

          <button onClick={handleNavigateToAnnouncements} className="btn-primary w-full flex items-center justify-center space-x-2">
            <Eye className="w-4 h-4" />
            <span>View All Announcements</span>
          </button>
        </div>

        {/* Team Attendance */}
        <div className="dashboard-card p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Team Attendance</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Recent check-ins</p>
            </div>
            <button onClick={handleNavigateToAttendance} className="btn-ghost flex items-center space-x-1 text-sm">
              <Clock className="w-4 h-4" />
              <span>View All</span>
            </button>
          </div>

          {teamAttendance.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500 dark:text-gray-400">No recent check-ins</p>
            </div>
          ) : (
            <div className="space-y-3">
              {teamAttendance.slice(0, 5).map((member) => (
                <div key={member.attendance_log_id} onClick={handleNavigateToAttendance} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-all cursor-pointer">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 avatar-gradient rounded-full flex items-center justify-center text-white font-semibold text-sm">
                      {member.name ? member.name.split(' ').map(n => n[0]).join('') : '??'}
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-gray-100 text-sm">{member.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{member.department}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`status-badge ${getStatusColor(member.status)}`}>{member.status}</span>
                    {member.check_in_time && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {new Date(member.check_in_time).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
