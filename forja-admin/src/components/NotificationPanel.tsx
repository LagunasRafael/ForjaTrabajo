import { useState, useEffect, useRef } from 'react';
import api from '../api/client';

interface ActivityItem {
  id: string;
  type: 'user' | 'service';
  title: string;
  description: string;
  time: string;
  rawDate: Date;
}

// Calcula tiempo relativo (hace X minutos, horas, días)
function timeAgo(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHrs = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMin < 1) return 'Justo ahora';
  if (diffMin < 60) return `Hace ${diffMin} min`;
  if (diffHrs < 24) return `Hace ${diffHrs}h`;
  if (diffDays < 7) return `Hace ${diffDays}d`;
  return date.toLocaleDateString('es-MX', { day: 'numeric', month: 'short' });
}

export const NotificationPanel = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const panelRef = useRef<HTMLDivElement>(null);

  // Cerrar al hacer click afuera
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Cargar actividad reciente
  const fetchActivity = async () => {
    setIsLoading(true);
    try {
      const [usersRes, servicesRes] = await Promise.all([
        api.get('/auth/users'),
        api.get('/services?include_inactive=true'),
      ]);

      const usersData = Array.isArray(usersRes.data) ? usersRes.data : [];
      const servicesData = Array.isArray(servicesRes.data) ? servicesRes.data : [];

      const userItems: ActivityItem[] = usersData
        .filter((u: any) => u.created_at)
        .map((u: any) => ({
          id: `user-${u.id}`,
          type: 'user' as const,
          title: 'Nuevo usuario registrado',
          description: u.full_name || u.email,
          time: timeAgo(new Date(u.created_at)),
          rawDate: new Date(u.created_at),
        }));

      const serviceItems: ActivityItem[] = servicesData
        .filter((s: any) => s.created_at)
        .map((s: any) => ({
          id: `service-${s.id}`,
          type: 'service' as const,
          title: 'Nuevo servicio publicado',
          description: s.title || 'Sin título',
          time: timeAgo(new Date(s.created_at)),
          rawDate: new Date(s.created_at),
        }));

      const all = [...userItems, ...serviceItems]
        .sort((a, b) => b.rawDate.getTime() - a.rawDate.getTime())
        .slice(0, 15);

      setActivities(all);

      // Los "no leídos" son los de las últimas 24 horas
      const oneDayAgo = new Date(Date.now() - 86400000);
      setUnreadCount(all.filter(a => a.rawDate > oneDayAgo).length);

    } catch (error) {
      console.error('Error cargando actividad:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Cargar al montar
  useEffect(() => {
    fetchActivity();
    // Refrescar cada 2 minutos
    const interval = setInterval(fetchActivity, 120000);
    return () => clearInterval(interval);
  }, []);

  const handleOpen = () => {
    setIsOpen(!isOpen);
    if (!isOpen) {
      setUnreadCount(0);
    }
  };

  return (
    <div className="relative" ref={panelRef}>
      {/* Botón de campana */}
      <button
        onClick={handleOpen}
        className="relative rounded-full p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors"
      >
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-indigo-500 text-[10px] font-bold text-white ring-2 ring-slate-900">
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
      </button>

      {/* Panel dropdown */}
      {isOpen && (
        <div className="absolute right-0 top-12 z-50 w-80 md:w-96 rounded-xl border border-slate-800 bg-slate-900 shadow-2xl shadow-black/40 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
          {/* Header */}
          <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3">
            <h3 className="text-sm font-bold text-white">Actividad Reciente</h3>
            <button
              onClick={fetchActivity}
              className="text-xs text-slate-400 hover:text-indigo-400 transition-colors"
            >
              Actualizar
            </button>
          </div>

          {/* Lista */}
          <div className="max-h-80 overflow-y-auto scrollbar-thin scrollbar-track-slate-900 scrollbar-thumb-slate-700">
            {isLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-slate-600 border-t-indigo-500"></div>
              </div>
            ) : activities.length === 0 ? (
              <div className="py-8 text-center text-sm text-slate-500">
                No hay actividad reciente
              </div>
            ) : (
              activities.map((item) => (
                <div
                  key={item.id}
                  className="flex items-start gap-3 border-b border-slate-800/50 px-4 py-3 hover:bg-slate-800/50 transition-colors"
                >
                  {/* Ícono por tipo */}
                  <div className={`mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${
                    item.type === 'user' 
                      ? 'bg-emerald-500/10 text-emerald-400'
                      : 'bg-blue-500/10 text-blue-400'
                  }`}>
                    {item.type === 'user' ? (
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg>
                    ) : (
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-slate-200 truncate">
                      {item.title}
                    </p>
                    <p className="text-xs text-slate-400 truncate">
                      {item.description}
                    </p>
                  </div>

                  <span className="shrink-0 text-[11px] text-slate-500">
                    {item.time}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};
