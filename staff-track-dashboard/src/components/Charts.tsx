import React from 'react';

interface ChartProps {
  title?: string;
  subtitle?: string;
  className?: string;
}

// Bar Chart Component
export const BarChart: React.FC<ChartProps & { 
  data: Array<{ label: string; value: number; color?: string }>;
  height?: number;
}> = ({ title, subtitle, data, height = 200, className = '' }) => {
  const maxValue = Math.max(...data.map(d => d.value));
  
  return (
    <div className={`card ${className}`}>
      {(title || subtitle) && (
        <div className="mb-4">
          {title && <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{title}</h3>}
          {subtitle && <p className="text-sm text-text-grey dark:text-text-grey-dark">{subtitle}</p>}
        </div>
      )}
      
      <div className="space-y-3" style={{ height: `${height}px` }}>
        {data.map((item, index) => (
          <div key={index} className="flex items-center space-x-3">
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
                  {item.label}
                </span>
                <span className="text-sm text-text-grey dark:text-text-grey-dark">
                  {item.value}
                </span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div
                  className={`h-2 rounded-full transition-all duration-500 ${item.color || 'bg-sky-blue'}`}
                  style={{ width: `${(item.value / maxValue) * 100}%` }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Line Chart Component
export const LineChart: React.FC<ChartProps & {
  data: Array<{ label: string; value: number }>;
  height?: number;
  color?: string;
}> = ({ title, subtitle, data, height = 200, color = '#3B82F6', className = '' }) => {
  const maxValue = Math.max(...data.map(d => d.value));
  const points = data.map((point, index) => {
    const x = (index / (data.length - 1)) * 100;
    const y = 100 - (point.value / maxValue) * 100;
    return `${x},${y}`;
  }).join(' ');

  return (
    <div className={`card ${className}`}>
      {(title || subtitle) && (
        <div className="mb-4">
          {title && <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{title}</h3>}
          {subtitle && <p className="text-sm text-text-grey dark:text-text-grey-dark">{subtitle}</p>}
        </div>
      )}
      
      <div className="relative" style={{ height: `${height}px` }}>
        <svg width="100%" height="100%" className="overflow-visible">
          {/* Grid lines */}
          {[...Array(5)].map((_, i) => (
            <line
              key={i}
              x1="0"
              y1={`${(i / 4) * 100}%`}
              x2="100%"
              y2={`${(i / 4) * 100}%`}
              stroke="currentColor"
              strokeWidth="1"
              className="text-gray-200 dark:text-gray-700"
            />
          ))}
          
          {/* Data line */}
          <polyline
            points={points}
            fill="none"
            stroke={color}
            strokeWidth="2"
            className="transition-all duration-500"
          />
          
          {/* Data points */}
          {data.map((point, index) => {
            const x = (index / (data.length - 1)) * 100;
            const y = 100 - (point.value / maxValue) * 100;
            return (
              <circle
                key={index}
                cx={`${x}%`}
                cy={`${y}%`}
                r="4"
                fill={color}
                className="transition-all duration-500"
              />
            );
          })}
        </svg>
        
        {/* X-axis labels */}
        <div className="flex justify-between mt-2">
          {data.map((point, index) => (
            <span key={index} className="text-xs text-text-grey dark:text-text-grey-dark">
              {point.label}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

// Pie Chart Component
export const PieChart: React.FC<ChartProps & {
  data: Array<{ label: string; value: number; color: string }>;
  size?: number;
}> = ({ title, subtitle, data, size = 200, className = '' }) => {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  let currentAngle = -90; // Start from top
  
  const createPath = (startAngle: number, endAngle: number, radius: number) => {
    const startAngleRad = (startAngle * Math.PI) / 180;
    const endAngleRad = (endAngle * Math.PI) / 180;
    
    const x1 = 50 + radius * Math.cos(startAngleRad);
    const y1 = 50 + radius * Math.sin(startAngleRad);
    const x2 = 50 + radius * Math.cos(endAngleRad);
    const y2 = 50 + radius * Math.sin(endAngleRad);
    
    const largeArcFlag = endAngle - startAngle > 180 ? 1 : 0;
    
    return `M 50 50 L ${x1} ${y1} A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2} Z`;
  };
  
  return (
    <div className={`card ${className}`}>
      {(title || subtitle) && (
        <div className="mb-4">
          {title && <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{title}</h3>}
          {subtitle && <p className="text-sm text-text-grey dark:text-text-grey-dark">{subtitle}</p>}
        </div>
      )}
      
      <div className="flex items-center justify-center">
        <div className="relative" style={{ width: size, height: size }}>
          <svg width="100%" height="100%" viewBox="0 0 100 100">
            {data.map((item, index) => {
              const percentage = (item.value / total) * 100;
              const angle = (percentage / 100) * 360;
              const endAngle = currentAngle + angle;
              
              const path = createPath(currentAngle, endAngle, 40);
              currentAngle = endAngle;
              
              return (
                <g key={index}>
                  <path
                    d={path}
                    fill={item.color}
                    className="transition-all duration-500 hover:opacity-80"
                  />
                </g>
              );
            })}
          </svg>
        </div>
      </div>
      
      {/* Legend */}
      <div className="mt-4 space-y-2">
        {data.map((item, index) => (
          <div key={index} className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: item.color }}
              />
              <span className="text-sm text-text-dark dark:text-text-dark-light">
                {item.label}
              </span>
            </div>
            <div className="text-right">
              <span className="text-sm font-medium text-text-dark dark:text-text-dark-light">
                {item.value}
              </span>
              <span className="text-xs text-text-grey dark:text-text-grey-dark ml-1">
                ({((item.value / total) * 100).toFixed(1)}%)
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Progress Ring Component
export const ProgressRing: React.FC<ChartProps & {
  value: number;
  maxValue: number;
  size?: number;
  strokeWidth?: number;
  color?: string;
}> = ({ title, subtitle, value, maxValue, size = 120, strokeWidth = 8, color = '#3B82F6', className = '' }) => {
  const percentage = (value / maxValue) * 100;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;
  
  return (
    <div className={`card flex flex-col items-center ${className}`}>
      {(title || subtitle) && (
        <div className="mb-4 text-center">
          {title && <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{title}</h3>}
          {subtitle && <p className="text-sm text-text-grey dark:text-text-grey-dark">{subtitle}</p>}
        </div>
      )}
      
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="transform -rotate-90">
          {/* Background circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="currentColor"
            strokeWidth={strokeWidth}
            fill="none"
            className="text-gray-200 dark:text-gray-700"
          />
          
          {/* Progress circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={color}
            strokeWidth={strokeWidth}
            fill="none"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className="transition-all duration-500"
          />
        </svg>
        
        {/* Center text */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <span className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
              {percentage.toFixed(0)}%
            </span>
            <p className="text-xs text-text-grey dark:text-text-grey-dark">
              {value} / {maxValue}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

// Stats Card with Mini Chart
export const StatsCard: React.FC<{
  title: string;
  value: string | number;
  change?: number;
  changeType?: 'increase' | 'decrease';
  icon: React.ReactNode;
  color: string;
  miniChart?: Array<{ value: number }>;
}> = ({ title, value, change, changeType = 'increase', icon, color, miniChart }) => {
  const changeColor = changeType === 'increase' ? 'text-green-600' : 'text-red-600';
  const changeIcon = changeType === 'increase' ? '↑' : '↓';
  
  return (
    <div className="card">
      <div className="flex items-center justify-between mb-4">
        <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: `${color}20` }}>
          <div style={{ color }}>
            {icon}
          </div>
        </div>
        {change !== undefined && (
          <div className={`flex items-center space-x-1 text-sm font-medium ${changeColor}`}>
            <span>{changeIcon}</span>
            <span>{Math.abs(change)}%</span>
          </div>
        )}
      </div>
      
      <div>
        <p className="text-2xl font-bold text-text-dark dark:text-text-dark-light">
          {value}
        </p>
        <p className="text-sm text-text-grey dark:text-text-grey-dark">
          {title}
        </p>
      </div>
      
      {/* Mini sparkline */}
      {miniChart && miniChart.length > 0 && (
        <div className="mt-4 h-8">
          <svg width="100%" height="100%" className="overflow-visible">
            <polyline
              points={miniChart.map((point, index) => {
                const x = (index / (miniChart.length - 1)) * 100;
                const maxValue = Math.max(...miniChart.map(p => p.value));
                const y = 100 - (point.value / maxValue) * 100;
                return `${x},${y}`;
              }).join(' ')}
              fill="none"
              stroke={color}
              strokeWidth="2"
              className="transition-all duration-500"
            />
          </svg>
        </div>
      )}
    </div>
  );
};

// Activity Heatmap
export const ActivityHeatmap: React.FC<ChartProps & {
  data: Array<Array<number>>;
  labels?: string[];
}> = ({ title, subtitle, data, labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'], className = '' }) => {
  const maxValue = Math.max(...data.flat());
  
  const getIntensity = (value: number) => {
    if (value === 0) return 'bg-gray-100 dark:bg-gray-800';
    const intensity = value / maxValue;
    if (intensity < 0.25) return 'bg-sky-blue bg-opacity-20';
    if (intensity < 0.5) return 'bg-sky-blue bg-opacity-40';
    if (intensity < 0.75) return 'bg-sky-blue bg-opacity-60';
    return 'bg-sky-blue bg-opacity-80';
  };
  
  return (
    <div className={`card ${className}`}>
      {(title || subtitle) && (
        <div className="mb-4">
          {title && <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">{title}</h3>}
          {subtitle && <p className="text-sm text-text-grey dark:text-text-grey-dark">{subtitle}</p>}
        </div>
      )}
      
      <div className="space-y-2">
        {data.map((week, weekIndex) => (
          <div key={weekIndex} className="flex items-center space-x-2">
            <span className="text-xs text-text-grey dark:text-text-grey-dark w-8">
              W{weekIndex + 1}
            </span>
            <div className="flex space-x-1 flex-1">
              {week.map((day, dayIndex) => (
                <div
                  key={dayIndex}
                  className={`flex-1 h-4 rounded ${getIntensity(day)} transition-all duration-200 hover:ring-2 hover:ring-sky-blue`}
                  title={`${labels[dayIndex]}: ${day} activities`}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
      
      <div className="flex items-center justify-between mt-4">
        <div className="flex space-x-1">
          {labels.map((label, index) => (
            <span key={index} className="text-xs text-text-grey dark:text-text-grey-dark">
              {label.charAt(0)}
            </span>
          ))}
        </div>
        <div className="flex items-center space-x-2">
          <span className="text-xs text-text-grey dark:text-text-grey-dark">Less</span>
          <div className="flex space-x-1">
            <div className="w-3 h-3 bg-gray-100 dark:bg-gray-800 rounded"></div>
            <div className="w-3 h-3 bg-sky-blue bg-opacity-20 rounded"></div>
            <div className="w-3 h-3 bg-sky-blue bg-opacity-40 rounded"></div>
            <div className="w-3 h-3 bg-sky-blue bg-opacity-60 rounded"></div>
            <div className="w-3 h-3 bg-sky-blue bg-opacity-80 rounded"></div>
          </div>
          <span className="text-xs text-text-grey dark:text-text-grey-dark">More</span>
        </div>
      </div>
    </div>
  );
};
