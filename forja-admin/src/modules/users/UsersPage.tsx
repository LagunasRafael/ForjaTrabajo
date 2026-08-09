import { useState, useMemo } from 'react';
import { UserTable } from './components/UserTable';
import { UserToolbar } from './components/UserToolbar';
import { UserFormSlideOver } from './components/UserFormSlideOver';
import { useUsers } from './hooks/useUsers';
import type { User } from './types/user.types';
import { toast } from 'sonner';
import {type UserFormData } from './schemas/user.schema';
import { ConfirmModal } from '../../components/ConfirmModal';

const UsersPage = () => {
  const { users, isLoading, createUser, updateUser, deleteUser } = useUsers();
  
  const [searchTerm, setSearchTerm] = useState('');
  const [isSlideOverOpen, setIsSlideOverOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);

  const filteredUsers = useMemo(() => {
    if (!searchTerm) return users;
    const lowerTerm = searchTerm.toLowerCase();
    return users.filter(user => 
      user.full_name.toLowerCase().includes(lowerTerm) ||
      user.email.toLowerCase().includes(lowerTerm)
    );
  }, [users, searchTerm]);

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

  const handleDeleteClick = (userId: string) => {
    const user = users.find(u => u.id === userId);
    if (user) setDeleteTarget(user);
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    try {
      await deleteUser(deleteTarget.id);
      toast.success(`${deleteTarget.full_name} ha sido eliminado`);
    } catch {
      toast.error('No se pudo eliminar el usuario');
    } finally {
      setDeleteTarget(null);
    }
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
        onDelete={handleDeleteClick as (userId: string) => void}
      />
      
      <UserFormSlideOver 
        isOpen={isSlideOverOpen}
        onClose={() => setIsSlideOverOpen(false)}
        onSubmit={handleSave}
        initialData={selectedUser}
      />

      <ConfirmModal
        isOpen={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDeleteConfirm}
        title="Eliminar usuario"
        message={
          deleteTarget
            ? `¿Estás seguro de que quieres eliminar permanentemente a ${deleteTarget.full_name}? Esta acción no se puede deshacer.`
            : ''
        }
        confirmLabel="Eliminar"
        confirmClass="bg-red-600 hover:bg-red-500"
      />
    </div>
  );
};

export default UsersPage;