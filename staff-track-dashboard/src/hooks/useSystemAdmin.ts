import { useAuth } from '../contexts/AuthContext';

/**
 * Hook to check if the current user is a System Admin
 * Returns true only if the user has "System Admin" or "System Administrator" role
 */
export const useSystemAdmin = () => {
  const { user } = useAuth();
  
  const isSystemAdmin = user?.role_name?.toLowerCase().includes('system admin') || 
                       user?.role_name?.toLowerCase().includes('system administrator');
  
  return {
    isSystemAdmin: !!isSystemAdmin,
    user,
  };
};
