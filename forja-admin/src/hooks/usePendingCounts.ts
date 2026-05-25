import { useWebSocketPendingCounts } from './useWebSocketPendingCounts';
export function usePendingCounts() {
  const { counts, isConnected } = useWebSocketPendingCounts();

  return {
    counts,
    isLoading: !isConnected && counts.disputes === 0 && counts.verifications === 0 && counts.reports === 0,
  };
}
