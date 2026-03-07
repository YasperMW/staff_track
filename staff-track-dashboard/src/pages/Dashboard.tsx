import React, { useState, useEffect } from 'react';
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
  MapPin,
  User,
} from 'lucide-react';
import {
  BarChart,
  LineChart,
  PieChart,
  ProgressRing,
  StatsCard,
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
  user_id: string;
  name: string;
  status: string;
  check_in_time?: string;
  department: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
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
  const [todayAttendance, setTodayAttendance] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setIsLoading(true);
    try {
      const [attendanceSummary, requestsSummary, announcements, teamList] = await Promise.all([
        attendanceApi.getTeamTodaySummary(),
        requestsApi.getRequestsSummary(),
        announcementsApi.getAnnouncements(3),
        attendanceApi.getTeamTodayList(),
      ]);

      console.log('Dashboard data:', {
        attendanceSummary,
        requestsSummary,
        announcements,
        teamList
      });

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

      // Process team attendance - handle different response formats
      const teamData = Array.isArray(teamList) ? teamList : (teamList.staff || teamList.items || []);
      setTeamAttendance(teamData);

      // Get today's attendance for current user
      try {
        const userAttendance = await attendanceApi.getTodayAttendance();
        setTodayAttendance(userAttendance);
      } catch (error) {
        // User might not have attendance record yet
        setTodayAttendance(null);
      }
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setIsLoading(false);
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

  const getAttendanceStatus = () => {
    if (!todayAttendance || todayAttendance.message === 'No attendance record for today') return 'Ready to check in';
    if (todayAttendance.check_in_time && !todayAttendance.check_out_time) return 'Currently working';
    if (todayAttendance.check_in_time && todayAttendance.check_out_time) return 'Completed for today';
    return 'Not checked in today';
  };

  const getButtonText = () => {
    if (!todayAttendance || todayAttendance.message === 'No attendance record for today') return 'Clock In';
    if (todayAttendance.check_in_time && !todayAttendance.check_out_time) return 'Clock Out';
    return 'View Details';
  };

  const handleClockAction = async () => {
    try {
      if (!todayAttendance || todayAttendance.message === 'No attendance record for today') {
        // Clock in - get user location
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            async (position) => {
              const locationData = {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
                accuracy: position.coords.accuracy,
                device_id: 'web-dashboard',
                shift_type: 'Day Shift'
              };
              
              const result = await attendanceApi.checkIn(locationData);
              console.log('Check-in successful:', result);
              await loadDashboardData(); // Refresh data
            },
            (error) => {
              console.error('Geolocation error:', error);
              // Fallback without location
              handleClockInWithoutLocation();
            }
          );
        } else {
          handleClockInWithoutLocation();
        }
      } else if (todayAttendance.check_in_time && !todayAttendance.check_out_time) {
        // Clock out
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            async (position) => {
              const locationData = {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
                accuracy: position.coords.accuracy,
                device_id: 'web-dashboard'
              };
              
              const result = await attendanceApi.checkOut(locationData);
              console.log('Check-out successful:', result);
              await loadDashboardData(); // Refresh data
            },
            (error) => {
              console.error('Geolocation error:', error);
              handleClockOutWithoutLocation();
            }
          );
        } else {
          handleClockOutWithoutLocation();
        }
      } else {
        // View details - navigate to attendance page
        window.location.href = '/attendance';
      }
    } catch (error: any) {
      console.error('Clock action error:', error);
      alert(error?.detail || 'Failed to perform clock action');
    }
  };

  const handleClockInWithoutLocation = async () => {
    const locationData = {
      location: 'Office - Main Building',
      device_id: 'web-dashboard',
      shift_type: 'Day Shift'
    };
    
    const result = await attendanceApi.checkIn(locationData);
    console.log('Check-in successful:', result);
    await loadDashboardData();
  };

  const handleClockOutWithoutLocation = async () => {
    const locationData = {
      location: 'Office - Main Building',
      device_id: 'web-dashboard'
    };
    
    const result = await attendanceApi.checkOut(locationData);
    console.log('Check-out successful:', result);
    await loadDashboardData();
  };

  const handleNavigateToAnnouncements = () => {
    window.location.href = '/announcements';
  };

  const handleNavigateToAttendance = () => {
    window.location.href = '/attendance';
  };

  const handleNavigateToRequests = () => {
    window.location.href = '/requests';
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'present':
        return 'text-green-600 bg-green-100';
      case 'absent':
        return 'text-red-600 bg-red-100';
      case 'late':
        return 'text-yellow-600 bg-yellow-100';
      default:
        return 'text-gray-600 bg-gray-100';
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
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center space-x-4 mb-2">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
              Admin Dashboard
            </h1>
            {user && (
              <div className="flex items-center space-x-2 px-3 py-1 bg-blue-50 rounded-full">
                <User className="w-4 h-4 text-blue-500" />
                <span className="text-sm font-medium text-blue-500">
                  Welcome, {user.first_name} {user.surname}
                </span>
              </div>
            )}
          </div>
          <p className="text-gray-500 dark:text-gray-400">{formatDate(currentTime)}</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={loadDashboardData}
            disabled={isLoading}
            className="flex items-center space-x-2 px-4 py-2 text-blue-500 hover:bg-blue-50 rounded-xl transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
          <a
            href="/profile"
            className="flex items-center space-x-2 px-4 py-2 bg-blue-500 text-white rounded-xl hover:bg-blue-600 transition-colors"
          >
            <User className="w-4 h-4" />
            <span>Profile</span>
          </a>
        </div>
      </div>

      {/* Clock In Card */}
      <div className="bg-gradient-to-br from-blue-500 to-amber-500 rounded-3xl p-8 text-white relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -mr-16 -mt-16" />
        <div className="relative z-10">
          <div className="flex items-center space-x-2 mb-6">
            <MapPin className="w-4 h-4 opacity-80" />
            <span className="text-sm opacity-80">Office - Main Building</span>
          </div>
          
          <div className="mb-6">
            <p className="text-sm opacity-80 mb-2">{getAttendanceStatus()}</p>
            <p className="text-5xl font-bold">{formatTime(currentTime)}</p>
          </div>
          
          <button 
            onClick={handleClockAction}
            disabled={isLoading}
            className="w-full bg-white text-blue-500 px-6 py-4 rounded-xl font-semibold hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {getButtonText()}
          </button>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-4">Quick Actions</h3>
          <div className="space-y-3">
            <button 
              onClick={handleNavigateToRequests}
              className="w-full btn-outline flex items-center justify-center space-x-2"
            >
              <AlertTriangle className="w-4 h-4" />
              <span>View Pending Requests</span>
            </button>
            <button 
              onClick={handleNavigateToAttendance}
              className="w-full btn-outline flex items-center justify-center space-x-2"
            >
              <Clock className="w-4 h-4" />
              <span>Attendance Report</span>
            </button>
            <button 
              onClick={handleNavigateToAnnouncements}
              className="w-full btn-outline flex items-center justify-center space-x-2"
            >
              <Bell className="w-4 h-4" />
              <span>Manage Announcements</span>
            </button>
          </div>
        </div>
      </div>

      {/* Enhanced Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          title="Staff Present"
          value={`${stats.presentToday}/${stats.totalStaff}`}
          change={12}
          changeType="increase"
          icon={<Users className="w-6 h-6" />}
          color="#3B82F6"
          miniChart={[{ value: 45 }, { value: 52 }, { value: 48 }, { value: 58 }, { value: 62 }, { value: 55 }, { value: 58 }]}
        />
        
        <StatsCard
          title="Late Arrivals"
          value={stats.lateToday}
          change={-8}
          changeType="decrease"
          icon={<Clock className="w-6 h-6" />}
          color="#F59E0B"
          miniChart={[{ value: 12 }, { value: 15 }, { value: 10 }, { value: 8 }, { value: 11 }, { value: 9 }, { value: 8 }]}
        />
        
        <StatsCard
          title="Absent"
          value={stats.absentToday}
          change={5}
          changeType="increase"
          icon={<UserX className="w-6 h-6" />}
          color="#EF4444"
          miniChart={[{ value: 3 }, { value: 5 }, { value: 4 }, { value: 6 }, { value: 5 }, { value: 7 }, { value: 5 }]}
        />
        
        <StatsCard
          title="Efficiency"
          value="94%"
          change={3}
          changeType="increase"
          icon={<TrendingUp className="w-6 h-6" />}
          color="#10B981"
          miniChart={[{ value: 88 }, { value: 90 }, { value: 92 }, { value: 91 }, { value: 93 }, { value: 94 }, { value: 94 }]}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Attendance Trend */}
        <LineChart
          title="Weekly Attendance Trend"
          subtitle="Staff presence over the last 7 days"
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
        
        {/* Department Distribution */}
        <PieChart
          title="Staff Distribution by Department"
          subtitle="Current staffing across departments"
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

      {/* Request Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <BarChart
          title="Pending Requests by Type"
          subtitle="Current pending requests"
          data={[
            { label: 'Leave', value: stats.pendingLeave, color: '#3B82F6' },
            { label: 'WFH', value: stats.pendingWFH, color: '#10B981' },
            { label: 'Shift Change', value: stats.pendingShiftChange, color: '#F59E0B' }
          ]}
          height={150}
        />
        
        <ProgressRing
          title="Attendance Rate"
          subtitle="Today's staff presence"
          value={stats.presentToday}
          maxValue={stats.totalStaff}
          size={150}
          color="#3B82F6"
        />
        
        <BarChart
          title="Weekly Activity"
          subtitle="Total activities this week"
          data={[
            { label: 'Check-ins', value: 156, color: '#10B981' },
            { label: 'Check-outs', value: 142, color: '#F59E0B' },
            { label: 'Overtime', value: 28, color: '#8B5CF6' }
          ]}
          height={150}
        />
      </div>

      {/* Activity Heatmap */}
      <ActivityHeatmap
        title="Staff Activity Heatmap"
        subtitle="Daily activity patterns over the last 4 weeks"
        data={[
          [5, 8, 12, 15, 18, 8, 3],    // Week 1
          [7, 10, 14, 16, 20, 12, 5],   // Week 2
          [6, 9, 11, 18, 22, 10, 4],    // Week 3
          [8, 12, 15, 20, 19, 11, 6],   // Week 4
        ]}
      />

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Announcements */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">Recent Announcements</h3>
            <span className="px-3 py-1 bg-blue-50 text-blue-500 rounded-full text-xs font-semibold">
              Latest 3
            </span>
          </div>

          {recentAnnouncements.length === 0 ? (
            <div className="text-center py-8">
              <Bell className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500 dark:text-gray-400">No announcements yet</p>
            </div>
          ) : (
            <div className="space-y-4 mb-6">
              {recentAnnouncements.map((announcement) => (
                <div key={announcement.id} className="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className={`p-2 rounded-lg ${getAnnouncementColor(announcement.type)}`}>
                    {getAnnouncementIcon(announcement.type)}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-gray-100 text-sm">{announcement.title}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{announcement.target_audience}</p>
                  </div>
                  <span className={`px-2 py-1 rounded text-xs font-semibold ${getAnnouncementColor(announcement.type)}`}>
                    {announcement.type}
                  </span>
                </div>
              ))}
            </div>
          )}

          <button onClick={handleNavigateToAnnouncements} className="btn-primary w-full">Manage Announcements</button>
        </div>

        {/* Team Attendance */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">My Team Attendance</h3>
            <button onClick={handleNavigateToAttendance} className="text-blue-500 hover:text-blue-600 text-sm font-medium flex items-center space-x-1">
              <span>Live View</span>
              <TrendingUp className="w-4 h-4" />
            </button>
          </div>

          {teamAttendance.length === 0 ? (
            <div className="text-center py-8">
              <Users className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500 dark:text-gray-400">No team attendance data available</p>
            </div>
          ) : (
            <div className="space-y-3">
              {teamAttendance.slice(0, 5).map((member) => (
                <div key={member.user_id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                      <span className="text-white text-sm font-semibold">
                        {member.name.split(' ').map(n => n[0]).join('')}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-gray-100 text-sm">{member.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{member.department}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`status-badge ${getStatusColor(member.status)}`}>
                      {member.status}
                    </span>
                    {member.check_in_time && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{member.check_in_time}</p>
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
