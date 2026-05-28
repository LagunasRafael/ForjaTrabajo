import { useState } from 'react';
import type{ PaymentListItem } from '../types/finance.types';
import { toast } from 'sonner';
import api from '../../../api/client';

interface TransactionTableProps {
  payments: PaymentListItem[];
  isLoading: boolean;
  onRefresh: () => void;
  onSelectPayment: (payment: PaymentListItem) => void;
}

const statusColors: Record<string, string> = {
  pending: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
  held_in_escrow: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  released: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  completed: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  refunded: 'bg-rose-500/10 text-rose-400 border-rose-500/20',
  failed: 'bg-red-500/10 text-red-400 border-red-500/20',
  pending_transfer: 'bg-orange-500/10 text-orange-400 border-orange-500/20',
};

const statusLabels: Record<string, string> = {
  pending: 'Pendiente',
  held_in_escrow: 'En Escrow',
  released: 'Liberado',
  completed: 'Completado',
  refunded: 'Reembolsado',
  failed: 'Fallido',
  pending_transfer: 'Transferencia Pendiente',
};

export const TransactionTable = ({ payments, isLoading, onRefresh, onSelectPayment }: TransactionTableProps) => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  const formatMXN = (val: number) =>
    new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });

  const filteredPayments = payments.filter(p => {
    const matchesSearch = !search ||
      p.id.toLowerCase().includes(search.toLowerCase()) ||
      p.service_title.toLowerCase().includes(search.toLowerCase()) ||
      p.client_name.toLowerCase().includes(search.toLowerCase()) ||
      p.worker_name.toLowerCase().includes(search.toLowerCase());
    
    const matchesStatus = !statusFilter || p.status === statusFilter;
    
    const matchesDateFrom = !dateFrom || new Date(p.created_at) >= new Date(dateFrom);
    const matchesDateTo = !dateTo || new Date(p.created_at) <= new Date(dateTo + 'T23:59:59');

    return matchesSearch && matchesStatus && matchesDateFrom && matchesDateTo;
  });

  const totalPages = Math.ceil(filteredPayments.length / itemsPerPage);
  const paginatedPayments = filteredPayments.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleExportCSV = () => {
    if (filteredPayments.length === 0) {
      toast.warning('No hay transacciones para exportar');
      return;
    }

    const headers = ['ID', 'Servicio', 'Cliente', 'Worker', 'Monto', 'Comisión', 'Estado', 'Fecha'];
    const rows = filteredPayments.map(p => [
      `"${p.id}"`,
      `"${p.service_title}"`,
      `"${p.client_name}"`,
      `"${p.worker_name}"`,
      p.amount,
      p.platform_fee,
      statusLabels[p.status] || p.status,
      formatDate(p.created_at)
    ].join(','));

    const csvContent = [headers.join(','), ...rows].join('\n');
    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `ForjaTrabajo_Transacciones_${new Date().toLocaleDateString()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success('Transacciones exportadas correctamente');
  };

  const handleRefund = async (paymentId: string) => {
    if (!confirm('¿Estás seguro de reembolsar este pago? Esta acción no se puede deshacer.')) return;
    try {
      await api.post(`/payments/refund/${paymentId}`);
      toast.success('Reembolso procesado correctamente');
      onRefresh();
    } catch (error) {
      toast.error('Error al procesar el reembolso');
    }
  };

  const handleDownloadInvoice = (paymentId: string) => {
    const apiUrl = import.meta.env.VITE_API_URL || 'https://forja-api-rw0r.onrender.com';
    window.open(`${apiUrl}/payments/invoice/${paymentId}/pdf`, '_blank');
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12 text-slate-500 animate-pulse">
        Cargando transacciones...
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Filtros */}
      <div className="flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Buscar por ID, servicio, cliente..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setCurrentPage(1); }}
          className="flex-1 min-w-[200px] rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white text-sm focus:border-indigo-500 focus:outline-none"
        />
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setCurrentPage(1); }}
          className="rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white text-sm focus:border-indigo-500 focus:outline-none"
        >
          <option value="">Todos los estados</option>
          {Object.entries(statusLabels).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>
        <input
          type="date"
          value={dateFrom}
          onChange={(e) => { setDateFrom(e.target.value); setCurrentPage(1); }}
          className="rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white text-sm focus:border-indigo-500 focus:outline-none"
        />
        <input
          type="date"
          value={dateTo}
          onChange={(e) => { setDateTo(e.target.value); setCurrentPage(1); }}
          className="rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white text-sm focus:border-indigo-500 focus:outline-none"
        />
        <button
          onClick={handleExportCSV}
          className="px-4 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-xl text-sm font-bold transition-all"
        >
          Exportar CSV
        </button>
      </div>

      {/* Tabla */}
      <div className="overflow-x-auto rounded-xl border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-800/50 border-b border-slate-700">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-slate-400 uppercase tracking-wider">ID</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-slate-400 uppercase tracking-wider">Servicio</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-slate-400 uppercase tracking-wider">Cliente</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-slate-400 uppercase tracking-wider">Worker</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-slate-400 uppercase tracking-wider">Monto</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-slate-400 uppercase tracking-wider">Comisión</th>
              <th className="px-4 py-3 text-center text-xs font-medium text-slate-400 uppercase tracking-wider">Estado</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-slate-400 uppercase tracking-wider">Fecha</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-slate-400 uppercase tracking-wider">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {paginatedPayments.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-8 text-center text-slate-500">
                  No se encontraron transacciones
                </td>
              </tr>
            ) : (
              paginatedPayments.map((payment) => {
                const canRefund = payment.status === 'held_in_escrow' || payment.status === 'pending';
                const canDownloadInvoice = payment.status === 'completed' || payment.status === 'released' || payment.status === 'refunded';

                return (
                  <tr key={payment.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-slate-400">
                      {payment.id.slice(0, 8)}...
                    </td>
                    <td className="px-4 py-3 text-white font-medium">{payment.service_title}</td>
                    <td className="px-4 py-3 text-slate-300">{payment.client_name}</td>
                    <td className="px-4 py-3 text-slate-300">{payment.worker_name}</td>
                    <td className="px-4 py-3 text-right text-emerald-400 font-bold">
                      {formatMXN(payment.amount)}
                    </td>
                    <td className="px-4 py-3 text-right text-purple-400">
                      {formatMXN(payment.platform_fee)}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <span className={`inline-flex px-2 py-1 text-xs font-bold rounded-full border ${statusColors[payment.status] || 'bg-slate-500/10 text-slate-400 border-slate-500/20'}`}>
                        {statusLabels[payment.status] || payment.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-400 text-xs">{formatDate(payment.created_at)}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1 justify-end">
                        <button
                          onClick={() => onSelectPayment(payment)}
                          className="p-1.5 rounded-lg hover:bg-indigo-500/20 text-indigo-400 transition-colors"
                          title="Ver detalle"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>
                          </svg>
                        </button>
                        {canRefund && (
                          <button
                            onClick={() => handleRefund(payment.id)}
                            className="p-1.5 rounded-lg hover:bg-rose-500/20 text-rose-400 transition-colors"
                            title="Reembolsar"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
                            </svg>
                          </button>
                        )}
                        {canDownloadInvoice && (
                          <button
                            onClick={() => handleDownloadInvoice(payment.id)}
                            className="p-1.5 rounded-lg hover:bg-emerald-500/20 text-emerald-400 transition-colors"
                            title="Descargar factura"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>
                            </svg>
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Paginación */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-slate-500">
            Mostrando {((currentPage - 1) * itemsPerPage) + 1} - {Math.min(currentPage * itemsPerPage, filteredPayments.length)} de {filteredPayments.length}
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1 rounded-lg bg-slate-800 text-slate-300 text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-700 transition-colors"
            >
              Anterior
            </button>
            <button
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1 rounded-lg bg-slate-800 text-slate-300 text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-700 transition-colors"
            >
              Siguiente
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
