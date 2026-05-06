import { useAuth } from '../contexts/AuthContext';

/**
 * Hook to check if the current user is a System Admin
 * Returns true only if the user has "System Admin" or "System Administrator" role
 */
export const useSystemAdmin = () => {
  const { user } = useAuth();
  
  const roleName = user?.role_name || user?.role || '';
  const isSystemAdmin = roleName.toLowerCase().includes('system admin') || 
                       roleName.toLowerCase().includes('system administrator');
  
  return {
    isSystemAdmin: !!isSystemAdmin,
    user,
  };
};
