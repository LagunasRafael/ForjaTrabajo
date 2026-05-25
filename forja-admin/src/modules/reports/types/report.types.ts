export interface Report {
  id: string;
  reporter_id: string;
  reported_user_id: string | null;
  reported_service_id: string | null;
  reason: string;
  description: string | null;
  status: 'pending' | 'resolved_banned' | 'resolved_service_banned' | 'dismissed';
  admin_id: string | null;
  admin_note: string | null;
  created_at: string;
  resolved_at: string | null;
  reporter_name: string;
  reported_user_name: string | null;
  admin_name: string | null;
  service?: {
    id: string;
    title: string;
    description: string;
    is_active: boolean;
  } | null;
}

export interface ResolveAction {
  action: 'ban_user' | 'ban_service' | 'dismiss';
  admin_note?: string;
}
