import { Outlet, NavLink, useLocation, Navigate } from 'react-router-dom';
import { useState,useEffect } from 'react';
import { Toaster } from 'sonner';
import { UserMenu } from './UserMenu';
import { NotificationPanel } from '../components/NotificationPanel';
import { usePendingCounts } from '../hooks/usePendingCounts';

// 1. Movimos los navItems afuera del componente (Mejor rendimiento)
const navItems = [
  { 
    name: 'Dashboard', 
    path: '/', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="9" x="3" y="3" rx="1" /><rect width="7" height="5" x="14" y="3" rx="1" /><rect width="7" height="9" x="14" y="12" rx="1" /><rect width="7" height="5" x="3" y="16" rx="1" /></svg>
  },
  { 
    name: 'Usuarios', 
    path: '/users', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
  },
  { 
    name: 'Categorías', 
    path: '/categories', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="7" x="3" y="3" rx="1" /><rect width="7" height="7" x="14" y="3" rx="1" /><rect width="7" height="7" x="14" y="14" rx="1" /><rect width="7" height="7" x="3" y="14" rx="1" /></svg>
  },
  { 
    name: 'Servicios', 
    path: '/services', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
  },
  { 
    name: 'Servicios Reportados', 
    path: '/reported-services', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/></svg>
  },
  {
    name: 'Disputas',
    path: '/disputes',
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><line x1="12" x2="12" y1="7" y2="13"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>
  },
  { 
    name: 'Finanzas', 
    path: '/finance', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline></svg>
  },
  { 
    name: 'Verificaciones', 
    path: '/verifications', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>
  },
  { 
    name: 'Reportes', 
    path: '/reports', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/></svg>
  },
];

// Componente de navegación reutilizable (Desktop + Mobile)
const SidebarNav = ({ onNavClick, counts }: { onNavClick?: () => void; counts: Record<string, number> }) => {
  const location = useLocation();
  return (
    <nav className="flex-1 space-y-1 px-4 py-6">
      {navItems.map((item) => {
        const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
        const pendingCount = counts[item.path] || 0;
        return (
          <NavLink
            key={item.path}
            to={item.path}
            onClick={onNavClick}
            className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all ${
              isActive
                ? 'bg-indigo-600/10 text-indigo-400 shadow-sm ring-1 ring-indigo-500/20'
                : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
            }`}
          >
            <span className={`transition-colors ${isActive ? 'text-indigo-400' : 'text-slate-500 group-hover:text-slate-300'}`}>
              {item.icon}
            </span>
            <span className="flex-1">{item.name}</span>
            {pendingCount > 0 && (
              <span className="ml-auto bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full min-w-[1.25rem] text-center">
                {pendingCount}
              </span>
            )}
          </NavLink>
        );
      })}
    </nav>
  );
};

// Logo reutilizable
const SidebarLogo = () => (
  <div className="flex h-16 items-center border-b border-slate-800 px-6">
    <div className="flex items-center gap-3">
      <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-white shadow-lg shadow-indigo-500/20">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/></svg>
      </div>
      <span className="text-lg font-bold tracking-tight text-white">
        Forja<span className="text-indigo-400">Trabajo</span>
      </span>
    </div>
  </div>
);

export const AdminLayout = () => {
  const location = useLocation();
  const { counts } = usePendingCounts();

  //Auth Guard: si no hay token, redirigir al login
  const token = localStorage.getItem('token');
  if (!token) {
    return <Navigate to="/login" replace />;
  }

  //Estado del sidebar móvil
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Leemos el estado de mantenimiento
  const [isMaintenanceActive, setIsMaintenanceActive] = useState(
    JSON.parse(localStorage.getItem('maintenance_mode') || 'false')
  );

  useEffect(() => {
    const updateMaintenanceState = () => {
      setIsMaintenanceActive(JSON.parse(localStorage.getItem('maintenance_mode') || 'false'));
    };
    window.addEventListener('maintenance_changed', updateMaintenanceState);
    return () => window.removeEventListener('maintenance_changed', updateMaintenanceState);
  }, []);

  // Cerrar menú móvil al cambiar de ruta
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [location.pathname]);

  return (
    <div className="flex flex-col h-screen bg-slate-950 text-slate-200 font-sans selection:bg-indigo-500/30">
      
      {/* 🚩 BANNER DE MANTENIMIENTO */}
      {isMaintenanceActive && (
        <div className="shrink-0 bg-amber-500/10 border-b border-amber-500/20 py-2 px-4 flex items-center justify-center gap-2 animate-pulse">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" className="text-amber-500"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
          <span className="text-xs font-black text-amber-500 uppercase tracking-widest">
            Modo Mantenimiento Activo
          </span>
        </div>
      )}

      {/* --- ESTRUCTURA PRINCIPAL (Sidebar + Main) --- */}
      <div className="flex flex-1 overflow-hidden">
        
        {/* 📱 OVERLAY MÓVIL (Backdrop oscuro) */}
        {isMobileMenuOpen && (
          <div 
            className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm md:hidden transition-opacity"
            onClick={() => setIsMobileMenuOpen(false)}
          />
        )}

        {/* 📱 SIDEBAR MÓVIL (Drawer) */}
        <aside className={`fixed inset-y-0 left-0 z-50 w-64 flex-col border-r border-slate-800 bg-slate-900 transform transition-transform duration-300 ease-in-out md:hidden ${
          isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
        } flex`}>
          <div className="flex items-center justify-between border-b border-slate-800 px-6 h-16">
            <div className="flex items-center gap-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-white shadow-lg shadow-indigo-500/20">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/></svg>
              </div>
              <span className="text-lg font-bold tracking-tight text-white">
                Forja<span className="text-indigo-400">Trabajo</span>
              </span>
            </div>
            {/* Botón X para cerrar */}
            <button 
              onClick={() => setIsMobileMenuOpen(false)}
              className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
          </div>
          <SidebarNav onNavClick={() => setIsMobileMenuOpen(false)} counts={{
            '/disputes': counts.disputes,
            '/verifications': counts.verifications,
            '/reports': counts.reports,
            '/reported-services': counts.reported_services,
          }} />
        </aside>

        {/*IDEBAR DESKTOP*/}
        <aside className="hidden w-64 flex-col border-r border-slate-800 bg-slate-900/50 backdrop-blur-xl md:flex">
          <SidebarLogo />
          <SidebarNav counts={{
            '/disputes': counts.disputes,
            '/verifications': counts.verifications,
            '/reports': counts.reports,
            '/reported-services': counts.reported_services,
          }} />
        </aside>

        {/* MAIN CONTENT AREA */}
        <div className="flex flex-1 flex-col overflow-hidden">
          <header className="relative z-30 flex h-16 shrink-0 items-center justify-between border-b border-slate-800 bg-slate-900/50 px-4 md:px-8 backdrop-blur-md">
            <div className="flex items-center gap-3">
              {/*BOTÓN HAMBURGUESA (solo en móvil) */}
              <button 
                onClick={() => setIsMobileMenuOpen(true)}
                className="rounded-lg p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors md:hidden"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>
              </button>
              
              <div className="flex items-center text-sm text-slate-500">
                <span className="mr-2 hidden sm:inline">Panel</span>
                <span className="mx-2 hidden sm:inline">/</span>
                <span className="font-medium text-slate-200 capitalize">
                  {location.pathname === '/' ? 'Dashboard' : location.pathname.split('/')[1]}
                </span>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <NotificationPanel />

              <div className="h-8 w-px bg-slate-800 mx-2"></div>
              <UserMenu />
            </div>
          </header>

          <main className="flex-1 overflow-y-auto bg-slate-950 p-4 md:p-8 scrollbar-thin scrollbar-track-slate-900 scrollbar-thumb-slate-700">
            <Outlet />
          </main>
        </div>
      </div>

      {/* --- GLOBAL TOASTER --- */}
      <Toaster 
        position="top-right" 
        theme="dark" 
        richColors 
        closeButton
        className="font-sans"
        toastOptions={{
          classNames: {
            title: 'text-sm font-semibold',
            description: 'text-xs text-slate-400',
            actionButton: 'bg-indigo-600',
            cancelButton: 'bg-slate-700',
          },
        }}
      />
    </div>
  );
};