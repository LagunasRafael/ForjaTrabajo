export interface FinanceOverview {
  gmv_total: number;
  platform_revenue: number;
  escrow_held: number;
  pending_transfers: number;
  refunded_total: number;
  total_transactions: number;
  average_ticket: number;
  commission_rate: number;
  payments_by_status: Record<string, number>;
}

export interface PaymentListItem {
  id: string;
  service_title: string;
  client_name: string;
  worker_name: string;
  amount: number;
  platform_fee: number;
  status: string;
  created_at: string;
}

export interface AnalyticsPoint {
  date: string;
  gmv: number;
  platform_fee: number;
}

export interface EscrowItem {
  payment_id: string;
  service_title: string;
  amount: number;
  status: string;
  created_at: string;
  worker_name: string;
  worker_has_stripe: boolean;
}
