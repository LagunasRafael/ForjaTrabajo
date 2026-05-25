import api from '../../../api/client';
import type { JobPost } from '../types/job.types';
import type { JobFormData } from '../schemas/job.schema';

// 🟢 OBTENER TODAS LAS CONTRATACIONES REALES
export const getJobsApi = async (): Promise<JobPost[]> => {
  const { data } = await api.get<JobPost[]>('/services/admin/jobs/all');
  return data;
};

// 🔵 CREAR OFERTA (Con archivos binarios)
export const createJobApi = async (formData: JobFormData, files: File[]): Promise<JobPost> => {
  const data = new FormData();
  
  data.append('title', formData.title);
  data.append('description', formData.description);
  data.append('category_id', formData.category); // Use category_id as expected by the backend if applicable
  
  // Check what the current backend endpoint for creation is. 
  // The previous version was POST /jobs/ but in backend it is POST /services/ usually.
  // Let's make it POST /services/ because that is the standard route we saw in routes.py.
  data.append('base_price', '0'); 

  files.forEach((file) => {
    data.append('files', file); 
  });

  const response = await api.post<JobPost>('/services/', data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  
  return response.data;
};

// 🔴 ELIMINAR OFERTA
export const deleteJobApi = async (id: string): Promise<void> => {
  await api.delete(`/services/jobs/${id}`); 
};