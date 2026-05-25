import { useEffect, useRef, useState, useCallback } from 'react';

export interface PendingCounts {
  disputes: number;
  verifications: number;
  reports: number;
  reported_services: number;
  total_users: number;
}

export function useWebSocketPendingCounts() {
  const [counts, setCounts] = useState<PendingCounts>({
    disputes: 0,
    verifications: 0,
    reports: 0,
    reported_services: 0,
    total_users: 0,
  });
  const [isConnected, setIsConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const retryCountRef = useRef(0);
  const maxRetries = 10;

  const getAdminUserId = useCallback(() => {
    try {
      const userStr = localStorage.getItem('user');
      if (userStr) {
        const user = JSON.parse(userStr);
        return user.id;
      }
    } catch (e) {
      console.error('Error parsing user:', e);
    }
    return null;
  }, []);

  const getWsUrl = useCallback(() => {
    const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
    return baseUrl.replace('https://', 'wss://').replace('http://', 'ws://');
  }, []);

  const connect = useCallback(() => {
    const adminUserId = getAdminUserId();
    if (!adminUserId) return;

    const wsUrl = `${getWsUrl()}/admin/ws/counts/${adminUserId}`;
    console.log(`[AdminWS] Connecting to ${wsUrl}`);

    try {
      const ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        console.log('[AdminWS] Connected');
        setIsConnected(true);
        retryCountRef.current = 0;
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === 'counts_update' && data.data) {
            setCounts(data.data);
          }
        } catch (e) {
          console.error('[AdminWS] Error parsing message:', e);
        }
      };

      ws.onclose = () => {
        console.log('[AdminWS] Disconnected');
        setIsConnected(false);

        if (retryCountRef.current < maxRetries) {
          const delay = Math.min(1000 * Math.pow(2, retryCountRef.current), 30000);
          reconnectTimeoutRef.current = setTimeout(() => {
            retryCountRef.current++;
            connect();
          }, delay);
        }
      };

      ws.onerror = (error) => {
        console.error('[AdminWS] Error:', error);
      };

      wsRef.current = ws;
    } catch (e) {
      console.error('[AdminWS] Failed to create WebSocket:', e);
    }
  }, [getAdminUserId, getWsUrl]);

  const disconnect = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    setIsConnected(false);
  }, []);

  useEffect(() => {
    connect();
    return () => disconnect();
  }, [connect, disconnect]);

  return { counts, isConnected };
}
