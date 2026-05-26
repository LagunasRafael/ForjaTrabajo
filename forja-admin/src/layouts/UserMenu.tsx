import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

export const UserMenu = () => {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  // 1. LEER DATOS DEL USUARIO
  const userString = localStorage.getItem('user');
  const user = userString ? JSON.parse(userString) : { full_name: 'Usuario', email: '...' };

  // 2. FUNCIÓN DE CERRAR SESIÓN
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  // 3. CERRAR AL HACER CLICK AFUERA
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // --- RENDERIZADO ---
  return (
    <div className="relative" ref={menuRef}>
      
      {/* BOTÓN PRINCIPAL (FOTO Y NOMBRE) */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-3 rounded-lg p-1 hover:bg-slate-800/50 transition-colors focus:outline-none"
      >
        {/* 👇 AQUÍ ESTÁ LA MAGIA DEL AVATAR 👇 */}
        {user.profile_picture_url ? (
          <img 
            src={user.profile_picture_url} 
            alt={`Perfil de ${user.full_name}`} 
            className="h-8 w-8 rounded-full ring-2 ring-slate-800 object-cover bg-slate-800"
          />
        ) : (
          <img 
            src={`https://ui-avatars.com/api/?name=${user.full_name || 'U'}&background=4f46e5&color=fff`} 
            alt="Avatar por defecto" 
            className="h-8 w-8 rounded-full ring-2 ring-slate-800"
          />
        )}
        {/* 👆 FIN DE LA MAGIA 👆 */}

        <div className="hidden flex-col items-start md:flex">
          <span className="text-sm font-medium text-slate-200">
            {user.full_name || "Usuario"}
          </span>
          <svg className={`h-4 w-4 text-slate-500 transition-transform ${isOpen ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </button>

      {/* MENÚ DESPLEGABLE */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-56 origin-top-right rounded-xl border border-slate-800 bg-slate-900 p-2 shadow-2xl ring-1 ring-black ring-opacity-5 focus:outline-none z-[100]">
          
          {/* INFO DEL USUARIO */}
          <div className="px-3 py-2 border-b border-slate-800 mb-1">
            <p className="text-xs text-slate-500">Sesión iniciada como</p>
            <p className="text-sm font-medium text-slate-200 truncate" title={user.email}>
              {user.email}
            </p>
          </div>
          
          {/* OPCIONES DE MENÚ */}
          <button onClick={() => navigate('/profile')} className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            Mi Perfil
          </button>
          
          <button onClick={() => navigate('/settings')} className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.1a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.1a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
            Configuración
          </button>

          <div className="my-1 border-t border-slate-800"></div>

          {/* BOTÓN DE LOGOUT */}
          <button 
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-rose-400 hover:bg-rose-500/10 transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
            Cerrar Sesión
          </button>
        </div>
      )}
    </div>
  );
};