import React, { useState, useMemo } from 'react';
import { 
  ChevronUp, 
  ChevronDown, 
  Search, 
  Filter, 
  ChevronLeft, 
  ChevronRight,
  MoreVertical,
  Eye,
  Edit,
  Trash2
} from 'lucide-react';

export interface Column<T> {
  key: keyof T;
  label: string;
  sortable?: boolean;
  filterable?: boolean;
  render?: (value: any, row: T) => React.ReactNode;
  width?: string;
}

export interface Action<T> {
  label: string | ((row: T) => string);
  icon: React.ReactNode | ((row: T) => React.ReactNode);
  onClick: (row: T) => void;
  variant?: 'primary' | 'secondary' | 'danger';
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  actions?: Action<T>[] | ((row: T) => Action<T>[]);
  loading?: boolean;
  searchable?: boolean;
  filterable?: boolean;
  sortable?: boolean;
  pagination?: {
    page: number;
    perPage: number;
    total: number;
    onPageChange: (page: number) => void;
    onPerPageChange: (perPage: number) => void;
  };
  emptyMessage?: string;
  className?: string;
}

function DataTable<T extends Record<string, any>>({
  data,
  columns,
  actions,
  loading = false,
  searchable = true,
  pagination,
  emptyMessage = 'No data available',
  className = ''
}: DataTableProps<T>) {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortConfig, setSortConfig] = useState<{
    key: keyof T | null;
    direction: 'asc' | 'desc';
  }>({ key: null, direction: 'asc' });
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [selectedRows, setSelectedRows] = useState<Set<string | number>>(new Set());

  // Filter and sort data
  const processedData = useMemo(() => {
    let filtered = [...data];

    // Apply search
    if (searchTerm) {
      filtered = filtered.filter(row =>
        columns.some(column => {
          const value = row[column.key];
          return value && value.toString().toLowerCase().includes(searchTerm.toLowerCase());
        })
      );
    }

    // Apply filters
    Object.entries(filters).forEach(([key, value]) => {
      if (value) {
        filtered = filtered.filter(row =>
          row[key] && row[key].toString().toLowerCase().includes(value.toLowerCase())
        );
      }
    });

    // Apply sorting
    if (sortConfig.key) {
      filtered.sort((a, b) => {
        const aValue = a[sortConfig.key!];
        const bValue = b[sortConfig.key!];
        
        if (aValue === null || aValue === undefined) return 1;
        if (bValue === null || bValue === undefined) return -1;
        
        if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
        if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }

    return filtered;
  }, [data, searchTerm, filters, sortConfig, columns]);

  const handleSort = (key: keyof T) => {
    setSortConfig(prev => ({
      key,
      direction: prev.key === key && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
  };

  const handleFilter = (key: string, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const toggleRowSelection = (id: string | number) => {
    setSelectedRows(prev => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  };

  const toggleAllRows = () => {
    if (selectedRows.size === processedData.length) {
      setSelectedRows(new Set());
    } else {
      setSelectedRows(new Set(processedData.map(row => row.id || row.user_id)));
    }
  };

  const getSortIcon = (column: Column<T>) => {
    if (sortConfig.key !== column.key) return null;
    return sortConfig.direction === 'asc' ? 
      <ChevronUp className="w-4 h-4" /> : 
      <ChevronDown className="w-4 h-4" />;
  };

  const getActionVariant = (variant?: string) => {
    switch (variant) {
      case 'primary': return 'text-sky-blue hover:bg-sky-blue hover:text-white';
      case 'danger': return 'text-pale-red hover:bg-pale-red hover:text-white';
      default: return 'text-text-grey hover:bg-gray-100';
    }
  };

  if (loading) {
    return (
      <div className="card">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-12 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`card ${className}`}>
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h3 className="text-lg font-semibold text-text-dark dark:text-text-dark-light">
          {data.length} {data.length === 1 ? 'Record' : 'Records'}
        </h3>
        
        <div className="flex items-center gap-3">
          {searchable && (
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-text-grey" />
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="input-field pl-10 w-48"
              />
            </div>
          )}
          
          {columns.some(col => col.filterable) && (
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="flex items-center space-x-2 px-3 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <Filter className="w-4 h-4" />
              <span>Filters</span>
            </button>
          )}
        </div>
      </div>

      {/* Filters */}
      {showFilters && columns.some(col => col.filterable) && (
        <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {columns.filter(col => col.filterable).map(column => (
              <div key={String(column.key)}>
                <label className="block text-sm font-medium text-text-grey mb-1">
                  {column.label}
                </label>
                <input
                  type="text"
                  placeholder={`Filter by ${column.label.toLowerCase()}...`}
                  value={filters[String(column.key)] || ''}
                  onChange={(e) => handleFilter(String(column.key), e.target.value)}
                  className="input-field w-full"
                />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Table */}
      {processedData.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-4">
            <Search className="w-8 h-8 text-text-grey" />
          </div>
          <p className="text-text-grey">{emptyMessage}</p>
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <th className="text-left p-3">
                    <input
                      type="checkbox"
                      checked={selectedRows.size === processedData.length && processedData.length > 0}
                      onChange={toggleAllRows}
                      className="rounded border-gray-300"
                    />
                  </th>
                  {columns.map(column => (
                    <th
                      key={String(column.key)}
                      className={`text-left p-3 font-medium text-text-dark dark:text-text-dark-light ${
                        column.sortable ? 'cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800' : ''
                      }`}
                      style={{ width: column.width }}
                      onClick={() => column.sortable && handleSort(column.key)}
                    >
                      <div className="flex items-center space-x-1">
                        <span>{column.label}</span>
                        {column.sortable && getSortIcon(column)}
                      </div>
                    </th>
                  ))}
                  {actions && <th className="text-left p-3 font-medium text-text-dark dark:text-text-dark-light">Actions</th>}
                </tr>
              </thead>
              <tbody>
                {processedData.map((row, index) => (
                  <tr
                    key={row.id || row.user_id || index}
                    className={`border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors ${
                      selectedRows.has(row.id || row.user_id) ? 'bg-sky-blue bg-opacity-5' : ''
                    }`}
                  >
                    <td className="p-3">
                      <input
                        type="checkbox"
                        checked={selectedRows.has(row.id || row.user_id)}
                        onChange={() => toggleRowSelection(row.id || row.user_id)}
                        className="rounded border-gray-300"
                      />
                    </td>
                    {columns.map(column => (
                      <td key={String(column.key)} className="p-3">
                        {column.render ? 
                          column.render(row[column.key], row) : 
                          row[column.key]
                        }
                      </td>
                    ))}
                    {actions && (
                      <td className="p-3">
                        <div className="relative">
                          <button className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors">
                            <MoreVertical className="w-4 h-4 text-text-grey" />
                          </button>
                          {/* Dropdown menu would go here - for now showing inline actions */}
                          <div className="flex items-center space-x-2">
                            {(() => {
                              const rowActions = typeof actions === 'function' ? actions(row) : actions;
                              return rowActions?.map((action, actionIndex) => {
                                const label = typeof action.label === 'function' ? action.label(row) : action.label;
                                const icon = typeof action.icon === 'function' ? action.icon(row) : action.icon;
                                return (
                                  <button
                                    key={actionIndex}
                                    onClick={() => action.onClick(row)}
                                    className={`p-1 rounded transition-colors ${getActionVariant(action.variant)}`}
                                    title={label}
                                  >
                                    {icon}
                                  </button>
                                );
                              });
                            })()}
                          </div>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {pagination && (
            <div className="flex flex-col sm:flex-row justify-between items-center gap-4 mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
              <div className="flex items-center space-x-2 text-sm text-text-grey">
                <span>Showing</span>
                <select
                  value={pagination.perPage}
                  onChange={(e) => pagination.onPerPageChange(Number(e.target.value))}
                  className="input-field py-1 px-2 w-20"
                >
                  <option value={10}>10</option>
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                </select>
                <span>of {pagination.total} results</span>
              </div>
              
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => pagination.onPageChange(pagination.page - 1)}
                  disabled={pagination.page === 1}
                  className="p-2 rounded-lg border border-gray-200 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 transition-colors"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                
                <div className="flex items-center space-x-1">
                  {Array.from({ length: Math.min(5, Math.ceil(pagination.total / pagination.perPage)) }, (_, i) => {
                    const pageNum = i + 1;
                    const isActive = pageNum === pagination.page;
                    return (
                      <button
                        key={pageNum}
                        onClick={() => pagination.onPageChange(pageNum)}
                        className={`px-3 py-1 rounded-lg transition-colors ${
                          isActive 
                            ? 'bg-sky-blue text-white' 
                            : 'border border-gray-200 hover:bg-gray-50'
                        }`}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                </div>
                
                <button
                  onClick={() => pagination.onPageChange(pagination.page + 1)}
                  disabled={pagination.page >= Math.ceil(pagination.total / pagination.perPage)}
                  className="p-2 rounded-lg border border-gray-200 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 transition-colors"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default DataTable;
