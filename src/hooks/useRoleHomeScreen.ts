import { useAuth } from '../context/AuthContext';

export function useRoleHomeScreen(): 'admin' | 'resident' | 'security' | 'auth' {
  const { session, role, loading } = useAuth();

  if (loading) return 'auth';
  if (!session) return 'auth';
  if (role === 'admin') return 'admin';
  if (role === 'security') return 'security';
  if (role === 'resident') return 'resident';
  return 'auth';
}
