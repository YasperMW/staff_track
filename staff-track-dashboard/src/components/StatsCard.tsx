import React from 'react';

interface StatsCardProps {
  label: string;
  value: number | string;
  icon: React.ReactNode;
  iconBgColor?: string;
  valueColor?: string;
}

const StatsCard: React.FC<StatsCardProps> = ({
  label,
  value,
  icon,
  iconBgColor = 'bg-sky-blue',
  valueColor = 'text-text-dark dark:text-text-dark-light'
}) => {
  return (
    <div className="card">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-text-grey dark:text-text-grey-dark">{label}</p>
          <p className={`text-2xl font-bold ${valueColor}`}>
            {value}
          </p>
        </div>
        <div className={`w-12 h-12 ${iconBgColor} bg-opacity-10 rounded-xl flex items-center justify-center`}>
          {icon}
        </div>
      </div>
    </div>
  );
};

export default StatsCard;