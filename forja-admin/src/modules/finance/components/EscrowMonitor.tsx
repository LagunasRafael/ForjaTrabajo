import { EscrowItem } from '../types/finance.types';
import { processPendingTransfer } from '../services/finance.service';
import { toast } from 'sonner';

interface EscrowMonitorProps {
  items: EscrowItem[];
  isLoading: boolean;
  onRefresh: () => void;
}

export const EscrowMonitor = ({ items, isLoading, onRefresh }: EscrowMonitorProps) => {
  const formatMXN = (val: number) =>
    new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });

  const handleProcessTransfer = async (paymentId: string) => {
    try {
      await processPendingTransfer(paymentId);
      toast.success('Transferencia procesada correctamente');
      onRefresh();
    } catch (error) {
      toast.error('Error al procesar la transferencia');
    }
  };

  const heldInEscrow = items.filter(i => i.status === 'held_in_escrow');
  const pendingTransfer = items.filter(i => i.status === 'pending_transfer');

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12 text-slate-500 animate-pulse">
        Cargando monitoreo de escrow...
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-slate-500">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" className="mb-4 opacity-50">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
        </svg>
        <p>No hay pagos en escrow o transferencias pendientes.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* En Escrow */}
      {heldInEscrow.length > 0 && (
        <div>
          <h4 className="text-sm font-bold text-blue-400 mb-3 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
            Fondos Retenidos en Escrow ({heldInEscrow.length})
          </h4>
          <div className="space-y-2">
            {heldInEscrow.map((item) => (
              <div key={item.payment_id} className="flex items-center justify-between p-4 rounded-xl bg-slate-800/30 border border-slate-700/50">
                <div className="flex-1">
                  <p className="text-white font-medium">{item.service_title}</p>
                  <p className="text-xs text-slate-400 mt-1">
                    Worker: {item.worker_name} • {formatDate(item.created_at)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-blue-400">{formatMXN(item.amount)}</p>
                  <span className="inline-flex px-2 py-1 text-xs font-bold rounded-full border bg-blue-500/10 text-blue-400 border-blue-500/20">
                    En Escrow
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Transferencias Pendientes */}
      {pendingTransfer.length > 0 && (
        <div>
          <h4 className="text-sm font-bold text-orange-400 mb-3 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
            </svg>
            Transferencias Pendientes ({pendingTransfer.length})
          </h4>
          <div className="space-y-2">
            {pendingTransfer.map((item) => (
              <div key={item.payment_id} className="flex items-center justify-between p-4 rounded-xl bg-slate-800/30 border border-slate-700/50">
                <div className="flex-1">
                  <p className="text-white font-medium">{item.service_title}</p>
                  <p className="text-xs text-slate-400 mt-1">
                    Worker: {item.worker_name} • {formatDate(item.created_at)}
                  </p>
                  {!item.worker_has_stripe && (
                    <p className="text-xs text-orange-400 mt-1 italic">
                      ⚠️ El worker no tiene Stripe configurado
                    </p>
                  )}
                </div>
                <div className="text-right flex items-center gap-3">
                  <div>
                    <p className="text-lg font-bold text-orange-400">{formatMXN(item.amount)}</p>
                    <span className="inline-flex px-2 py-1 text-xs font-bold rounded-full border bg-orange-500/10 text-orange-400 border-orange-500/20">
                      Pendiente
                    </span>
                  </div>
                  {item.worker_has_stripe && (
                    <button
                      onClick={() => handleProcessTransfer(item.payment_id)}
                      className="px-3 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-lg text-xs font-bold transition-all"
                    >
                      Procesar
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
