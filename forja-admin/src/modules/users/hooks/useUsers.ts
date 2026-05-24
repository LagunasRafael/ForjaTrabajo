import { useState, useEffect } from 'react';
import { useAutoRefresh } from '../../../hooks/useAutoRefresh';
import type { User } from '../types/user.types';
import type { UserFormData } from '../schemas/user.schema';

// Importamos las funciones reales que conectan con FastAPI
import { 
  getUsersApi, 
  createUserApi, 
  updateUserApi, 
  deleteUserApi,
  uploadUserAvatarApi,
  banUserApi,
  unbanUserApi,
} from '../services/user.service';

export const useUsers = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // 1. CARGAR USUARIOS (Al iniciar la pantalla)
  useEffect(() => {
    fetchUsers();
  }, []);

  useAutoRefresh(() => fetchUsers(), 30000);

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      // Llamamos al servicio que trae los datos y los pasa por el Mapper
      const data = await getUsersApi();
      setUsers(data);
      setError(null);
    } catch (err) {
      setError('Error al cargar usuarios desde el servidor');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  // 2. CREAR USUARIO
  const createUser = async (formData: UserFormData) => {
    try {
      // Enviamos la petición POST a FastAPI
      const newUser = await createUserApi(formData);
      
      // Actualizamos la tabla de React inmediatamente (Optimistic UI)
      setUsers(prev => [newUser, ...prev]);
      
      return newUser;
    } catch (error) {
      console.error("Error creando usuario:", error);
      throw error; // Lo lanzamos para que el toast.error del UsersPage lo atrape
    }
  };

  // 3. ACTUALIZAR USUARIO
  const updateUser = async (id: string, formData: UserFormData) => {
    try {
      // Enviamos la petición PUT a FastAPI
      const updatedUser = await updateUserApi(id, formData);
      
      // Buscamos al usuario en la tabla y lo reemplazamos con los datos frescos
      setUsers(prev => prev.map(user => 
        user.id === id ? { ...user, ...updatedUser } : user
      ));
      
      return updatedUser;
    } catch (error) {
      console.error("Error actualizando usuario:", error);
      throw error;
    }
  };

  // 4. ELIMINAR USUARIO
  const deleteUser = async (id: string) => {
    try {
      // Enviamos la petición DELETE a FastAPI
      await deleteUserApi(id);
      
      // Lo filtramos (quitamos) de la tabla visualmente
      setUsers(prev => prev.filter(user => user.id !== id));
    } catch (error) {
      console.error("Error eliminando usuario:", error);
      throw error;
    }
  };

  const uploadAvatar = async (id: string, file: File) => {
    try {
      // 1. Llamamos a la API que creamos hace un momento
      const updatedUser = await uploadUserAvatarApi(id, file);
      
      // 2. Actualizamos el estado local para que la foto aparezca en la tabla sin recargar la página
      setUsers(prevUsers => prevUsers.map(user => 
        user.id === id ? updatedUser : user
      ));
      
      return updatedUser;
    } catch (error) {
      console.error("Error subiendo avatar:", error);
      throw error;
    }
  };

  const banUser = async (id: string) => {
    const updatedUser = await banUserApi(id);
    setUsers(prev => prev.map(user => 
      user.id === id ? { ...user, ...updatedUser } : user
    ));
    return updatedUser;
  };

  const unbanUser = async (id: string) => {
    const updatedUser = await unbanUserApi(id);
    setUsers(prev => prev.map(user => 
      user.id === id ? { ...user, ...updatedUser } : user
    ));
    return updatedUser;
  };

  return {
    users,
    isLoading,
    error,
    createUser,
    updateUser,
    deleteUser,
    refreshUsers: fetchUsers,
    uploadAvatar,
    banUser,
    unbanUser,
  };
};