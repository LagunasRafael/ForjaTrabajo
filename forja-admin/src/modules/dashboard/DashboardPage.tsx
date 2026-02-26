import { useState, useEffect } from 'react';
import { toast } from 'sonner';

// Asegúrate de que tu interfaz de User esté exportada en algún lado o ajusta esto
// import type { User } from '../users/types/user.types'; 
import { getUsersApi } from '../users/services/user.service';
import { getCategories } from '../services/services/category.service';
import { getServices } from '../services/services/service.service';

export const DashboardPage = () => {
  const [stats, setStats] = useState({
    users: 0,
    categories: 0,
    services: 0,
    activeRequests: 12
  });
  
  // NUEVO ESTADO: Guardaremos a los últimos usuarios aquí
  const [recentUsers, setRecentUsers] = useState<any[]>([]); 
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadDashboardData = async () => {
      try {
        const [usersData, categoriesData, servicesData] = await Promise.all([
          getUsersApi(),
          getCategories(),
          getServices()
        ]);

        setStats({
          users: usersData.length,
          categories: categoriesData.length,
          services: servicesData.length,
          activeRequests: 12 
        });

        // LÓGICA NUEVA: Asumimos que el backend los manda en orden, 
        // o si no, podemos usar .reverse() para tener los últimos 5
        const lastFiveUsers = [...usersData].reverse().slice(0, 5);
        setRecentUsers(lastFiveUsers);

      } catch (error) {
        console.error("Error cargando métricas:", error);
        toast.error('No se pudieron cargar algunas métricas del panel');
      } finally {
        setIsLoading(false);
      }
    };

    loadDashboardData();
  }, []);

  // --- COMPONENTE DE TARJETA (Se mantiene intacto) ---
  const StatCard = ({ title, value, icon, trend, colorClass }: any) => (
    <div className="relative overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-slate-400">{title}</p>
          <h3 className="mt-2 text-3xl font-bold text-white">
            {isLoading ? (
              <span className="inline-block h-8 w-16 animate-pulse rounded bg-slate-800"></span>
            ) : (
              value
            )}
          </h3>
        </div>
        <div className={`flex h-12 w-12 items-center justify-center rounded-xl bg-slate-800/50 ${colorClass}`}>
          {icon}
        </div>
      </div>
      <div className="mt-4 flex items-center text-sm">
        <span className="flex items-center font-medium text-emerald-400">
          <svg className="mr-1 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>
          {trend}
        </span>
        <span className="ml-2 text-slate-500">desde el mes pasado</span>
      </div>
      <div className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-current opacity-[0.03] blur-2xl group-hover:opacity-[0.05] transition-opacity"></div>
    </div>
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      
      {/* Encabezado */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight">Panel de Control</h2>
        <p className="text-sm text-slate-400 mt-1">Resumen general de la plataforma Forja Trabajo.</p>
      </div>

      {/* Grid de KPIs */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {/* Tus tarjetas actuales se mantienen igual, no las borraré para ahorrar espacio visual */}
        <StatCard title="Usuarios Registrados" value={stats.users} trend="+12%" colorClass="text-blue-400 shadow-[0_0_15px_rgba(96,165,250,0.15)]" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>} />
        <StatCard title="Oficios (Categorías)" value={stats.categories} trend="+3" colorClass="text-emerald-400 shadow-[0_0_15px_rgba(52,211,153,0.15)]" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>} />
        <StatCard title="Servicios Publicados" value={stats.services} trend="+28%" colorClass="text-indigo-400 shadow-[0_0_15px_rgba(129,140,248,0.15)]" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M15 18a3 3 0 1 0-6 0"/><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2-2h12a2 2 0 0 0 2-2V7z"/><circle cx="12" cy="13" r="2"/></svg>} />
        <StatCard title="Solicitudes Activas" value={stats.activeRequests} trend="+5%" colorClass="text-rose-400 shadow-[0_0_15px_rgba(251,113,133,0.15)]" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>} />
      </div>

      {/* 👇 NUEVA SECCIÓN: ACTIVIDAD RECIENTE 👇 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Tabla de Usuarios Recientes (Ocupa 2/3 del espacio en pantallas grandes) */}
        <div className="lg:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-white tracking-tight">Nuevos Usuarios</h3>
            <button className="text-sm text-indigo-400 hover:text-indigo-300 font-medium transition-colors">
              Ver todos
            </button>
          </div>

          {isLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map(i => (
                <div key={i} className="flex items-center gap-4 animate-pulse">
                  <div className="h-10 w-10 rounded-full bg-slate-800"></div>
                  <div className="space-y-2 flex-1">
                    <div className="h-4 w-1/3 rounded bg-slate-800"></div>
                    <div className="h-3 w-1/4 rounded bg-slate-800"></div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="divide-y divide-slate-800/60">
              {recentUsers.map((user) => (
                <div key={user.id} className="flex items-center justify-between py-4 group">
                  <div className="flex items-center gap-4">
                    
                    {/* El Avatar mágico de S3 */}
                    <div className="relative h-10 w-10 rounded-full bg-slate-800 overflow-hidden flex items-center justify-center border border-slate-700 shadow-inner">
                      {user.avatarUrl ? (
                        <img src={user.avatarUrl} alt={user.full_name} className="h-full w-full object-cover" />
                      ) : (
                        <span className="text-slate-400 font-bold text-sm">
                          {user.full_name.charAt(0).toUpperCase()}
                        </span>
                      )}
                    </div>

                    <div>
                      <h4 className="text-sm font-semibold text-slate-200 group-hover:text-white transition-colors">
                        {user.full_name}
                      </h4>
                      <p className="text-xs text-slate-500">{user.email}</p>
                    </div>
                  </div>

                  {/* Etiqueta de Rol */}
                  <div className="flex items-center">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      user.role === 'admin' ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20' :
                      user.role === 'worker' ? 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20' :
                      'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                    }`}>
                      {user.role}
                    </span>
                  </div>
                </div>
              ))}
              
              {recentUsers.length === 0 && (
                <p className="py-4 text-sm text-slate-500 text-center">No hay usuarios registrados aún.</p>
              )}
            </div>
          )}
        </div>

        {/* Otra tarjeta complementaria (Ocupa 1/3 del espacio) */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm flex flex-col items-center justify-center text-center border-dashed">
          <div className="h-16 w-16 bg-slate-800/50 rounded-full flex items-center justify-center mb-4 text-indigo-400">
             <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>
          </div>
          <h3 className="text-white font-medium mb-2">Configuración Rápida</h3>
          <p className="text-sm text-slate-400 mb-6">
            Personaliza el comportamiento de la plataforma y ajusta las reglas de negocio.
          </p>
          <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white text-sm font-medium rounded-lg transition-colors border border-slate-700 w-full">
            Ir a Ajustes
          </button>
        </div>

      </div>

    </div>
  );
};