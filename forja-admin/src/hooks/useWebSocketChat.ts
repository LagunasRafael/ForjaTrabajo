import { useEffect, useRef, useState, useCallback } from 'react';

interface WebSocketMessage {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  message_type: string;
  created_at: string;
  status: string;
}

interface UseWebSocketChatReturn {
  isConnected: boolean;
  lastMessage: WebSocketMessage | null;
  reconnect: () => void;
}

export function useWebSocketChat(
  conversationId: string | undefined
): UseWebSocketChatReturn {
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
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
      console.error('Error parsing user from localStorage:', e);
    }
    return null;
  }, []);

  const getWsUrl = useCallback(() => {
    const baseUrl = import.meta.env.VITE_API_URL || 'https://forja-api-rw0r.onrender.com';
    return baseUrl
      .replace('https://', 'wss://')
      .replace('http://', 'ws://');
  }, []);

  const connect = useCallback(() => {
    if (!conversationId) return;

    // Cerrar conexión anterior antes de crear una nueva
    if (wsRef.current) {
      wsRef.current.onopen = null;
      wsRef.current.onclose = null;
      wsRef.current.onerror = null;
      wsRef.current.onmessage = null;
      wsRef.current.close();
      wsRef.current = null;
    }

    const adminUserId = getAdminUserId();
    if (!adminUserId) {
      console.warn('[WS] No admin user ID found in localStorage');
      return;
    }

    const wsUrl = `${getWsUrl()}/services/chat/ws/${conversationId}/${adminUserId}`;
    console.log(`[WS] Connecting to ${wsUrl}`);

    try {
      const ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        console.log('[WS] Connected');
        setIsConnected(true);
        retryCountRef.current = 0;
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log('[WS] Received message:', data);
          if (data.id && data.conversation_id && data.content !== undefined) {
            setLastMessage(data as WebSocketMessage);
          }
        } catch (e) {
          console.error('[WS] Error parsing message:', e);
        }
      };

      ws.onclose = (event) => {
        console.log(`[WS] Disconnected (code: ${event.code})`);
        setIsConnected(false);

        if (retryCountRef.current < maxRetries) {
          const delay = Math.min(1000 * Math.pow(2, retryCountRef.current), 30000);
          console.log(`[WS] Reconnecting in ${delay}ms (attempt ${retryCountRef.current + 1})`);
          reconnectTimeoutRef.current = setTimeout(() => {
            retryCountRef.current++;
            connect();
          }, delay);
        } else {
          console.warn('[WS] Max retries reached');
        }
      };

      ws.onerror = (error) => {
        console.error('[WS] Error:', error);
      };

      wsRef.current = ws;
    } catch (e) {
      console.error('[WS] Failed to create WebSocket:', e);
    }
  }, [conversationId, getAdminUserId, getWsUrl]);

  const reconnect = useCallback(() => {
    disconnect();
    retryCountRef.current = 0;
    connect();
  }, [connect]);

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
    if (conversationId) {
      connect();
    }

    return () => {
      disconnect();
    };
  }, [conversationId, connect, disconnect]);

  return { isConnected, lastMessage, reconnect };
}
