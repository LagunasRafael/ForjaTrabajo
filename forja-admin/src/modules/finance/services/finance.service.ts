import api from '../../../api/client';
import type{ FinanceOverview, PaymentListItem, AnalyticsPoint, EscrowItem } from '../types/finance.types';

export const getFinanceOverview = async (): Promise<FinanceOverview> => {
  const { data } = await api.get('/admin/finance/overview');
  return data;
};

export const getAdminPayments = async (params?: {
  status?: string;
  date_from?: string;
  date_to?: string;
  search?: string;
  skip?: number;
  limit?: number;
}): Promise<PaymentListItem[]> => {
  const { data } = await api.get('/admin/finance/payments', { params });
  return data;
};

export const getFinanceAnalytics = async (days: number = 30): Promise<AnalyticsPoint[]> => {
  const { data } = await api.get('/admin/finance/analytics', { params: { days } });
  return data;
};

export const getEscrowMonitor = async (): Promise<EscrowItem[]> => {
  const { data } = await api.get('/admin/finance/escrow');
  return data;
};

export const processPendingTransfer = async (paymentId: string): Promise<{ status: string; message: string }> => {
  const { data } = await api.post(`/admin/finance/process-pending-transfer/${paymentId}`);
  return data;
};
