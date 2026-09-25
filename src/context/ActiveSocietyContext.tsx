import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { supabase } from '../utils/supabase';
import type { Society } from '../types/database';
import { useAuth } from './AuthContext';

type ActiveSocietyContextValue = {
  society: Society | null;
  loading: boolean;
  refreshSociety: () => Promise<void>;
};

const ActiveSocietyContext = createContext<ActiveSocietyContextValue | undefined>(
  undefined,
);

export function ActiveSocietyProvider({ children }: { children: ReactNode }) {
  const { profile } = useAuth();
  const [society, setSociety] = useState<Society | null>(null);
  const [loading, setLoading] = useState(false);

  const refreshSociety = useCallback(async () => {
    if (!profile?.society_id) {
      setSociety(null);
      return;
    }

    setLoading(true);
    const { data, error } = await supabase
      .from('societies')
      .select('*')
      .eq('id', profile.society_id)
      .maybeSingle();

    setLoading(false);

    if (error) {
      console.warn('[ActiveSocietyContext] society fetch failed', error.message);
      setSociety(null);
      return;
    }

    setSociety(data as Society | null);
  }, [profile?.society_id]);

  useEffect(() => {
    refreshSociety();
  }, [refreshSociety]);

  const value = useMemo(
    () => ({ society, loading, refreshSociety }),
    [society, loading, refreshSociety],
  );

  return (
    <ActiveSocietyContext.Provider value={value}>
      {children}
    </ActiveSocietyContext.Provider>
  );
}

export function useActiveSociety() {
  const ctx = useContext(ActiveSocietyContext);
  if (!ctx) {
    throw new Error('useActiveSociety must be used within ActiveSocietyProvider');
  }
  return ctx;
}
