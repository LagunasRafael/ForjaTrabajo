import { useEffect, useRef } from 'react';

export function useAutoRefresh(callback: () => void, intervalMs = 30000) {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    const tick = () => callbackRef.current();

    const interval = setInterval(tick, intervalMs);

    const onFocus = () => tick();
    window.addEventListener('focus', onFocus);

    return () => {
      clearInterval(interval);
      window.removeEventListener('focus', onFocus);
    };
  }, [intervalMs]);
}
