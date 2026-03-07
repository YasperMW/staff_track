import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import DataTable from '../components/DataTable';
import type { Column, Action } from '../components/DataTable';
import { announcementsApi } from '../services/api';
import { 
  Megaphone, 
  Calendar, 
  Eye, 
  Edit, 
  Trash2, 
  Plus,
  Bell,
  AlertTriangle,
  Info,
  CheckCircle,
  Send,
  Filter
} from 'lucide-react';

interface Announcement {
  id: string;
  title: string;
  message?: string;
  content?: string;
  type: 'general' | 'urgent' | 'policy' | 'event' | 'maintenance' | 'holiday';
  priority?: 'low' | 'medium' | 'high' | 'critical';
  targetAudience?: 'all' | 'staff' | 'management' | 'specific_departments';
  target_departments?: string[];
  authorId?: string;
  authorName?: string;
  status?: 'draft' | 'published' | 'scheduled' | 'archived';
  published_at?: string;
  scheduled_at?: string;
  expires_at?: string;
  view_count?: number;
  created_at?: string;
  updated_at?: string;
}

const Announcements: React.FC = () => {
  const { success, error, info } = useToast();
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'published' | 'draft' | 'scheduled'>('all');
  const [stats, setStats] = useState({
    total: 0,
    published: 0,
    draft: 0,
    scheduled: 0,
    totalViews: 0,
    urgent: 0
  });

  useEffect(() => {
    loadAnnouncements();
  }, [selectedFilter]);

  const loadAnnouncements = async () => {
    try {
      setLoading(true);
      
      // Get announcements from API
      const response = await announcementsApi.getAnnouncements();
      console.log('Announcements:', response);
      
      // Process announcements data
      const announcementsData: Announcement[] = Array.isArray(response) ? response : [];
      
      // Filter announcements based on selected filter
      const filteredAnnouncements = selectedFilter === 'all' 
        ? announcementsData 
        : announcementsData.filter((ann: Announcement) => ann.status === selectedFilter);
      
      setAnnouncements(filteredAnnouncements);
      
      // Calculate stats
      const total = announcementsData.length;
      const published = announcementsData.filter((a: Announcement) => a.status === 'published').length;
      const draft = announcementsData.filter((a: Announcement) => a.status === 'draft').length;
      const scheduled = announcementsData.filter((a: Announcement) => a.status === 'scheduled').length;
      const totalViews = announcementsData.reduce((sum: number, a: Announcement) => sum + (a.view_count || 0), 0);
      const urgent = announcementsData.filter((a: Announcement) => a.priority === 'critical' || a.priority === 'high').length;
      
      setStats({
        total,
        published,
        draft,
        scheduled,
        totalViews,
        urgent
      });
      
    } catch (err: any) {
      console.error('Error loading announcements:', err);
      error('Failed to load announcements data');
    } finally {
      setLoading(false);
    }
  };

  const handlePublish = (announcement: Announcement) => {
    success(`"${announcement.title}" published successfully`);
    loadAnnouncements();
  };

  const handleArchive = (announcement: Announcement) => {
    info(`"${announcement.title}" archived`);
    loadAnnouncements();
  };

  const handleEdit = (announcement: Announcement) => {
    info(`Editing "${announcement.title}"`);
  };

  const handleView = (announcement: Announcement) => {
    info(`Viewing "${announcement.title}"`);
  };

  const handleSendNotification = (announcement: Announcement) => {
    success(`Notification sent for "${announcement.title}"`);
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'urgent':
        return <AlertTriangle className="w-5 h-5" />;
      case 'policy':
        return <Info className="w-5 h-5" />;
      case 'event':
        return <Calendar className="w-5 h-5" />;
      case 'maintenance':
        return <AlertTriangle className="w-5 h-5" />;
      default:
        return <Megaphone className="w-5 h-5" />;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'published':
        return <CheckCircle className="w-5 h-5" />;
      case 'draft':
        return <Edit className="w-5 h-5" />;
      case 'scheduled':
        return <Calendar className="w-5 h-5" />;
      default:
        return <Megaphone className="w-5 h-5" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'critical':
        return 'text-red-600 bg-red-100 dark:bg-red-900 dark:text-red-400';
      case 'high':
        return 'text-orange-600 bg-orange-100 dark:bg-orange-900 dark:text-orange-400';
      case 'medium':
        return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'published':
        return 'text-green-600 bg-green-100 dark:bg-green-900 dark:text-green-400';
      case 'draft':
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
      case 'scheduled':
        return 'text-blue-600 bg-blue-100 dark:bg-blue-900 dark:text-blue-400';
      default:
        return 'text-gray-600 bg-gray-100 dark:bg-gray-900 dark:text-gray-400';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const columns: Column<Announcement>[] = [
    {
      key: 'title',
      label: 'Announcement',
      sortable: true,
      filterable: true,
      render: (_, row) => (
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <div className={`p-1 rounded-full ${getPriorityColor(row.priority || 'low')}`}>
              {getTypeIcon(row.type || 'general')}
            </div>
            <h4 className="font-medium text-text-dark dark:text-text-dark-light">
              {row.title}
            </h4>
          </div>
          <p className="text-sm text-text-grey dark:text-text-grey-dark line-clamp-2">
            {row.message || row.content || 'No content available'}
          </p>
        </div>
      )
    },
    {
      key: 'type',
      label: 'Type',
      sortable: true,
      filterable: true,
      render: (value) => (
        <span className="text-sm font-medium capitalize text-text-dark dark:text-text-dark-light">
          {value}
        </span>
      )
    },
    {
      key: 'priority',
      label: 'Priority',
      sortable: true,
      filterable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <div className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(value || 'low')}`}>
            {(value || 'low').toUpperCase()}
          </div>
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
          <div className={`p-1 rounded-full ${getStatusColor(value || 'draft')}`}>
            {getStatusIcon(value || 'draft')}
          </div>
          <span className="text-sm font-medium capitalize">
            {value || 'draft'}
          </span>
        </div>
      )
    },
    {
      key: 'view_count',
      label: 'Views',
      sortable: true,
      render: (value) => (
        <div className="flex items-center space-x-2">
          <Eye className="w-4 h-4 text-text-grey" />
          <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
            {value}
          </span>
        </div>
      )
    },
    {
      key: 'published_at',
      label: 'Published',
      sortable: true,
      render: (_, row) => {
        const date = row.published_at || row.scheduled_at || row.created_at || new Date().toISOString();
        return (
          <span className="text-sm text-text-grey dark:text-text-grey-dark">
            {formatDate(date)}
          </span>
        );
      }
    }
  ];

  const getActions = (announcement: Announcement): Action<Announcement>[] => {
    const baseActions: Action<Announcement>[] = [
      {
        label: 'View',
        icon: <Eye className="w-4 h-4" />,
        onClick: handleView,
        variant: 'primary'
      },
      {
        label: 'Edit',
        icon: <Edit className="w-4 h-4" />,
        onClick: handleEdit,
        variant: 'secondary'
      }
    ];

    if (announcement.status === 'draft') {
      baseActions.push(
        {
          label: 'Publish',
          icon: <Send className="w-4 h-4" />,
          onClick: handlePublish,
          variant: 'secondary'
        }
      );
    }

    if (announcement.status === 'published') {
      baseActions.push(
        {
          label: 'Send Notification',
          icon: <Bell className="w-4 h-4" />,
          onClick: handleSendNotification,
          variant: 'secondary'
        },
        {
          label: 'Archive',
          icon: <Trash2 className="w-4 h-4" />,
          onClick: handleArchive,
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
            Announcements Management
          </h1>
          <p className="text-text-grey dark:text-text-grey-dark">
            Create and manage hospital announcements and communications
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
              <option value="all">All Announcements</option>
              <option value="published">Published</option>
              <option value="draft">Draft</option>
              <option value="scheduled">Scheduled</option>
            </select>
          </div>
          <button className="btn-primary flex items-center space-x-2">
            <Plus className="w-4 h-4" />
            <span>New Announcement</span>
          </button>
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
              <Megaphone className="w-6 h-6 text-sky-blue" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Published</p>
              <p className="text-2xl font-bold text-green-600">
                {stats.published}
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Draft</p>
              <p className="text-2xl font-bold text-gray-600">
                {stats.draft}
              </p>
            </div>
            <div className="w-12 h-12 bg-gray-100 dark:bg-gray-900 rounded-xl flex items-center justify-center">
              <Edit className="w-6 h-6 text-gray-600 dark:text-gray-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Scheduled</p>
              <p className="text-2xl font-bold text-blue-600">
                {stats.scheduled}
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
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Total Views</p>
              <p className="text-2xl font-bold text-purple-600">
                {stats.totalViews}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-xl flex items-center justify-center">
              <Eye className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-text-grey dark:text-text-grey-dark">Urgent</p>
              <p className="text-2xl font-bold text-red-600">
                {stats.urgent}
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-xl flex items-center justify-center">
              <AlertTriangle className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Announcements Table */}
      <DataTable
        data={announcements}
        columns={columns}
        actions={getActions}
        loading={loading}
        emptyMessage="No announcements found matching the selected filter."
      />
    </div>
  );
};

export default Announcements;
