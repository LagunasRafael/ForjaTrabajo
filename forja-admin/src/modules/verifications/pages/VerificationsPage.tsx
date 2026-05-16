import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { Check, X, User, AlertTriangle } from 'lucide-react';
import api from '../../../api/client';

interface Verification {
  id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  ine_front_url: string;
  ine_back_url: string;
  selfie_url: string;
  status: string;
  face_similarity: number | null;
  created_at: string;
}

export const VerificationsPage = () => {
  const [verifications, setVerifications] = useState<Verification[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<Verification | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showReject, setShowReject] = useState(false);

  const loadVerifications = async () => {
    try {
      setLoading(true);
      const { data } = await api.get('/auth/admin/verifications');
      setVerifications(data);
    } catch (e) {
      toast.error('Error al cargar verificaciones');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadVerifications();
  }, []);

  const handleApprove = async (id: string) => {
    try {
      await api.post(`/auth/admin/verifications/${id}/approve`);
      toast.success('Verificación aprobada');
      setSelected(null);
      loadVerifications();
    } catch (e) {
      toast.error('Error al aprobar');
    }
  };

  const handleReject = async (id: string) => {
    if (!rejectReason.trim()) {
      toast.error('Escribe un motivo de rechazo');
      return;
    }
    try {
      await api.post(`/auth/admin/verifications/${id}/reject`, { reason: rejectReason });
      toast.success('Verificación rechazada');
      setSelected(null);
      setShowReject(false);
      setRejectReason('');
      loadVerifications();
    } catch (e) {
      toast.error('Error al rechazar');
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Verificaciones de Identidad</h2>
          <p className="text-slate-400 text-sm mt-1">Revisión de INE y selfies pendientes</p>
        </div>
        <button
          onClick={loadVerifications}
          className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-sm transition-all"
        >
          Refrescar
        </button>
      </div>

      {loading ? (
        <div className="p-20 text-center text-slate-500 animate-pulse">Cargando verificaciones...</div>
      ) : verifications.length === 0 ? (
        <div className="p-20 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-2xl">
          No hay verificaciones pendientes
        </div>
      ) : selected ? (
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 space-y-6">
          <button
            onClick={() => { setSelected(null); setShowReject(false); }}
            className="text-slate-400 hover:text-white text-sm"
          >
            ← Volver a la lista
          </button>

          <div className="flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-indigo-500/20 flex items-center justify-center">
              <User size={24} className="text-indigo-400" />
            </div>
            <div>
              <p className="text-lg font-bold text-white">{selected.user_name}</p>
              <p className="text-sm text-slate-400">{selected.user_email}</p>
            </div>
            {selected.face_similarity != null && (
              <div className="ml-auto">
                <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                  selected.face_similarity >= 95 ? 'bg-emerald-500/20 text-emerald-400' :
                  selected.face_similarity >= 80 ? 'bg-amber-500/20 text-amber-400' :
                  'bg-rose-500/20 text-rose-400'
                }`}>
                  Similitud: {selected.face_similarity.toFixed(1)}%
                </span>
              </div>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <p className="text-xs text-slate-500 uppercase tracking-wider mb-2">INE Frente</p>
              <img src={selected.ine_front_url} alt="INE Frente" className="w-full rounded-lg border border-slate-700" />
            </div>
            <div>
              <p className="text-xs text-slate-500 uppercase tracking-wider mb-2">INE Reverso</p>
              <img src={selected.ine_back_url} alt="INE Reverso" className="w-full rounded-lg border border-slate-700" />
            </div>
            <div>
              <p className="text-xs text-slate-500 uppercase tracking-wider mb-2">Selfie</p>
              <img src={selected.selfie_url} alt="Selfie" className="w-full rounded-lg border border-slate-700" />
            </div>
          </div>

          {showReject ? (
            <div className="space-y-3">
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Motivo del rechazo..."
                className="w-full p-3 bg-slate-800 border border-slate-700 rounded-lg text-white text-sm resize-none"
                rows={3}
              />
              <div className="flex gap-3">
                <button
                  onClick={() => handleReject(selected.id)}
                  className="px-6 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-sm font-bold transition-all"
                >
                  Confirmar Rechazo
                </button>
                <button
                  onClick={() => { setShowReject(false); setRejectReason(''); }}
                  className="px-4 py-2 bg-slate-700 text-white rounded-lg text-sm"
                >
                  Cancelar
                </button>
              </div>
            </div>
          ) : (
            <div className="flex gap-3">
              <button
                onClick={() => handleApprove(selected.id)}
                className="flex items-center gap-2 px-6 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-sm font-bold transition-all"
              >
                <Check size={16} /> Aprobar
              </button>
              <button
                onClick={() => setShowReject(true)}
                className="flex items-center gap-2 px-6 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-sm font-bold transition-all"
              >
                <X size={16} /> Rechazar
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="grid gap-4">
          {verifications.map((v) => (
            <div
              key={v.id}
              onClick={() => setSelected(v)}
              className="p-4 rounded-xl border border-slate-800 bg-slate-900/40 hover:border-indigo-500/30 cursor-pointer transition-all"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <User size={20} className="text-slate-500" />
                  <div>
                    <p className="text-sm font-bold text-white">{v.user_name}</p>
                    <p className="text-xs text-slate-400">{v.user_email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  {v.face_similarity != null && (
                    <span className={`text-xs font-bold ${
                      v.face_similarity >= 95 ? 'text-emerald-400' : v.face_similarity >= 80 ? 'text-amber-400' : 'text-rose-400'
                    }`}>
                      {v.face_similarity.toFixed(0)}%
                    </span>
                  )}
                  <span className="text-xs text-slate-500">
                    {new Date(v.created_at).toLocaleDateString()}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
