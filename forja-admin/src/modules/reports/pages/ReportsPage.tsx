import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { getReportsApi, getReportDetailApi, resolveReportApi } from '../services/reports.service';
import type { Report } from '../types/report.types';
import { useAutoRefresh } from '../../../hooks/useAutoRefresh';
import { ConfirmModal } from '../../../components/ConfirmModal';

const reasonLabels: Record<string, string> = {
  spam: 'Spam',
  inappropriate_content: 'Contenido inapropiado',
  scam: 'Estafa',
  harassment: 'Acoso',
  fake_profile: 'Perfil falso',
  other: 'Otro',
};

const statusBadge = (status: string) => {
  const map: Record<string, { label: string; cls: string }> = {
    pending: { label: 'Pendiente', cls: 'bg-amber-500/10 text-amber-400 ring-amber-500/20' },
    resolved_banned: { label: 'Usuario baneado', cls: 'bg-red-500/10 text-red-400 ring-red-500/20' },
    resolved_service_banned: { label: 'Servicio desactivado', cls: 'bg-orange-500/10 text-orange-400 ring-orange-500/20' },
    dismissed: { label: 'Desestimado', cls: 'bg-slate-500/10 text-slate-400 ring-slate-500/20' },
  };
  const b = map[status] ?? { label: status, cls: 'bg-slate-500/10 text-slate-400 ring-slate-500/20' };
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${b.cls}`}>
      {b.label}
    </span>
  );
};

export const ReportsPage = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState('pending');
  const [selected, setSelected] = useState<Report | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [isResolving, setIsResolving] = useState(false);
  const [confirmAction, setConfirmAction] = useState<'ban_user' | 'ban_service' | 'dismiss' | null>(null);

  useEffect(() => { loadReports(); }, [filter]);

  useAutoRefresh(() => loadReports(), 30000);

  const loadReports = async () => {
    setIsLoading(true);
    try {
      const data = await getReportsApi(filter === 'all' ? undefined : filter);
      setReports(data);
      setSelected(null);
    } catch {
      toast.error('Error al cargar reportes');
    } finally {
      setIsLoading(false);
    }
  };

  const openDetail = async (id: string) => {
    try {
      const detail = await getReportDetailApi(id);
      setSelected(detail);
      setAdminNote('');
    } catch {
      toast.error('Error al cargar detalle');
    }
  };

  const handleResolve = async () => {
    if (!selected || !confirmAction) return;

    setIsResolving(true);
    try {
      await resolveReportApi(selected.id, {
        action: confirmAction,
        admin_note: adminNote || undefined,
      });
      toast.success('Reporte resuelto');
      setSelected(null);
      setConfirmAction(null);
      loadReports();
    } catch {
      toast.error('Error al resolver reporte');
    } finally {
      setIsResolving(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Reportes</h2>
          <p className="text-sm text-slate-400 mt-1">Revisa los reportes de usuarios y servicios.</p>
        </div>
        <div className="flex gap-2 flex-wrap">
          {['pending', 'resolved_banned', 'resolved_service_banned', 'dismissed', 'all'].map((s) => (
            <button
              key={s}
              onClick={() => setFilter(s)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                filter === s
                  ? 'bg-indigo-600 text-white'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              {s === 'all' ? 'Todos' : statusBadge(s).props.className ? (
                s === 'pending' ? 'Pendientes' :
                s === 'resolved_banned' ? 'Baneados' :
                s === 'resolved_service_banned' ? 'Serv. desact.' :
                'Desestimados'
              ) : s}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className={`${selected ? 'lg:col-span-1' : 'lg:col-span-3'} rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm overflow-hidden shadow-xl`}>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="border-b border-slate-800 bg-slate-900/50 text-xs uppercase text-slate-400">
                <tr>
                  <th className="px-6 py-4 font-semibold">Reportante</th>
                  <th className="px-6 py-4 font-semibold">Reportado</th>
                  <th className="px-6 py-4 font-semibold">Motivo</th>
                  <th className="px-6 py-4 font-semibold">Estado</th>
                  <th className="px-6 py-4 font-semibold text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {isLoading ? (
                  <tr><td colSpan={5} className="px-6 py-12 text-center text-slate-500 animate-pulse">Cargando...</td></tr>
                ) : reports.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-12 text-center text-slate-500">No hay reportes.</td></tr>
                ) : (
                  reports.map((r) => (
                    <tr key={r.id} className={`transition-colors cursor-pointer hover:bg-slate-800/30 ${selected?.id === r.id ? 'bg-indigo-900/20 ring-1 ring-inset ring-indigo-500/30' : ''}`}
                      onClick={() => openDetail(r.id)}>
                      <td className="px-6 py-4 font-medium text-slate-200">{r.reporter_name}</td>
                      <td className="px-6 py-4">{r.reported_user_name ?? '—'}</td>
                      <td className="px-6 py-4">{reasonLabels[r.reason] ?? r.reason}</td>
                      <td className="px-6 py-4">{statusBadge(r.status)}</td>
                      <td className="px-6 py-4 text-right">
                        <span className="text-indigo-400 hover:text-indigo-300 text-sm font-medium transition-colors">
                          Ver &rarr;
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {selected && (
          <div className="lg:col-span-2 rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm p-6 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white">Detalle del Reporte</h3>
              <button onClick={() => setSelected(null)} className="text-slate-400 hover:text-white text-sm">Cerrar &times;</button>
            </div>

            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-slate-400">Reportante:</span>
                <p className="text-slate-200 font-medium">{selected.reporter_name}</p>
              </div>
              <div>
                <span className="text-slate-400">Reportado:</span>
                <p className="text-slate-200 font-medium">{selected.reported_user_name ?? '—'}</p>
              </div>
              <div>
                <span className="text-slate-400">Motivo:</span>
                <p className="text-slate-200 font-medium">{reasonLabels[selected.reason] ?? selected.reason}</p>
              </div>
              <div>
                <span className="text-slate-400">Estado:</span>
                <p>{statusBadge(selected.status)}</p>
              </div>
              <div>
                <span className="text-slate-400">Fecha:</span>
                <p className="text-slate-200">{new Date(selected.created_at).toLocaleString('es-MX')}</p>
              </div>
              {selected.admin_name && (
                <div>
                  <span className="text-slate-400">Resuelto por:</span>
                  <p className="text-slate-200">{selected.admin_name}</p>
                </div>
              )}
            </div>

            {selected.description && (
              <div>
                <span className="text-slate-400 text-sm">Descripción del reportante:</span>
                <p className="text-slate-300 mt-1 bg-slate-800/50 p-3 rounded-lg">{selected.description}</p>
              </div>
            )}

            {selected.service && (
              <div className="bg-slate-800/50 p-4 rounded-lg space-y-2">
                <h4 className="text-white font-semibold text-sm">Servicio reportado</h4>
                <p className="text-slate-200 font-medium">{selected.service.title}</p>
                <p className="text-slate-400 text-xs line-clamp-2">{selected.service.description}</p>
                <span className={`inline-flex text-xs font-medium px-2 py-0.5 rounded ${selected.service.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-red-500/20 text-red-400'}`}>
                  {selected.service.is_active ? 'Activo' : 'Desactivado'}
                </span>
              </div>
            )}

            {selected.status === 'pending' && (
              <div className="space-y-3 pt-2 border-t border-slate-800">
                <textarea
                  value={adminNote}
                  onChange={(e) => setAdminNote(e.target.value)}
                  placeholder="Nota del admin (opcional)..."
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg p-3 text-sm text-slate-200 placeholder-slate-500 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  rows={2}
                />
                <div className="flex gap-3 flex-wrap">
                  <button
                    disabled={isResolving}
                    onClick={() => setConfirmAction('ban_user')}
                    className="px-4 py-2 bg-red-600 hover:bg-red-500 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition-colors"
                  >
                    Banear usuario
                  </button>
                  {selected.reported_service_id && (
                    <button
                      disabled={isResolving}
                      onClick={() => setConfirmAction('ban_service')}
                      className="px-4 py-2 bg-orange-600 hover:bg-orange-500 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition-colors"
                    >
                      Desactivar servicio
                    </button>
                  )}
                  <button
                    disabled={isResolving}
                    onClick={() => setConfirmAction('dismiss')}
                    className="px-4 py-2 bg-slate-600 hover:bg-slate-500 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition-colors"
                  >
                    Desestimar
                  </button>
                </div>
              </div>
            )}

            {selected.admin_note && (
              <div className="pt-2 border-t border-slate-800">
                <span className="text-slate-400 text-sm">Nota del admin:</span>
                <p className="text-slate-300 mt-1">{selected.admin_note}</p>
              </div>
            )}
          </div>
        )}

        <ConfirmModal
          isOpen={confirmAction !== null}
          onClose={() => setConfirmAction(null)}
          onConfirm={handleResolve}
          title={
            confirmAction === 'ban_user' ? 'Banear usuario' :
            confirmAction === 'ban_service' ? 'Desactivar servicio' :
            'Desestimar reporte'
          }
          message={
            confirmAction === 'ban_user' ? '¿BANEAR al usuario reportado? Se desactivará su cuenta de forma permanente.' :
            confirmAction === 'ban_service' ? '¿DESACTIVAR el servicio reportado? Dejará de ser visible en la plataforma.' :
            '¿DESESTIMAR este reporte? No se tomará ninguna acción.'
          }
          confirmLabel={
            confirmAction === 'ban_user' ? 'Banear' :
            confirmAction === 'ban_service' ? 'Desactivar' :
            'Desestimar'
          }
          confirmClass={
            confirmAction === 'ban_user' ? 'bg-red-600 hover:bg-red-500' :
            confirmAction === 'ban_service' ? 'bg-orange-600 hover:bg-orange-500' :
            'bg-slate-600 hover:bg-slate-500'
          }
          isLoading={isResolving}
        />
      </div>
    </div>
  );
};

export default ReportsPage;
