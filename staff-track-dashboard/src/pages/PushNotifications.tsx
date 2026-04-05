import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { notificationsApi, departmentsApi, rolesApi } from '../services/api';
import type { BroadcastNotificationRequest } from '../services/api';
import {
  Send,
  Bell,
  AlertTriangle,
  Wrench,
  Info,
  Smartphone,
  Users,
  Building,
  Shield,
  Loader2,
  CheckCircle,
  XCircle,
  History,
} from 'lucide-react';

interface NotificationType {
  value: string;
  label: string;
  description: string;
}

interface Target {
  value: string;
  label: string;
}

interface SentNotification {
  id: string;
  title: string;
  body: string;
  type: string;
  target: string;
  targetValue?: string;
  sentAt: string;
  targetUsers: number;
  tokensTargeted: number;
  pushSent: number;
  pushFailed: number;
  inAppCreated: number;
  success: boolean;
  errorMessage?: string;
}

const PushNotifications: React.FC = () => {
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [notificationType, setNotificationType] = useState('general');
  const [target, setTarget] = useState('all');
  const [targetValue, setTargetValue] = useState('');

  // Data from API
  const [notificationTypes, setNotificationTypes] = useState<NotificationType[]>([]);
  const [targets, setTargets] = useState<Target[]>([]);
  const [departments, setDepartments] = useState<string[]>([]);
  const [roles, setRoles] = useState<string[]>([]);

  // History
  const [sentHistory, setSentHistory] = useState<SentNotification[]>([]);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const [typesRes, deptsRes, rolesRes] = await Promise.all([
        notificationsApi.getBroadcastTypes(),
        departmentsApi.getAllDepartments(),
        rolesApi.getAllRoles(),
      ]);

      setNotificationTypes(typesRes.notification_types || []);
      setTargets(typesRes.targets || []);
      setDepartments(deptsRes.departments?.map((d: any) => d.name) || []);
      setRoles(rolesRes.roles?.map((r: any) => r.name) || []);
    } catch (err) {
      console.error('Failed to load data:', err);
      setError('Failed to load notification settings');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSuccess(null);
    setError(null);

    if (!title.trim() || !body.trim()) {
      setError('Please fill in both title and message');
      return;
    }

    if (target !== 'all' && !targetValue) {
      setError('Please select a specific department or role');
      return;
    }

    setIsSending(true);
    try {
      const request: BroadcastNotificationRequest = {
        title: title.trim(),
        body: body.trim(),
        notification_type: notificationType,
        target: target as 'all' | 'department' | 'role',
        target_value: target !== 'all' ? targetValue : undefined,
      };

      const result = await notificationsApi.sendBroadcast(request);

      // Backend returns data directly, not wrapped in success/response format
      const targetUsers = result.target_users || 0;
      const tokensTargeted = result.tokens_targeted || 0;
      const pushSent = result.push_sent || 0;
      const pushFailed = result.push_failed || 0;
      const inAppCreated = result.in_app_created || 0;
      
      setSuccess(
        `Notification sent successfully! ` +
        `${targetUsers} users targeted, ${pushSent} push notifications delivered, ${inAppCreated} in-app notifications created` +
        (pushFailed > 0 ? ` (${pushFailed} failed)` : '')
      );
      
      // Add to history
      const newNotification: SentNotification = {
        id: Date.now().toString(),
        title: title.trim(),
        body: body.trim(),
        type: notificationType,
        target: target,
        targetValue: target !== 'all' ? targetValue : undefined,
        sentAt: new Date().toISOString(),
        targetUsers,
        tokensTargeted,
        pushSent,
        pushFailed,
        inAppCreated,
        success: true,
      };
      setSentHistory(prev => [newNotification, ...prev].slice(0, 10));
      // Clear form
      setTitle('');
      setBody('');
    } catch (err: any) {
      console.error('Failed to send notification:', err);
      const errorMessage = err.response?.data?.detail || err.message || 'Failed to send notification';
      setError(errorMessage);
      
      // Add failed attempt to history
      const newNotification: SentNotification = {
        id: Date.now().toString(),
        title: title.trim(),
        body: body.trim(),
        type: notificationType,
        target: target,
        targetValue: target !== 'all' ? targetValue : undefined,
        sentAt: new Date().toISOString(),
        targetUsers: 0,
        tokensTargeted: 0,
        pushSent: 0,
        pushFailed: 0,
        inAppCreated: 0,
        success: false,
        errorMessage: errorMessage,
      };
      setSentHistory(prev => [newNotification, ...prev].slice(0, 10));
    } finally {
      setIsSending(false);
    }
  };

  const getNotificationTypeIcon = (type: string) => {
    switch (type) {
      case 'app_update':
        return <Smartphone className="w-5 h-5 text-blue-500" />;
      case 'maintenance':
        return <Wrench className="w-5 h-5 text-yellow-500" />;
      case 'incident':
        return <AlertTriangle className="w-5 h-5 text-red-500" />;
      default:
        return <Info className="w-5 h-5 text-gray-500" />;
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'app_update':
        return 'bg-blue-100 text-blue-700 border-blue-200';
      case 'maintenance':
        return 'bg-yellow-100 text-yellow-700 border-yellow-200';
      case 'incident':
        return 'bg-red-100 text-red-700 border-red-200';
      default:
        return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Push Notifications</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">
            Send broadcast notifications to all staff or specific groups
          </p>
        </div>
        <div className="flex items-center space-x-2 text-sm text-gray-500">
          <Bell className="w-4 h-4" />
          <span>Sent as: {user?.first_name} {user?.surname}</span>
        </div>
      </div>

      {/* Success/Error Messages */}
      {success && (
        <div className="flex items-center space-x-2 p-4 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 rounded-lg border border-green-200 dark:border-green-800">
          <CheckCircle className="w-5 h-5" />
          <span>{success}</span>
        </div>
      )}

      {error && (
        <div className="flex items-center space-x-2 p-4 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 rounded-lg border border-red-200 dark:border-red-800">
          <XCircle className="w-5 h-5" />
          <span>{error}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Send Notification Form */}
        <div className="lg:col-span-2">
          <div className="card p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-6">
              Compose Notification
            </h2>

            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Notification Type */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Notification Type
                </label>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {notificationTypes.map((type) => (
                    <button
                      key={type.value}
                      type="button"
                      onClick={() => setNotificationType(type.value)}
                      className={`flex flex-col items-center p-4 rounded-lg border-2 transition-all ${
                        notificationType === type.value
                          ? getTypeColor(type.value)
                          : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                      }`}
                    >
                      {getNotificationTypeIcon(type.value)}
                      <span className="mt-2 text-sm font-medium">{type.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Target Audience */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Target Audience
                </label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <select
                      value={target}
                      onChange={(e) => {
                        setTarget(e.target.value);
                        setTargetValue('');
                      }}
                      className="w-full px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      {targets.map((t) => (
                        <option key={t.value} value={t.value}>{t.label}</option>
                      ))}
                    </select>
                  </div>
                  {target !== 'all' && (
                    <div>
                      <select
                        value={targetValue}
                        onChange={(e) => setTargetValue(e.target.value)}
                        className="w-full px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      >
                        <option value="">Select {target === 'department' ? 'Department' : 'Role'}</option>
                        {(target === 'department' ? departments : roles).map((item) => (
                          <option key={item} value={item}>{item}</option>
                        ))}
                      </select>
                    </div>
                  )}
                </div>
                {target !== 'all' && (
                  <div className="mt-2 flex items-center space-x-2 text-sm text-gray-500">
                    {target === 'department' ? <Building className="w-4 h-4" /> : <Shield className="w-4 h-4" />}
                    <span>
                      {target === 'department'
                        ? 'Only users in the selected department will receive this notification'
                        : 'Only users with the selected role will receive this notification'}
                    </span>
                  </div>
                )}
              </div>

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Title
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter notification title"
                  className="w-full px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  maxLength={100}
                />
                <p className="mt-1 text-xs text-gray-500">{title.length}/100 characters</p>
              </div>

              {/* Message */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Message
                </label>
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Enter notification message"
                  rows={4}
                  className="w-full px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                  maxLength={500}
                />
                <p className="mt-1 text-xs text-gray-500">{body.length}/500 characters</p>
              </div>

              {/* Preview */}
              <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-lg border border-gray-200 dark:border-gray-700">
                <p className="text-xs text-gray-500 mb-2">Preview</p>
                <div className="flex items-start space-x-3">
                  <div className="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Bell className="w-5 h-5 text-white" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 dark:text-gray-100 truncate">
                      {title || 'Notification Title'}
                    </p>
                    <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                      {body || 'Notification message will appear here...'}
                    </p>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={isSending || !title.trim() || !body.trim()}
                className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSending ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>Sending...</span>
                  </>
                ) : (
                  <>
                    <Send className="w-5 h-5" />
                    <span>Send Notification</span>
                  </>
                )}
              </button>
            </form>
          </div>
        </div>

        {/* Info & History Sidebar */}
        <div className="space-y-6">
          {/* Info Card */}
          <div className="card p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
              Notification Types
            </h3>
            <div className="space-y-4">
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Smartphone className="w-4 h-4 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-gray-100">App Update</p>
                  <p className="text-sm text-gray-500">Notify users about new app features</p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Wrench className="w-4 h-4 text-yellow-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-gray-100">Maintenance</p>
                  <p className="text-sm text-gray-500">Scheduled or emergency maintenance</p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 bg-red-100 dark:bg-red-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
                  <AlertTriangle className="w-4 h-4 text-red-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-gray-100">Incident Report</p>
                  <p className="text-sm text-gray-500">Important safety or security alerts</p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="w-8 h-8 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Info className="w-4 h-4 text-gray-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900 dark:text-gray-100">General</p>
                  <p className="text-sm text-gray-500">General information for all users</p>
                </div>
              </div>
            </div>
          </div>

          {/* Recent Sent */}
          <div className="card p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Recent Sent
              </h3>
              <History className="w-4 h-4 text-gray-400" />
            </div>
            {sentHistory.length === 0 ? (
              <div className="text-center py-6 text-gray-500">
                <Bell className="w-8 h-8 mx-auto mb-2 opacity-50" />
                <p className="text-sm">No notifications sent yet</p>
              </div>
            ) : (
              <div className="space-y-3">
                {sentHistory.map((item) => (
                  <div
                    key={item.id}
                    className={`p-4 rounded-lg border ${
                      item.success 
                        ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800' 
                        : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
                    }`}
                  >
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-2">
                          <p className="font-medium text-gray-900 dark:text-gray-100 text-sm truncate">
                            {item.title}
                          </p>
                          {item.success ? (
                            <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                          ) : (
                            <XCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                          )}
                        </div>
                        <p className="text-xs text-gray-500 truncate mt-1">{item.body}</p>
                      </div>
                      <span className={`ml-2 px-2 py-1 text-xs rounded-full ${getTypeColor(item.type)}`}>
                        {item.type.replace('_', ' ')}
                      </span>
                    </div>
                    
                    {/* Error Message */}
                    {item.errorMessage && (
                      <div className="mb-2 p-2 bg-red-100 dark:bg-red-900/30 rounded border border-red-200 dark:border-red-800">
                        <p className="text-xs text-red-700 dark:text-red-400">{item.errorMessage}</p>
                      </div>
                    )}
                    
                    {/* Target Information */}
                    <div className="mb-2 text-xs text-gray-500">
                      <div className="flex items-center space-x-2 mb-1">
                        <span className="font-medium">Target:</span>
                        <span>{item.target === 'all' ? 'All Users' : item.targetValue}</span>
                        {item.target !== 'all' && (
                          <span className="px-1 py-0.5 bg-gray-100 dark:bg-gray-700 rounded text-xs">
                            {item.target}
                          </span>
                        )}
                      </div>
                    </div>
                    
                    {/* Delivery Statistics */}
                    {item.success && item.targetUsers > 0 ? (
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        <div className="flex items-center space-x-1">
                          <Users className="w-3 h-3 text-blue-500" />
                          <span className="text-gray-600 dark:text-gray-400">Users:</span>
                          <span className="font-medium text-gray-900 dark:text-gray-100">{item.targetUsers}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Smartphone className="w-3 h-3 text-green-500" />
                          <span className="text-gray-600 dark:text-gray-400">Push Sent:</span>
                          <span className="font-medium text-green-700 dark:text-green-400">{item.pushSent}</span>
                        </div>
                        {item.pushFailed > 0 && (
                          <div className="flex items-center space-x-1">
                            <XCircle className="w-3 h-3 text-red-500" />
                            <span className="text-gray-600 dark:text-gray-400">Failed:</span>
                            <span className="font-medium text-red-700 dark:text-red-400">{item.pushFailed}</span>
                          </div>
                        )}
                        <div className="flex items-center space-x-1">
                          <Bell className="w-3 h-3 text-purple-500" />
                          <span className="text-gray-600 dark:text-gray-400">In-App:</span>
                          <span className="font-medium text-gray-900 dark:text-gray-100">{item.inAppCreated}</span>
                        </div>
                      </div>
                    ) : (
                      <div className="text-xs text-gray-500">
                        {item.target === 'all' ? 'All active users' : `${item.target}: ${item.targetValue}`}
                      </div>
                    )}
                    
                    <div className="flex items-center justify-between mt-2 text-xs text-gray-400 pt-2 border-t border-gray-200 dark:border-gray-700">
                      <span>Sent by {user?.first_name} {user?.surname}</span>
                      <span>{new Date(item.sentAt).toLocaleString()}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PushNotifications;