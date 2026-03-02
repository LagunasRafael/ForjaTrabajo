import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useState,useEffect } from 'react';
import { Toaster } from 'sonner';
import { UserMenu } from './UserMenu';

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
    name: 'Empresas', 
    path: '/companies', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 21c3 0 7-1 7-8V5c0-1.25-.756-2.017-2-2H4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/><path d="M15 21c3 0 7-1 7-8V5c0-1.25-.757-2.017-2-2h-4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/></svg>
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
    name: 'Finanzas', 
    path: '/finance', 
    icon: <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline></svg>
  },
];

export const AdminLayout = () => {
  const location = useLocation();
  // Leemos el estado de mantenimiento
  const [isMaintenanceActive, setIsMaintenanceActive] = useState(
  JSON.parse(localStorage.getItem('maintenance_mode') || 'false')
);

useEffect(() => {
  // Función que actualiza el estado cuando escucha el evento
  const updateMaintenanceState = () => {
    setIsMaintenanceActive(JSON.parse(localStorage.getItem('maintenance_mode') || 'false'));
  };

  // Ponemos a React a escuchar nuestro evento personalizado
  window.addEventListener('maintenance_changed', updateMaintenanceState);
  
  // Limpieza al desmontar
  return () => window.removeEventListener('maintenance_changed', updateMaintenanceState);
}, []);

  // 2. Usamos UN SOLO return con la estructura correcta
  return (
    <div className="flex flex-col h-screen bg-slate-950 text-slate-200 font-sans selection:bg-indigo-500/30">
      
      {/* 🚩 BANNER DE MANTENIMIENTO (Ocupa el ancho completo arriba) */}
      {isMaintenanceActive && (
        <div className="shrink-0 bg-amber-500/10 border-b border-amber-500/20 py-2 px-4 flex items-center justify-center gap-2 animate-pulse">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" className="text-amber-500"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
          <span className="text-xs font-black text-amber-500 uppercase tracking-widest">
            Modo Mantenimiento Activo
          </span>
        </div>
      )}

      {/* --- ESTRUCTURA PRINCIPAL DIVIDIDA (Sidebar + Main) --- */}
      <div className="flex flex-1 overflow-hidden">
        
        {/* SIDEBAR */}
        <aside className="hidden w-64 flex-col border-r border-slate-800 bg-slate-900/50 backdrop-blur-xl md:flex">
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

          <nav className="flex-1 space-y-1 px-4 py-6">
            {navItems.map((item) => {
              const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-indigo-600/10 text-indigo-400 shadow-sm ring-1 ring-indigo-500/20'
                      : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                  }`}
                >
                  <span className={`transition-colors ${isActive ? 'text-indigo-400' : 'text-slate-500 group-hover:text-slate-300'}`}>
                    {item.icon}
                  </span>
                  {item.name}
                </NavLink>
              );
            })}
          </nav>
        </aside>

        {/* MAIN CONTENT AREA */}
        <div className="flex flex-1 flex-col overflow-hidden">
          <header className="relative z-50 flex h-16 shrink-0 items-center justify-between border-b border-slate-800 bg-slate-900/50 px-8 backdrop-blur-md">
            <div className="flex items-center text-sm text-slate-500">
              <span className="mr-2">Panel</span>
              <span className="mx-2">/</span>
              <span className="font-medium text-slate-200 capitalize">
                {location.pathname === '/' ? 'Dashboard' : location.pathname.split('/')[1]}
              </span>
            </div>
            
            <div className="flex items-center gap-4">
              <button className="relative rounded-full p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors">
                <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-indigo-500 ring-2 ring-slate-900"></span>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
              </button>

              <div className="h-8 w-px bg-slate-800 mx-2"></div>
              <UserMenu />
            </div>
          </header>

          <main className="flex-1 overflow-y-auto bg-slate-950 p-8 scrollbar-thin scrollbar-track-slate-900 scrollbar-thumb-slate-700">
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