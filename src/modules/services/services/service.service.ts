import api from '../../../api/client';
import type { Category } from './category.service';

export interface Service {
  id: string;
  name: string;
  description: string;
  price: number;
  category_id: string;
  provider_id: string;
  // Opcional: Para mostrar el nombre de la categoría en la tabla si el backend lo popula
  category?: Category; 
}

export const getServices = async (): Promise<Service[]> => {
  // Ajusta la URL si usas prefijo /services en backend
  const { data } = await api.get<Service[]>('/services'); 
  return data;
};

export const createService = async (serviceData: { 
  name: string; 
  description: string; 
  price: number; 
  category_id: string; 
}): Promise<Service> => {
  const { data } = await api.post<Service>('/services', serviceData);
  return data;
};