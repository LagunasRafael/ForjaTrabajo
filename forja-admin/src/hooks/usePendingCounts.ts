import { useState, useEffect } from 'react';
import { useAutoRefresh } from './useAutoRefresh';
import { getConversationsApi } from '../modules/disputes/services/disputes.service';
import { getReportsApi } from '../modules/reports/services/reports.service';
import api from '../api/client';

export interface PendingCounts {
  disputes: number;
  verifications: number;
  reports: number;
}

export function usePendingCounts() {
  const [counts, setCounts] = useState<PendingCounts>({
    disputes: 0,
    verifications: 0,
    reports: 0,
  });
  const [isLoading, setIsLoading] = useState(true);

  const fetchCounts = async () => {
    try {
      const [conversations, verificationsRes, reports] = await Promise.all([
        getConversationsApi(),
        api.get('/auth/admin/verifications'),
        getReportsApi('pending'),
      ]);

      setCounts({
        disputes: conversations.filter(c => c.status === 'dispute').length,
        verifications: verificationsRes.data.filter((v: any) => v.status === 'pending').length,
        reports: reports.length,
      });
    } catch (e) {
      console.error('Error fetching pending counts:', e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCounts();
  }, []);

  useAutoRefresh(fetchCounts, 30000);

  return { counts, isLoading, refresh: fetchCounts };
}
