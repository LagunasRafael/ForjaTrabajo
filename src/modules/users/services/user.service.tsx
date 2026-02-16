import api from '../../../api/client';
import type { User } from '../types/user.types';
import type { UserFormData } from '../schemas/user.schema';

// 1. DTO (Data Transfer Object): ESPEJO exacto de Python (FastAPI)
interface UserDTO {
  id: string;
  full_name: string; 
  email: string;
  role: string;
  is_active: boolean; 
  created_at: string; 
  profile_picture_url?: string;
}

// 2. MAPPER (Adapter Pattern): Convierte el DTO crudo al formato del Frontend
const mapUserFromApi = (dto: UserDTO): User => {
  return {
    id: dto.id,
    full_name: dto.full_name || "Usuario Sin Nombre", 
    email: dto.email,
    role: dto.role as any,
    status: dto.is_active ? 'active' : 'inactive',
    createdAt: dto.created_at, 
    avatarUrl: dto.profile_picture_url,
  };
};

// --- SERVICIOS CONECTADOS AL HOOK ---

// 🟢 OBTENER TODOS
export const getUsersApi = async (): Promise<User[]> => {
  const { data } = await api.get<UserDTO[]>('/auth/users'); 
  return data.map(mapUserFromApi); // Pasamos los datos por el filtro (Mapper)
};

// 🔵 CREAR
export const createUserApi = async (formData: UserFormData): Promise<User> => {
  const payload = {
    full_name: formData.name, // Traducimos del Formulario (name) a FastAPI (full_name)
    email: formData.email,
    password: "passwordTemporal123", // Requerido por FastAPI
    role: formData.role,
    // is_active: formData.status === 'active' // Opcional, si tu API lo recibe al registrar
  };

  const { data } = await api.post<UserDTO>('/auth/register', payload);
  return mapUserFromApi(data);
};

// 🟠 ACTUALIZAR
export const updateUserApi = async (id: string, formData: UserFormData): Promise<User> => {
  const payload = { 
    full_name: formData.name, // Traducimos nuevamente
    role: formData.role,
    is_active: formData.status === 'active' // Traducimos status a is_active booleano
  };
  
  // Asumiendo que tus rutas de update/delete están en /auth/users
  const { data } = await api.put<UserDTO>(`/auth/users/${id}`, payload);
  return mapUserFromApi(data);
};

// 🔴 ELIMINAR
export const deleteUserApi = async (id: string): Promise<void> => {
  await api.delete(`/auth/users/${id}`);
};

// 🟣 SUBIR FOTO DE PERFIL (AWS S3) 👇 NUEVO SERVICIO AÑADIDO
export const uploadUserAvatarApi = async (id: string, file: File): Promise<User> => {
  // 1. Empacamos el archivo físico
  const formData = new FormData();
  formData.append("file", file); // "file" debe ser exactamente el nombre que espera FastAPI

  // 2. Hacemos la petición POST a tu nuevo endpoint
  const { data } = await api.post<UserDTO>(`/auth/${id}/profile-picture`, formData, {
    headers: {
      "Content-Type": "multipart/form-data", // Vital para que FastAPI no espere un JSON
    },
  });
  
  // 3. Devolvemos el usuario actualizado pasado por el Mapper
  return mapUserFromApi(data);
};