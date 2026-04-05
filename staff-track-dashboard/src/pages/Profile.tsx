import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../contexts/ToastContext';
import {
  User,
  Mail,
  Phone,
  MapPin,
  Calendar,
  Briefcase,
  Award,
  Edit,
  Camera,
  Shield,
  Download,
  Activity,
  Users,
  Target,
  TrendingUp
} from 'lucide-react';

interface ProfileData {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  employeeNumber: string;
  department: string;
  role: string;
  position: string;
  joinDate: string;
  avatar?: string;
  bio?: string;
  skills: string[];
  achievements: Array<{
    title: string;
    description: string;
    date: string;
    type: 'award' | 'certification' | 'milestone';
  }>;
  stats: {
    totalHours: number;
    attendanceRate: number;
    projectsCompleted: number;
    teamSize: number;
  };
}

const Profile: React.FC = () => {
  const { user } = useAuth();
  const { info } = useToast();
  const [profile, setProfile] = useState<ProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'activity' | 'achievements' | 'settings'>('overview');

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      setLoading(true);
      // Mock profile data - replace with actual API call
      const mockProfile: ProfileData = {
        id: user?.user_id || '1',
        firstName: user?.first_name || 'John',
        lastName: user?.surname || 'Doe',
        email: user?.email || 'john.doe@hospital.com',
        phone: '+1 234 567 8900',
        employeeNumber: 'EMP001',
        department: 'Emergency Department',
        role: 'Administrator',
        position: 'Senior Administrator',
        joinDate: '2020-03-15',
        bio: 'Dedicated healthcare administrator with over 5 years of experience in hospital management systems. Passionate about improving operational efficiency and staff satisfaction.',
        skills: ['Hospital Management', 'Team Leadership', 'Process Optimization', 'Healthcare Compliance', 'Emergency Response', 'Data Analysis'],
        achievements: [
          {
            title: 'Employee of the Year 2023',
            description: 'Recognized for outstanding leadership and innovation in hospital operations',
            date: '2023-12-15',
            type: 'award'
          },
          {
            title: 'Healthcare Management Certification',
            description: 'Advanced certification in healthcare administration and management',
            date: '2022-06-20',
            type: 'certification'
          },
          {
            title: '1000 Days Service Milestone',
            description: 'Celebrated 1000 days of dedicated service to the hospital',
            date: '2023-03-15',
            type: 'milestone'
          }
        ],
        stats: {
          totalHours: 8760,
          attendanceRate: 96.5,
          projectsCompleted: 12,
          teamSize: 25
        }
      };

      setProfile(mockProfile);
    } catch (err) {
      console.error('Error loading profile:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAvatarUpload = () => {
    info('Avatar upload functionality coming soon');
  };

  const handleExportProfile = () => {
    info('Exporting profile data...');
    // TODO: Implement profile export
  };

  const getAchievementIcon = (type: string) => {
    switch (type) {
      case 'award':
        return <Award className="w-5 h-5" />;
      case 'certification':
        return <Shield className="w-5 h-5" />;
      case 'milestone':
        return <Target className="w-5 h-5" />;
      default:
        return <Award className="w-5 h-5" />;
    }
  };

  const getAchievementColor = (type: string) => {
    switch (type) {
      case 'award':
        return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-400';
      case 'certification':
        return 'text-blue-600 bg-blue-100 dark:bg-blue-900 dark:text-blue-400';
      case 'milestone':
        return 'text-purple-600 bg-purple-100 dark:bg-purple-900 dark:text-purple-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-48 mb-2"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-64"></div>
        </div>
        <div className="card">
          <div className="animate-pulse space-y-4">
            <div className="flex items-center space-x-4">
              <div className="w-20 h-20 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
                <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="card text-center py-12">
        <User className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <p className="text-gray-500">Profile not found</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
            My Profile
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Manage your personal information and preferences
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <button
            onClick={handleExportProfile}
            className="btn-outline flex items-center space-x-2"
          >
            <Download className="w-4 h-4" />
            <span>Export</span>
          </button>
          <button
            onClick={() => setIsEditing(!isEditing)}
            className={`btn-outline flex items-center space-x-2 ${isEditing ? 'bg-sky-blue text-white' : ''}`}
          >
            <Edit className="w-4 h-4" />
            <span>{isEditing ? 'Save' : 'Edit'}</span>
          </button>
        </div>
      </div>

      {/* Profile Header Card */}
      <div className="card">
        <div className="flex flex-col md:flex-row items-center md:items-start space-y-4 md:space-y-0 md:space-x-6">
          {/* Avatar */}
          <div className="relative">
            <div className="w-24 h-24 bg-sky-blue rounded-full flex items-center justify-center">
              <span className="text-white text-2xl font-bold">
                {profile.firstName.charAt(0)}{profile.lastName.charAt(0)}
              </span>
            </div>
            <button
              onClick={handleAvatarUpload}
              className="absolute bottom-0 right-0 w-8 h-8 bg-white dark:bg-gray-800 rounded-full flex items-center justify-center shadow-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              <Camera className="w-4 h-4 text-gray-600 dark:text-gray-400" />
            </button>
          </div>
          
          {/* Basic Info */}
          <div className="flex-1 text-center md:text-left">
            <h2 className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
              {profile.firstName} {profile.lastName}
            </h2>
            <p className="text-lg text-text-grey dark:text-text-grey-dark mb-2">
              {profile.position}
            </p>
            <div className="flex flex-wrap justify-center md:justify-start gap-4 text-sm">
              <div className="flex items-center space-x-1 text-text-grey dark:text-text-grey-dark">
                <Briefcase className="w-4 h-4" />
                <span>{profile.department}</span>
              </div>
              <div className="flex items-center space-x-1 text-text-grey dark:text-text-grey-dark">
                <Users className="w-4 h-4" />
                <span>{profile.role}</span>
              </div>
              <div className="flex items-center space-x-1 text-text-grey dark:text-text-grey-dark">
                <Calendar className="w-4 h-4" />
                <span>Joined {new Date(profile.joinDate).toLocaleDateString()}</span>
              </div>
            </div>
            
            {profile.bio && (
              <p className="text-text-dark dark:text-text-dark-light mt-4 max-w-2xl">
                {profile.bio}
              </p>
            )}
          </div>
          
          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-4 md:gap-6">
            <div className="text-center">
              <p className="text-2xl font-bold text-sky-blue">{profile.stats.attendanceRate}%</p>
              <p className="text-xs text-text-grey dark:text-text-grey-dark">Attendance Rate</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-green-600">{profile.stats.projectsCompleted}</p>
              <p className="text-xs text-text-grey dark:text-text-grey-dark">Projects</p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="flex space-x-8">
          {(['overview', 'activity', 'achievements', 'settings'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab
                  ? 'border-sky-blue text-sky-blue'
                  : 'border-transparent text-text-grey dark:text-text-grey-dark hover:text-text-dark dark:hover:text-text-dark-light'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="space-y-6">
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Contact Information */}
            <div className="card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Contact Information
              </h3>
              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <Mail className="w-5 h-5 text-text-grey dark:text-text-grey-dark" />
                  <div>
                    <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">Email</p>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark">{profile.email}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-3">
                  <Phone className="w-5 h-5 text-text-grey dark:text-text-grey-dark" />
                  <div>
                    <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">Phone</p>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark">{profile.phone}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-3">
                  <MapPin className="w-5 h-5 text-text-grey dark:text-text-grey-dark" />
                  <div>
                    <p className="text-sm font-medium text-text-dark dark:text-text-dark-light">Location</p>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark">Main Building, Floor 3</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Employment Details */}
            <div className="card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Employment Details
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Employee Number</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.employeeNumber}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Department</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.department}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Position</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">{profile.position}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Join Date</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
                    {new Date(profile.joinDate).toLocaleDateString()}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Years of Service</span>
                  <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
                    {Math.floor((Date.now() - new Date(profile.joinDate).getTime()) / (1000 * 60 * 60 * 24 * 365))}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'activity' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Recent Activity
              </h3>
              <div className="space-y-4">
                <div className="flex items-start space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className="w-8 h-8 bg-sky-blue rounded-full flex items-center justify-center flex-shrink-0">
                    <Activity className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-text-dark dark:text-text-dark-light text-sm">
                      Updated team attendance records
                    </p>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">2 hours ago</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center flex-shrink-0">
                    <TrendingUp className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-text-dark dark:text-text-dark-light text-sm">
                      Completed performance review
                    </p>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">1 day ago</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className="w-8 h-8 bg-purple-600 rounded-full flex items-center justify-center flex-shrink-0">
                    <Users className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-text-dark dark:text-text-dark-light text-sm">
                      Added new team members
                    </p>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark">3 days ago</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Performance Stats
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Total Hours</span>
                  <span className="text-lg font-bold text-text-dark dark:text-text-dark-light">
                    {profile.stats.totalHours}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Team Size</span>
                  <span className="text-lg font-bold text-text-dark dark:text-text-dark-light">
                    {profile.stats.teamSize}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-text-grey dark:text-text-grey-dark">Projects</span>
                  <span className="text-lg font-bold text-text-dark dark:text-text-dark-light">
                    {profile.stats.projectsCompleted}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'achievements' && (
          <div className="card">
            <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-6">
              Achievements & Recognition
            </h3>
            <div className="space-y-4">
              {profile.achievements.map((achievement, index) => (
                <div key={index} className="flex items-start space-x-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
                  <div className={`p-2 rounded-lg ${getAchievementColor(achievement.type)}`}>
                    {getAchievementIcon(achievement.type)}
                  </div>
                  <div className="flex-1">
                    <h4 className="font-medium text-text-dark dark:text-text-dark-light">
                      {achievement.title}
                    </h4>
                    <p className="text-sm text-text-grey dark:text-text-grey-dark mt-1">
                      {achievement.description}
                    </p>
                    <p className="text-xs text-text-grey dark:text-text-grey-dark mt-2">
                      {new Date(achievement.date).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'settings' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Privacy Settings
              </h3>
              <div className="space-y-4">
                <label className="flex items-center justify-between">
                  <span className="text-sm text-text-dark dark:text-text-dark-light">Profile Visibility</span>
                  <select className="input-field w-auto">
                    <option>Public</option>
                    <option>Team Only</option>
                    <option>Private</option>
                  </select>
                </label>
                <label className="flex items-center justify-between">
                  <span className="text-sm text-text-dark dark:text-text-dark-light">Show Activity Status</span>
                  <input type="checkbox" defaultChecked className="toggle" />
                </label>
              </div>
            </div>

            <div className="card">
              <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light mb-4">
                Notification Preferences
              </h3>
              <div className="space-y-4">
                <label className="flex items-center justify-between">
                  <span className="text-sm text-text-dark dark:text-text-dark-light">Email Notifications</span>
                  <input type="checkbox" defaultChecked className="toggle" />
                </label>
                <label className="flex items-center justify-between">
                  <span className="text-sm text-text-dark dark:text-text-dark-light">Achievement Alerts</span>
                  <input type="checkbox" defaultChecked className="toggle" />
                </label>
                <label className="flex items-center justify-between">
                  <span className="text-sm text-text-dark dark:text-text-dark-light">Performance Reviews</span>
                  <input type="checkbox" defaultChecked className="toggle" />
                </label>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Profile;
