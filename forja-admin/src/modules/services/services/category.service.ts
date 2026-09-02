import api from '../../../api/client';

// DTO: Lo que viene de FastAPI 
interface CategoryDTO {
  id: string;
  name: string;
  description?: string;
  is_active?: boolean;
  created_at?: string;
}

// 2. Modelo forntend que usa frontend 
export interface Category {
  id: string;
  name: string;
  description?: string;
  status: 'active' | 'inactive';
  createdAt?: string;
}

// 3. Mapper: El traductor
const mapCategoryFromApi = (dto: CategoryDTO): Category => ({
  id: dto.id,
  name: dto.name,
  description: dto.description,
  status: dto.is_active === false ? 'inactive' : 'active',
  createdAt: dto.created_at,
});

// --- SERVICIOS ---

export const getCategories = async (): Promise<Category[]> => {
  const { data } = await api.get<CategoryDTO[]>('/services/categories');
  return data.map(mapCategoryFromApi);
};

export const createCategory = async (category: { name: string; description: string }): Promise<Category> => {
  const { data } = await api.post<CategoryDTO>('/services/categories', category);
  return mapCategoryFromApi(data);
};

// 🟠 ACTUALIZAR (Nuevo)
export const updateCategory = async (id: string, category: { name: string; description: string }): Promise<Category> => {
  const { data } = await api.put<CategoryDTO>(`/services/categories/${id}`, category);
  return mapCategoryFromApi(data);
};

// 🔴 ELIMINAR (Nuevo)
export const deleteCategory = async (id: string): Promise<void> => {
  await api.delete(`/services/categories/${id}`);
};