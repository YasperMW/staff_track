import React from 'react';
import { Inbox, Search, FileX, Users, Building2, Calendar, Bell, FileText } from 'lucide-react';

type EmptyStateVariant = 'default' | 'search' | 'users' | 'departments' | 'attendance' | 'announcements' | 'requests';

interface EmptyStateProps {
  variant?: EmptyStateVariant;
  title?: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}

const variantConfig: Record<
  EmptyStateVariant,
  { icon: React.ElementType; title: string; description: string }
> = {
  default: {
    icon: Inbox,
    title: 'No data yet',
    description: 'Items will appear here once they are added.',
  },
  search: {
    icon: Search,
    title: 'No results found',
    description: 'Try adjusting your search or filter criteria.',
  },
  users: {
    icon: Users,
    title: 'No users yet',
    description: 'Add your first user to get started.',
  },
  departments: {
    icon: Building2,
    title: 'No departments yet',
    description: 'Create a department to organize your staff.',
  },
  attendance: {
    icon: Calendar,
    title: 'No attendance records',
    description: 'Attendance data will appear here once staff check in.',
  },
  announcements: {
    icon: Bell,
    title: 'No announcements yet',
    description: 'Create an announcement to notify your team.',
  },
  requests: {
    icon: FileText,
    title: 'No requests yet',
    description: 'Requests from staff will appear here.',
  },
};

const EmptyState: React.FC<EmptyStateProps> = ({
  variant = 'default',
  title,
  description,
  action,
  className = '',
}) => {
  const config = variantConfig[variant];
  const Icon = config.icon;

  return (
    <div className={`flex flex-col items-center justify-center py-16 px-6 text-center ${className}`}>
      <div className="w-16 h-16 bg-gray-100 dark:bg-gray-800 rounded-2xl flex items-center justify-center mb-6">
        <Icon className="w-8 h-8 text-gray-400 dark:text-gray-500" />
      </div>
      <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">
        {title ?? config.title}
      </h3>
      <p className="text-sm text-gray-500 dark:text-gray-400 max-w-xs mb-6">
        {description ?? config.description}
      </p>
      {action}
    </div>
  );
};

export default EmptyState;
