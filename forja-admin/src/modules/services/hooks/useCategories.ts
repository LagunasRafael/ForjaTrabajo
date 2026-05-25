import { useState, useEffect, useCallback } from 'react';
import { 
  getCategories, 
  createCategory, 
  updateCategory, 
  deleteCategory,
  type Category 
} from '../services/category.service';
import { toast } from 'sonner';

export const useCategories = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // 🟢 Cargar categorías
  const fetchCategories = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getCategories();
      setCategories(data);
    } catch (error) {
      toast.error('Error al cargar las categorías');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  // 🔵 Crear
  const addCategory = async (name: string, description: string) => {
    const newCat = await createCategory({ name, description });
    setCategories(prev => [...prev, newCat]);
    return newCat;
  };

  // 🟠 Actualizar
  const editCategory = async (id: string, name: string, description: string) => {
    const updatedCat = await updateCategory(id, { name, description });
    setCategories(prev => prev.map(cat => cat.id === id ? updatedCat : cat));
    return updatedCat;
  };

  // 🔴 Eliminar
  const removeCategory = async (id: string) => {
    await deleteCategory(id);
    setCategories(prev => prev.filter(cat => cat.id !== id));
  };

  return {
    categories,
    isLoading,
    addCategory,
    editCategory,
    removeCategory,
    refresh: fetchCategories
  };
};