import { useState, useMemo } from 'react';
import { UserTable } from './components/UserTable';
import { UserToolbar } from './components/UserToolbar';
import { UserFormSlideOver } from './components/UserFormSlideOver';
import { useUsers } from './hooks/useUsers'; // <--- Importamos el Hook
import type { User } from './types/user.types';
import { toast } from 'sonner';
import {type UserFormData } from './schemas/user.schema';

const UsersPage = () => {
  // 1. Lógica de Datos (Extraída al Hook)
  const { users, isLoading, createUser, updateUser, deleteUser } = useUsers();
  
  // 2. Estado de UI (Local de la página)
  const [searchTerm, setSearchTerm] = useState('');
  const [isSlideOverOpen, setIsSlideOverOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  // 3. Filtrado
  const filteredUsers = useMemo(() => {
    if (!searchTerm) return users;
    const lowerTerm = searchTerm.toLowerCase();
    return users.filter(user => 
      user.full_name.toLowerCase().includes(lowerTerm) ||
      user.email.toLowerCase().includes(lowerTerm)
    );
  }, [users, searchTerm]);

  // 4. Handlers de UI
  const handleOpenCreate = () => {
    setSelectedUser(null);
    setIsSlideOverOpen(true);
  };

  const handleOpenEdit = (user: User) => {
    setSelectedUser(user);
    setIsSlideOverOpen(true);
  };

  const handleSave = async (formData: UserFormData) => {
    try {
      if (selectedUser) {
        // Modo Edición
        await updateUser(selectedUser.id, formData);
        toast.success('Usuario actualizado correctamente'); // <--- Feedback
      } else {
        // Modo Creación
        await createUser(formData);
        toast.success('Nuevo usuario creado exitosamente'); // <--- Feedback
      }
      setIsSlideOverOpen(false);
    } catch (error) {
      toast.error('Ocurrió un error al guardar el usuario'); // <--- Error Handling
    }
  };

  const handleDelete = async (id: string) => {
    // Usamos toast.promise para acciones asíncronas (efecto muy pro)
    toast.promise(deleteUser(id), {
      loading: 'Eliminando usuario...',
      success: 'Usuario eliminado permanentemente',
      error: 'No se pudo eliminar el usuario',
    });
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <header>
        <h1 className="text-2xl font-bold text-white tracking-tight">Usuarios</h1>
        <p className="text-slate-400 text-sm mt-1">Gestión de accesos y roles del sistema.</p>
      </header>

      <UserToolbar 
        onSearch={setSearchTerm} 
        onCreateClick={handleOpenCreate} 
      />

      <UserTable 
        users={filteredUsers} 
        isLoading={isLoading} 
        onEdit={handleOpenEdit} 
        onDelete={handleDelete}
      />
      
      <UserFormSlideOver 
        isOpen={isSlideOverOpen}
        onClose={() => setIsSlideOverOpen(false)}
        onSubmit={handleSave}
        initialData={selectedUser}
      />
    </div>
  );
};

export default UsersPage;