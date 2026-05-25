import type { UserStatus } from '../types/user.types';

const styles: Record<UserStatus, string> = {
  active: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  inactive: 'bg-slate-500/10 text-slate-400 border-slate-500/20',
  pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  banned: 'bg-red-500/10 text-red-400 border-red-500/20',
};

const labels: Record<UserStatus, string> = {
  active: 'Activo',
  inactive: 'Inactivo',
  pending: 'Pendiente',
  banned: 'Baneado',
};

export const UserStatusBadge = ({ status }: { status: UserStatus }) => {
  return (
    <span className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold tracking-wide border ${styles[status]}`}>
      {labels[status]}
    </span>
  );
};