import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import DataTable from '../components/DataTable';
import CreateAnnouncementModal from '../components/CreateAnnouncementModal';
import type { Column, Action } from '../components/DataTable';
import { announcementsApi, notificationsApi } from '../services/api';
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
  Filter,
  X,
  Mail
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
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [selectedAnnouncement, setSelectedAnnouncement] = useState<Announcement | null>(null);
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

  const handlePublish = async (announcement: Announcement) => {
    try {
      await announcementsApi.updateAnnouncement(announcement.id, { is_active: true });
      success(`"${announcement.title}" published successfully`);
      loadAnnouncements();
    } catch (err: any) {
      error('Failed to publish announcement');
    }
  };

  const handleArchive = async (announcement: Announcement) => {
    try {
      await announcementsApi.updateAnnouncement(announcement.id, { is_active: false });
      info(`"${announcement.title}" archived`);
      loadAnnouncements();
    } catch (err: any) {
      error('Failed to archive announcement');
    }
  };

  const handleEdit = (announcement: Announcement) => {
    setSelectedAnnouncement(announcement);
    setIsEditModalOpen(true);
  };

  const handleView = (announcement: Announcement) => {
    setSelectedAnnouncement(announcement);
    setIsViewModalOpen(true);
  };

  const handleSendNotification = async (announcement: Announcement) => {
    try {
      // Send push notification to target users
      const notificationData = {
        title: announcement.title,
        body: announcement.message || announcement.content || '',
        notification_type: announcement.type || 'general',
        target: 'all' as const,
        data: {
          announcement_id: announcement.id
        }
      };

      // If there are specific target departments, use advanced broadcast
      if (announcement.target_departments && announcement.target_departments.length > 0) {
        await notificationsApi.sendAdvancedBroadcast({
          title: announcement.title,
          body: announcement.message || announcement.content || '',
          notification_type: announcement.type || 'general',
          target_audience: 'department',
          department_filter: announcement.target_departments.join(','),
          data: { announcement_id: announcement.id }
        });
      } else {
        await notificationsApi.sendBroadcast(notificationData);
      }

      success(`Notification sent for "${announcement.title}"`);
    } catch (err: any) {
      error(`Failed to send notification: ${err.response?.data?.message || err.message}`);
    }
  };

  const handleDelete = async (announcement: Announcement) => {
    if (confirm(`Are you sure you want to delete "${announcement.title}"?`)) {
      try {
        await announcementsApi.deleteAnnouncement(announcement.id);
        success(`"${announcement.title}" deleted successfully`);
        loadAnnouncements();
      } catch (err: any) {
        error('Failed to delete announcement');
      }
    }
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
        },
        {
          label: 'Delete',
          icon: <Trash2 className="w-4 h-4" />,
          onClick: handleDelete,
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
          <button 
            className="btn-primary flex items-center space-x-2"
            onClick={() => setIsCreateModalOpen(true)}
          >
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

       {/* Create Announcement Modal */}
       <CreateAnnouncementModal
         isOpen={isCreateModalOpen}
         onClose={() => setIsCreateModalOpen(false)}
         onSuccess={() => {
           setIsCreateModalOpen(false);
           loadAnnouncements();
         }}
       />

       {/* Edit Announcement Modal */}
       <CreateAnnouncementModal
         isOpen={isEditModalOpen}
         announcement={selectedAnnouncement}
         onClose={() => {
           setIsEditModalOpen(false);
           setSelectedAnnouncement(null);
         }}
         onSuccess={() => {
           setIsEditModalOpen(false);
           setSelectedAnnouncement(null);
           loadAnnouncements();
           success('Announcement updated successfully');
         }}
       />

       {/* View Announcement Modal */}
       {isViewModalOpen && selectedAnnouncement && (
         <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
           <div className="bg-white dark:bg-gray-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
             <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
               <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                 View Announcement
               </h2>
               <button
                 onClick={() => {
                   setIsViewModalOpen(false);
                   setSelectedAnnouncement(null);
                 }}
                 className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
               >
                 <X className="w-5 h-5 text-gray-500" />
               </button>
             </div>
             <div className="p-6 space-y-4">
               <div>
                 <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                   {selectedAnnouncement.title}
                 </h3>
                 <div className="flex items-center space-x-2 mb-4">
                   <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(selectedAnnouncement.priority || 'low')}`}>
                     {(selectedAnnouncement.priority || 'low').toUpperCase()}
                   </span>
                   <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(selectedAnnouncement.status || 'draft')}`}>
                     {(selectedAnnouncement.status || 'draft').toUpperCase()}
                   </span>
                   <span className="text-sm text-gray-500 dark:text-gray-400">
                     {selectedAnnouncement.type}
                   </span>
                 </div>
               </div>
               <div className="prose dark:prose-invert max-w-none">
                 <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
                   {selectedAnnouncement.message || selectedAnnouncement.content || 'No content available'}
                 </p>
               </div>
               {selectedAnnouncement.target_departments && selectedAnnouncement.target_departments.length > 0 && (
                 <div>
                   <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
                     Target Departments:
                   </h4>
                   <div className="flex flex-wrap gap-2">
                     {selectedAnnouncement.target_departments.map((dept: string, idx: number) => (
                       <span key={idx} className="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 rounded-full text-xs">
                         {dept}
                       </span>
                     ))}
                   </div>
                 </div>
               )}
               <div className="grid grid-cols-2 gap-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                 <div>
                   <p className="text-sm text-gray-500 dark:text-gray-400">Published Date</p>
                   <p className="text-sm font-medium text-gray-900 dark:text-white">
                     {selectedAnnouncement.published_at
                       ? formatDate(selectedAnnouncement.published_at)
                       : 'Not published'}
                   </p>
                 </div>
                 <div>
                   <p className="text-sm text-gray-500 dark:text-gray-400">View Count</p>
                   <p className="text-sm font-medium text-gray-900 dark:text-white">
                     {selectedAnnouncement.view_count || 0} views
                   </p>
                 </div>
                 {selectedAnnouncement.expires_at && (
                   <div className="col-span-2">
                     <p className="text-sm text-gray-500 dark:text-gray-400">Expires At</p>
                     <p className="text-sm font-medium text-gray-900 dark:text-white">
                       {formatDate(selectedAnnouncement.expires_at)}
                     </p>
                   </div>
                 )}
               </div>
             </div>
             <div className="flex justify-end space-x-3 p-6 border-t border-gray-200 dark:border-gray-700">
               <button
                 onClick={() => {
                   setIsViewModalOpen(false);
                   setSelectedAnnouncement(null);
                 }}
                 className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
               >
                 Close
               </button>
               <button
                 onClick={() => {
                   setIsViewModalOpen(false);
                   handleEdit(selectedAnnouncement);
                 }}
                 className="px-4 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg transition-colors flex items-center space-x-2"
               >
                 <Edit className="w-4 h-4" />
                 <span>Edit</span>
               </button>
             </div>
           </div>
         </div>
       )}
     </div>
   );
 };

export default Announcements;
