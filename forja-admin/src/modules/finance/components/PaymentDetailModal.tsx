import { PaymentListItem } from '../types/finance.types';

interface PaymentDetailModalProps {
  payment: PaymentListItem | null;
  onClose: () => void;
}

const statusLabels: Record<string, string> = {
  pending: 'Pendiente',
  held_in_escrow: 'En Escrow',
  released: 'Liberado',
  completed: 'Completado',
  refunded: 'Reembolsado',
  failed: 'Fallido',
  pending_transfer: 'Transferencia Pendiente',
};

export const PaymentDetailModal = ({ payment, onClose }: PaymentDetailModalProps) => {
  if (!payment) return null;

  const formatMXN = (val: number) =>
    new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString('es-MX', { 
      day: '2-digit', 
      month: 'long', 
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm" onClick={onClose}>
      <div className="w-full max-w-lg mx-4 rounded-2xl border border-slate-800 bg-slate-900 p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-bold text-white">Detalle de Pago</h3>
          <button onClick={onClose} className="p-2 rounded-lg hover:bg-slate-800 text-slate-400 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 6 6 18"/><path d="m6 6 12 12"/>
            </svg>
          </button>
        </div>

        <div className="space-y-4">
          <div className="p-4 rounded-xl bg-slate-800/50">
            <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">ID de Pago</p>
            <p className="font-mono text-sm text-white">{payment.id}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Servicio</p>
              <p className="text-white font-medium">{payment.service_title}</p>
            </div>
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Estado</p>
              <p className="text-white font-medium">{statusLabels[payment.status] || payment.status}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Cliente</p>
              <p className="text-white font-medium">{payment.client_name}</p>
            </div>
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Worker</p>
              <p className="text-white font-medium">{payment.worker_name}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Monto</p>
              <p className="text-2xl font-bold text-emerald-400">{formatMXN(payment.amount)}</p>
            </div>
            <div className="p-4 rounded-xl bg-slate-800/50">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Comisión Plataforma</p>
              <p className="text-2xl font-bold text-purple-400">{formatMXN(payment.platform_fee)}</p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-slate-800/50">
            <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Fecha de Creación</p>
            <p className="text-white font-medium">{formatDate(payment.created_at)}</p>
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={onClose}
            className="px-6 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-sm font-bold transition-all"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
};
