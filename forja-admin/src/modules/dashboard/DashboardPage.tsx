import { useState, useEffect, useMemo } from 'react';
import { useAutoRefresh } from '../../hooks/useAutoRefresh';
import { usePendingCounts } from '../../hooks/usePendingCounts';
import { toast } from 'sonner';
import { 
  PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend, 
  BarChart, Bar, XAxis, YAxis, CartesianGrid 
} from 'recharts';

// Servicios de API
import { getUsersApi } from '../users/services/user.service';
import { getCategories } from '../services/services/category.service';
import { getServices } from '../services/services/service.service';

export const DashboardPage = () => {
  const { counts } = usePendingCounts();
  const [stats, setStats] = useState({
    users: 0,
    categories: 0,
    services: 0,
    activeRequests: 0 // Dinámico: MATCHED
  });
  
  const [recentUsers, setRecentUsers] = useState<any[]>([]);
  const [services, setServices] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [categories, setCategories] = useState<any[]>([]);

  const loadDashboardData = async () => {
    try {
      setIsLoading(true);
      const [usersData, categoriesData, servicesData] = await Promise.all([
        getUsersApi(),
        getCategories(),
        getServices()
      ]);

      // 📊 Cálculos de métricas reales
      const matched = servicesData.filter(s => (s.status || '').toUpperCase() === 'MATCHED').length;
      
      setStats({
        users: usersData.length,
        categories: categoriesData.length,
        services: servicesData.length,
        activeRequests: matched 
      });

      setServices(servicesData);
      setCategories(categoriesData);
      
      // Últimos 5 usuarios registrados
      const lastFiveUsers = [...usersData].reverse().slice(0, 5);
      setRecentUsers(lastFiveUsers);

    } catch (error) {
      console.error("Error cargando métricas:", error);
      toast.error('Error al sincronizar datos del servidor');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
  }, []);

  useAutoRefresh(() => loadDashboardData(), 90000);

  // 📈 Preparación de datos para la gráfica circular
  const chartData = useMemo(() => [
    { name: 'Abiertos', value: services.filter(s => (s.status || '').toUpperCase() === 'OPEN').length, color: '#60a5fa' },
    { name: 'En Proceso', value: services.filter(s => (s.status || '').toUpperCase() === 'MATCHED').length, color: '#fb7185' },
    { name: 'Terminados', value: services.filter(s => (s.status || '').toUpperCase() === 'COMPLETED').length, color: '#34d399' },
  ], [services]);

  const categoryDemandData = useMemo(() => {
  if (services.length === 0 || categories.length === 0) return [];

  // Contamos servicios por categoryId
  const counts: Record<string, number> = {};
  services.forEach(s => {
    counts[s.categoryId] = (counts[s.categoryId] || 0) + 1;
  });

  // Mapeamos a nombres reales y ordenamos de mayor a menor
  return categories
    .map(cat => ({
      name: cat.name,
      value: counts[cat.id] || 0
    }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 6); // Mostramos solo las 6 más populares
}, [services, categories]);

  // --- COMPONENTE INTERNO: TARJETA DE KPI ---
  const StatCard = ({ title, value, icon, trend, colorClass }: any) => (
    <div className="relative overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm group hover:border-slate-700 transition-all duration-300">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-slate-400">{title}</p>
          <h3 className="mt-2 text-3xl font-bold text-white">
            {isLoading ? <span className="inline-block h-8 w-16 animate-pulse rounded bg-slate-800"></span> : value}
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
        <span className="ml-2 text-slate-500">tendencia actual</span>
      </div>
    </div>
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-500 pb-10">
      
      {/* 1. ENCABEZADO */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight">Panel de Control</h2>
        <p className="text-sm text-slate-400 mt-1">Análisis en tiempo real de Ciudad Hidalgo.</p>
      </div>

      {/* 2. GRID DE KPIs (Métricas Principales) */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Usuarios Totales" value={counts.total_users || stats.users} trend="+12%" colorClass="text-blue-400" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>} />
        <StatCard title="Categorías" value={stats.categories} trend="Estable" colorClass="text-emerald-400" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>} />
        <StatCard title="Servicios Totales" value={stats.services} trend="+28%" colorClass="text-indigo-400" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M15 18a3 3 0 1 0-6 0"/><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2-2h12a2 2 0 0 0 2-2V7z"/><circle cx="12" cy="13" r="2"/></svg>} />
        <StatCard title="En Proceso (Match)" value={stats.activeRequests} trend="En curso" colorClass="text-rose-400" icon={<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>} />
      </div>

      {/* 3. PENDIENTES DE MODERACIÓN */}
      <div>
        <h3 className="text-lg font-bold text-white mb-4">Pendientes de Moderación</h3>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <div className="relative overflow-hidden rounded-2xl border border-red-500/20 bg-red-500/5 p-6 backdrop-blur-sm group hover:border-red-500/40 transition-all">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-400">Disputas Activas</p>
                <h3 className="mt-2 text-3xl font-bold text-red-400">
                  {counts.disputes}
                </h3>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-red-500/10 text-red-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><line x1="12" x2="12" y1="7" y2="13"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>
              </div>
            </div>
            <a href="/disputes" className="mt-4 flex items-center text-sm font-medium text-red-400 hover:text-red-300 transition-colors">
              Ver disputas
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="ml-1"><path d="m9 18 6-6-6-6"/></svg>
            </a>
          </div>

          <div className="relative overflow-hidden rounded-2xl border border-amber-500/20 bg-amber-500/5 p-6 backdrop-blur-sm group hover:border-amber-500/40 transition-all">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-400">Verificaciones Pendientes</p>
                <h3 className="mt-2 text-3xl font-bold text-amber-400">
                  {counts.verifications}
                </h3>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-500/10 text-amber-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>
              </div>
            </div>
            <a href="/verifications" className="mt-4 flex items-center text-sm font-medium text-amber-400 hover:text-amber-300 transition-colors">
              Ver verificaciones
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="ml-1"><path d="m9 18 6-6-6-6"/></svg>
            </a>
          </div>

          <div className="relative overflow-hidden rounded-2xl border border-orange-500/20 bg-orange-500/5 p-6 backdrop-blur-sm group hover:border-orange-500/40 transition-all">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-400">Reportes Pendientes</p>
                <h3 className="mt-2 text-3xl font-bold text-orange-400">
                  {counts.reports}
                </h3>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-orange-500/10 text-orange-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/></svg>
              </div>
            </div>
            <a href="/reports" className="mt-4 flex items-center text-sm font-medium text-orange-400 hover:text-orange-300 transition-colors">
              Ver reportes
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="ml-1"><path d="m9 18 6-6-6-6"/></svg>
            </a>
          </div>

          <div className="relative overflow-hidden rounded-2xl border border-rose-500/20 bg-rose-500/5 p-6 backdrop-blur-sm group hover:border-rose-500/40 transition-all">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-400">Servicios Reportados</p>
                <h3 className="mt-2 text-3xl font-bold text-rose-400">
                  {counts.reported_services}
                </h3>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-rose-500/10 text-rose-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="m9 12 2 2 4-4"/></svg>
              </div>
            </div>
            <a href="/reported-services" className="mt-4 flex items-center text-sm font-medium text-rose-400 hover:text-rose-300 transition-colors">
              Ver servicios reportados
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="ml-1"><path d="m9 18 6-6-6-6"/></svg>
            </a>
          </div>
        </div>
      </div>

      {/* 4. SECCIÓN DE ANÁLISIS VISUAL Y USUARIOS */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* GRÁFICA DE DISTRIBUCIÓN (1/3) */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <h3 className="text-lg font-bold text-white mb-6">Estado de Servicios</h3>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={chartData}
                  innerRadius={70}
                  outerRadius={90}
                  paddingAngle={8}
                  dataKey="value"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} stroke="transparent" />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px', fontSize: '12px',boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.5)'}}
                  itemStyle={{ color: '#ffffff' }}
                />
                <Legend iconType="circle" wrapperStyle={{ paddingTop: '20px' }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/*SECCIÓN DE DEMANDA POR CATEGORÍA */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h3 className="text-lg font-bold text-white tracking-tight">Demanda por Categoría</h3>
            </div>
            <div className="h-10 w-10 rounded-xl bg-indigo-500/10 flex items-center justify-center text-indigo-400">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/></svg>
            </div>
          </div>

          <div className="h-[350px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={categoryDemandData}
                layout="vertical"
                margin={{ top: 5, right: 30, left: 40, bottom: 5 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" horizontal={false} />
                <XAxis type="number" hide />
                <YAxis 
                  dataKey="name" 
                  type="category" 
                  stroke="#94a3b8" 
                  fontSize={12} 
                  width={100}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip
                  cursor={{ fill: '#1e293b', opacity: 0.4 }}
                  contentStyle={{ 
                    backgroundColor: '#0f172a', 
                    border: '1px solid #334155', 
                    borderRadius: '12px',
                    color: '#fff' 
                  }}
                  itemStyle={{ color: '#818cf8' }}
                />
                <Bar 
                  dataKey="value" 
                  fill="#818cf8" 
                  radius={[0, 4, 4, 0]} 
                  barSize={24}
                  // Animación para que se vea pro al cargar
                  animationDuration={1500}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* TABLA DE USUARIOS RECIENTES (2/3) */}
        <div className="lg:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-white tracking-tight">Nuevos Miembros</h3>
            <button className="text-sm text-indigo-400 hover:text-indigo-300 font-medium transition-colors">
              Ver base completa
            </button>
          </div>

          {isLoading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4].map(i => (
                <div key={i} className="flex items-center gap-4 animate-pulse">
                  <div className="h-10 w-10 rounded-full bg-slate-800"></div>
                  <div className="h-4 w-full rounded bg-slate-800"></div>
                </div>
              ))}
            </div>
          ) : (
            <div className="divide-y divide-slate-800/60">
              {recentUsers.map((user) => (
                <div key={user.id} className="flex items-center justify-between py-4 group hover:bg-white/[0.02] px-2 rounded-lg transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-full bg-indigo-500/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400 font-bold">
                      {user.avatarUrl ? (
                        <img src={user.avatarUrl} className="h-full w-full object-cover rounded-full" alt="avatar" />
                      ) : user.full_name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h4 className="text-sm font-semibold text-slate-200">{user.full_name}</h4>
                      <p className="text-xs text-slate-500">{user.email}</p>
                    </div>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${
                    user.role === 'admin' ? 'bg-rose-500/10 text-rose-400 border-rose-500/20' :
                    user.role === 'worker' ? 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20' :
                    'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                  }`}>
                    {user.role}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* 5. SECCIÓN INFERIOR DE ACCESO RÁPIDO */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="rounded-2xl border border-slate-800 bg-indigo-600/10 p-6 border-dashed flex items-center gap-6">
          <div className="h-14 w-14 rounded-2xl bg-indigo-500/20 flex items-center justify-center text-indigo-400">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
          </div>
          <div>
            <h4 className="text-white font-bold">Mantenimiento de Categorías</h4>
            <p className="text-sm text-slate-400">Añade o edita los oficios disponibles en la plataforma.</p>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-emerald-600/10 p-6 border-dashed flex items-center gap-6">
          <div className="h-14 w-14 rounded-2xl bg-emerald-500/20 flex items-center justify-center text-emerald-400">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="3" y2="15"/></svg>
          </div>
          <div>
            <h4 className="text-white font-bold">Exportar Reportes</h4>
            <p className="text-sm text-slate-400">Genera un CSV con el historial de servicios terminados.</p>
          </div>
        </div>
      </div>

    </div>
  );
};