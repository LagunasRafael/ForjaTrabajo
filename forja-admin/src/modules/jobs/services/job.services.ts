import api from '../../../api/client';
import type { JobPost } from '../types/job.types';
import type { JobFormData } from '../schemas/job.schema';

// 🟢 OBTENER TODAS LAS OFERTAS (Para la tabla)
export const getJobsApi = async (): Promise<JobPost[]> => {
  const { data } = await api.get<JobPost[]>('/jobs/');
  return data;
};

// 🔵 CREAR OFERTA (Con archivos binarios)
export const createJobApi = async (formData: JobFormData, files: File[]): Promise<JobPost> => {
  const data = new FormData();
  
  data.append('title', formData.title);
  data.append('description', formData.description);
  data.append('category', formData.category);
  data.append('location_city', formData.location_city);
  data.append('client_id', 'id-temporal-admin'); // Aquí iría el ID del admin logueado

  files.forEach((file) => {
    data.append('files', file); 
  });

  const response = await api.post<JobPost>('/jobs/', data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  
  return response.data;
};

// 🔴 ELIMINAR OFERTA
export const deleteJobApi = async (id: string): Promise<void> => {
  await api.delete(`/jobs/${id}`);
};