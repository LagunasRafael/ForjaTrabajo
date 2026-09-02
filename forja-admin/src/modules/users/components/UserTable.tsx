import type { User } from '../types/user.types';
import { UserStatusBadge } from './UserStatusBadge';

interface UserTableProps {
  users: User[];
  isLoading: boolean;
  onEdit: (user: User) => void;
  onDelete: (userId: string) => void;
}

export const UserTable = ({ users, isLoading, onEdit, onDelete }: UserTableProps) => {
  if (isLoading) {
    return (
      <div className="w-full p-12 flex justify-center text-slate-500">
        <span className="animate-pulse">Cargando usuarios...</span>
      </div>
    );
  }

  return (
    // Contenedor "Card" con borde sutil
    <div className="w-full overflow-hidden rounded-lg border border-slate-800 bg-slate-900/40">
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm text-slate-400">
          <thead className="bg-slate-950/30 text-xs uppercase tracking-wider text-slate-500 font-medium">
            <tr>
              <th className="px-6 py-4">Usuario</th>
              <th className="px-6 py-4">Rol</th>
              <th className="px-6 py-4">Estado</th>
              <th className="px-6 py-4">Fecha Registro</th>
              <th className="px-6 py-4 text-right">Acciones</th>
            </tr>
          </thead>
          
          <tbody className="divide-y divide-slate-800/50">
            {users.map((user) => (
              <tr key={user.id} className="group hover:bg-slate-800/30 transition-colors">
                
                {/* Columna Usuario + Avatar */}
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="h-8 w-8 rounded-full bg-slate-800 flex items-center justify-center text-xs font-bold text-slate-300 ring-1 ring-slate-700 overflow-hidden">
                      {user.avatarUrl ? (
                        <img src={user.avatarUrl} alt="" className="h-full w-full rounded-full object-cover" />
                      ) : (
                        // --- CORRECCIÓN AQUÍ: Protección contra nulos ---
                        // Si no hay nombre, usa el email. Si no hay email, usa 'U'.
                        (user.full_name || user.email || "U").charAt(0).toUpperCase()
                      )}
                    </div>
                    <div className="flex flex-col">
                      {/* --- CORRECCIÓN AQUÍ: Fallback visual --- */}
                      <span className="text-slate-200 font-medium">
                        {user.full_name || "Sin nombre"} 
                      </span>
                      <span className="text-xs text-slate-500">{user.email}</span>
                    </div>
                  </div>
                </td>

                {/* Columna Rol */}
                <td className="px-6 py-4">
                  <span className="text-slate-300 bg-slate-800 px-2 py-1 rounded text-xs capitalize">
                    {user.role}
                  </span>
                </td>

                {/* Columna Estado */}
                <td className="px-6 py-4">
                  <UserStatusBadge status={user.status} />
                </td>

                {/* Columna Fecha */}
                <td className="px-6 py-4 text-xs font-mono text-slate-500">
                  {/* Protección extra por si createdAt viene nulo */}
                  {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : "-"}
                </td>

                {/* Acciones */}
                <td className="px-6 py-4 text-right">
                <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button 
                    onClick={() => onEdit(user)}
                    className="p-1.5 text-slate-400 hover:text-indigo-400 hover:bg-indigo-500/10 rounded transition-colors"
                    title="Editar"
                    >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path></svg>
                    </button>
                    
                    <button 
                    onClick={() => onDelete(user.id)}
                    className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded transition-colors"
                    title="Eliminar"
                    >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
                    </button>
                </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};