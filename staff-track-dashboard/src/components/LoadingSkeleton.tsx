import React from 'react';

interface SkeletonProps {
  className?: string;
  width?: string;
  height?: string;
  variant?: 'text' | 'circular' | 'rectangular';
}

const Skeleton: React.FC<SkeletonProps> = ({ 
  className = '', 
  width = 'w-full', 
  height = 'h-4', 
  variant = 'rectangular' 
}) => {
  const baseClasses = 'animate-pulse bg-gray-200 dark:bg-gray-700 rounded';
  const variantClasses = {
    text: 'h-4',
    circular: 'rounded-full',
    rectangular: 'rounded-md'
  };

  return (
    <div 
      className={`${baseClasses} ${variantClasses[variant]} ${width} ${height} ${className}`}
    />
  );
};

// Card Skeleton
export const CardSkeleton: React.FC<{ lines?: number }> = ({ lines = 3 }) => (
  <div className="card">
    <div className="space-y-3">
      <Skeleton width="w-12" height="h-12" variant="circular" />
      <div className="space-y-2">
        <Skeleton width="w-3/4" />
        <Skeleton width="w-1/2" />
      </div>
      <div className="space-y-2">
        {[...Array(lines)].map((_, i) => (
          <Skeleton key={i} width={i === lines - 1 ? 'w-full' : 'w-5/6'} />
        ))}
      </div>
    </div>
  </div>
);

// Table Skeleton
export const TableSkeleton: React.FC<{ rows?: number; columns?: number }> = ({ 
  rows = 5, 
  columns = 4 
}) => (
  <div className="card">
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead>
          <tr className="border-b border-gray-200 dark:border-gray-700">
            {[...Array(columns)].map((_, i) => (
              <th key={i} className="text-left p-3">
                <Skeleton width="w-20" height="h-4" />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {[...Array(rows)].map((_, rowIndex) => (
            <tr key={rowIndex} className="border-b border-gray-100 dark:border-gray-800">
              {[...Array(columns)].map((_, colIndex) => (
                <td key={colIndex} className="p-3">
                  <Skeleton 
                    width={colIndex === 0 ? 'w-16' : 'w-24'} 
                    height="h-4" 
                  />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

// Stats Card Skeleton
export const StatsCardSkeleton: React.FC = () => (
  <div className="card">
    <div className="flex items-center justify-between">
      <div className="space-y-2">
        <Skeleton width="w-20" height="h-4" />
        <Skeleton width="w-16" height="h-8" />
      </div>
      <Skeleton width="w-12" height="h-12" variant="circular" />
    </div>
  </div>
);

// User List Skeleton
export const UserListSkeleton: React.FC<{ count?: number }> = ({ count = 5 }) => (
  <div className="space-y-4">
    {[...Array(count)].map((_, i) => (
      <div key={i} className="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
        <Skeleton width="w-10" height="h-10" variant="circular" />
        <div className="flex-1 space-y-2">
          <Skeleton width="w-32" height="h-4" />
          <Skeleton width="w-48" height="h-3" />
        </div>
        <Skeleton width="w-20" height="h-8" />
      </div>
    ))}
  </div>
);

// Department Grid Skeleton
export const DepartmentGridSkeleton: React.FC<{ count?: number }> = ({ count = 6 }) => (
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    {[...Array(count)].map((_, i) => (
      <div key={i} className="card">
        <div className="space-y-4">
          <div className="flex items-start justify-between">
            <Skeleton width="w-12" height="h-12" variant="circular" />
            <div className="flex space-x-2">
              <Skeleton width="w-8" height="h-8" />
              <Skeleton width="w-8" height="h-8" />
            </div>
          </div>
          <div className="space-y-2">
            <Skeleton width="w-3/4" height="h-5" />
            <Skeleton width="w-full" height="h-4" />
            <Skeleton width="w-2/3" height="h-4" />
          </div>
          <div className="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
            <div className="flex items-center space-x-2">
              <Skeleton width="w-4" height="h-4" />
              <Skeleton width="w-8" height="h-4" />
            </div>
            <Skeleton width="w-16" height="h-4" />
          </div>
        </div>
      </div>
    ))}
  </div>
);

// Dashboard Skeleton
export const DashboardSkeleton: React.FC = () => (
  <div className="space-y-6">
    {/* Header */}
    <div className="space-y-2">
      <Skeleton width="w-48" height="h-8" />
      <Skeleton width="w-64" height="h-4" />
    </div>

    {/* Stats Cards */}
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {[...Array(3)].map((_, i) => (
        <StatsCardSkeleton key={i} />
      ))}
    </div>

    {/* Recent Activity */}
    <div className="card">
      <div className="space-y-4">
        <Skeleton width="w-32" height="h-6" />
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="flex items-center space-x-3">
              <Skeleton width="w-8" height="h-8" variant="circular" />
              <div className="flex-1 space-y-2">
                <Skeleton width="w-40" height="h-4" />
                <Skeleton width="w-24" height="h-3" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

// Form Skeleton
export const FormSkeleton: React.FC<{ fields?: number }> = ({ fields = 4 }) => (
  <div className="card">
    <div className="space-y-6">
      <div className="space-y-2">
        <Skeleton width="w-32" height="h-6" />
        <Skeleton width="w-48" height="h-4" />
      </div>
      
      <div className="space-y-4">
        {[...Array(fields)].map((_, i) => (
          <div key={i} className="space-y-2">
            <Skeleton width="w-24" height="h-4" />
            <Skeleton width="w-full" height="h-10" />
          </div>
        ))}
      </div>
      
      <div className="flex space-x-3">
        <Skeleton width="w-24" height="h-10" />
        <Skeleton width="w-20" height="h-10" />
      </div>
    </div>
  </div>
);

export default Skeleton;
