import api from '../../../api/client';
import type { Report, ResolveAction } from '../types/report.types';

export const getReportsApi = async (status?: string): Promise<Report[]> => {
  const params = status ? { status } : {};
  const { data } = await api.get<Report[]>('/services/admin/reports', { params });
  return data;
};

export const getReportDetailApi = async (id: string): Promise<Report> => {
  const { data } = await api.get<Report>(`/services/admin/reports/${id}`);
  return data;
};

export const resolveReportApi = async (id: string, payload: ResolveAction): Promise<void> => {
  await api.post(`/services/admin/reports/${id}/resolve`, payload);
};
