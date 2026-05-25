import { useState, useEffect, useCallback } from 'react';
import { getFinanceOverview, getAdminPayments, getFinanceAnalytics, getEscrowMonitor } from '../services/finance.service';
import type{ FinanceOverview, PaymentListItem, AnalyticsPoint, EscrowItem } from '../types/finance.types';
import { RevenueChart } from '../components/RevenueChart';
import { TransactionTable } from '../components/TransactionTable';
import { EscrowMonitor } from '../components/EscrowMonitor';
import { PaymentDetailModal } from '../components/PaymentDetailModal';
import { toast } from 'sonner';
import api from '../../../api/client';

export const FinancePage = () => {
  const [overview, setOverview] = useState<FinanceOverview | null>(null);
  const [payments, setPayments] = useState<PaymentListItem[]>([]);
  const [analytics, setAnalytics] = useState<AnalyticsPoint[]>([]);
  const [escrowItems, setEscrowItems] = useState<EscrowItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedPayment, setSelectedPayment] = useState<PaymentListItem | null>(null);
  const [commissionRate, setCommissionRate] = useState(10);
  const [isSavingCommission, setIsSavingCommission] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      setIsLoading(true);
      const [overviewData, paymentsData, analyticsData, escrowData] = await Promise.all([
        getFinanceOverview(),
        getAdminPayments({ limit: 500 }),
        getFinanceAnalytics(30),
        getEscrowMonitor(),
      ]);
      setOverview(overviewData);
      setPayments(paymentsData);
      setAnalytics(analyticsData);
      setEscrowItems(escrowData);
      setCommissionRate(overviewData.commission_rate);
    } catch (error) {
      toast.error('Error al cargar datos financieros');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const formatMXN = (val: number) =>
    new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  const handleSaveCommission = async () => {
    setIsSavingCommission(true);
    try {
      await api.put('/admin/finance/config', { commission_rate: commissionRate });
      toast.success('Comisión actualizada correctamente');
      fetchData();
    } catch (error) {
      toast.error('Error al actualizar la comisión');
    } finally {
      setIsSavingCommission(false);
    }
  };

  const totalEscrowAmount = escrowItems.reduce((sum, item) => sum + item.amount, 0);
  const totalPendingAmount = escrowItems
    .filter(item => item.status === 'pending_transfer')
    .reduce((sum, item) => sum + item.amount, 0);

  return (
    <div className="space-y-8 animate-in fade-in duration-500 pb-10">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Gestión Financiera</h2>
          <p className="text-sm text-slate-400 mt-1">Métricas reales de pagos, comisiones y escrow.</p>
        </div>
      </div>

      {/* Tarjetas de Métricas */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Volumen Total (GMV)</p>
          <h3 className="mt-2 text-3xl font-bold text-emerald-400">
            {isLoading ? '...' : formatMXN(overview?.gmv_total || 0)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Dinero total movido en la plataforma.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Revenue Plataforma</p>
          <h3 className="mt-2 text-3xl font-bold text-purple-400">
            {isLoading ? '...' : formatMXN(overview?.platform_revenue || 0)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Comisiones recaudadas.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">En Escrow</p>
          <h3 className="mt-2 text-3xl font-bold text-blue-400">
            {isLoading ? '...' : formatMXN(totalEscrowAmount)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Fondos retenidos actualmente.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Transferencias Pendientes</p>
          <h3 className="mt-2 text-3xl font-bold text-orange-400">
            {isLoading ? '...' : formatMXN(totalPendingAmount)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Esperando Stripe del worker.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Reembolsos Totales</p>
          <h3 className="mt-2 text-3xl font-bold text-rose-400">
            {isLoading ? '...' : formatMXN(overview?.refunded_total || 0)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Dinero devuelto a clientes.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Ticket Promedio</p>
          <h3 className="mt-2 text-3xl font-bold text-indigo-400">
            {isLoading ? '...' : formatMXN(overview?.average_ticket || 0)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Promedio por transacción completada.</p>
        </div>
      </div>

      {/* Comisión y Transacciones */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Configuración de Comisión */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-emerald-400">
              <path d="M12 2v20"/><path d="m17 5-5-3-5 3"/><path d="m17 19-5 3-5-3"/><path d="M2 12h20"/>
            </svg>
            Comisión de Plataforma
          </h3>
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <input
                type="range"
                min="0"
                max="30"
                value={commissionRate}
                onChange={(e) => setCommissionRate(parseInt(e.target.value))}
                className="flex-1 h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500"
              />
              <span className="text-2xl font-bold text-white w-16 text-center">{commissionRate}%</span>
            </div>
            <button
              onClick={handleSaveCommission}
              disabled={isSavingCommission || commissionRate === overview?.commission_rate}
              className="w-full px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSavingCommission ? 'Guardando...' : 'Actualizar Comisión'}
            </button>
            <p className="text-xs text-slate-500 italic">
              Esta comisión se aplica a cada transacción completada.
            </p>
          </div>

          {/* Resumen rápido */}
          <div className="mt-6 pt-6 border-t border-slate-800 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-slate-400">Total transacciones</span>
              <span className="text-white font-bold">{isLoading ? '...' : overview?.total_transactions || 0}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-400">Comisión actual</span>
              <span className="text-white font-bold">{isLoading ? '...' : `${overview?.commission_rate || 0}%`}</span>
            </div>
          </div>
        </div>

        {/* Gráfica de Revenue */}
        <div className="lg:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <h3 className="text-lg font-bold text-white mb-6">Tendencia de Ingresos (30 días)</h3>
          <RevenueChart data={analytics} isLoading={isLoading} />
        </div>
      </div>

      {/* Monitoreo de Escrow */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
        <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-blue-400">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          Monitoreo de Escrow y Transferencias
        </h3>
        <EscrowMonitor items={escrowItems} isLoading={isLoading} onRefresh={fetchData} />
      </div>

      {/* Tabla de Transacciones */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
        <h3 className="text-lg font-bold text-white mb-6">Historial de Transacciones</h3>
        <TransactionTable payments={payments} isLoading={isLoading} onRefresh={fetchData} onSelectPayment={setSelectedPayment} />
      </div>

      {/* Modal de Detalle */}
      {selectedPayment && (
        <PaymentDetailModal payment={selectedPayment} onClose={() => setSelectedPayment(null)} />
      )}
    </div>
  );
};
