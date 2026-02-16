import { useEffect, useState, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { userSchema, type UserFormData } from '../schemas/user.schema';
import type { User } from '../types/user.types';
import { toast } from 'sonner';
// IMPORTA AQUÍ TU NUEVA FUNCIÓN DEL HOOK O SERVICIO 👇
import { useUsers } from '../hooks/useUsers'; 

interface UserFormSlideOverProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: UserFormData) => void;
  initialData?: User | null;
}

export const UserFormSlideOver = ({ isOpen, onClose, onSubmit, initialData }: UserFormSlideOverProps) => {
  // 1. Hook de Usuarios (Para usar la función de subir foto)
  const { uploadAvatar } = useUsers();

  // 2. Estados Locales para la Foto de Perfil
  const [localAvatarUrl, setLocalAvatarUrl] = useState<string | undefined>(undefined);
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // 3. Configuración del Hook Form
  const { 
    register, 
    handleSubmit, 
    reset, 
    formState: { errors, isSubmitting } 
  } = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
    defaultValues: {
      name: '',
      email: '',
      role: 'client',
      status: 'active'
    }
  });

  // 4. Efecto para cargar datos
  useEffect(() => {
    if (isOpen) {
      if (initialData) {
        setLocalAvatarUrl(initialData.avatarUrl); // <-- Guardamos la foto actual
        reset({
          name: initialData.full_name,
          email: initialData.email,
          role: initialData.role,
          status: initialData.status,
        });
      } else {
        setLocalAvatarUrl(undefined); // <-- Limpiamos si es nuevo usuario
        reset({
          name: '',
          email: '',
          role: 'client',
          status: 'active'
        });
      }
    }
  }, [isOpen, initialData, reset]);

  // 5. Función para manejar la subida de foto a AWS
  const handlePhotoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !initialData) return; // Validación doble

    setIsUploadingPhoto(true);
    const loadingToast = toast.loading('Subiendo imagen a la nube...');

    try {
      // Usamos la función de tu hook (que se conecta a tu servicio API)
      const updatedUser = await uploadAvatar(initialData.id, file);
      
      // Actualizamos el circulito visualmente
      setLocalAvatarUrl(updatedUser.avatarUrl); 
      toast.success('¡Foto de perfil actualizada!', { id: loadingToast });
      
    } catch (error) {
      toast.error('Hubo un error al subir la imagen', { id: loadingToast });
    } finally {
      setIsUploadingPhoto(false);
      if (fileInputRef.current) fileInputRef.current.value = ''; 
    }
  };

  // Clases de animación
  const backdropClass = isOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none';
  const panelClass = isOpen ? 'translate-x-0' : 'translate-x-full';

  return (
    <div className={`fixed inset-0 z-50 flex justify-end transition-opacity duration-300 ${backdropClass}`}>
      <div className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm transition-opacity" onClick={onClose} />

      <div className={`relative h-full w-full max-w-md bg-slate-900 border-l border-slate-800 shadow-2xl transition-transform duration-300 ease-in-out transform flex flex-col ${panelClass}`}>
        
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800 shrink-0">
          <h2 className="text-lg font-semibold text-white">
            {initialData ? 'Editar Usuario' : 'Nuevo Usuario'}
          </h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
            <span className="sr-only">Cerrar</span>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>

        {/* 6. Formulario Conectado (Con scroll interno) */}
        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-6 overflow-y-auto flex-1">
          
          {/* 👇 NUEVA SECCIÓN DE FOTO DE PERFIL (Solo en modo Edición) 👇 */}
          {initialData && (
            <div className="flex flex-col items-center justify-center p-4 mb-6 bg-slate-950/50 rounded-xl border border-slate-800/50">
              <div className="relative group mb-3">
                {/* El circulito de la foto */}
                <div className="w-24 h-24 rounded-full overflow-hidden bg-slate-800 border-2 border-slate-700 shadow-inner relative flex items-center justify-center">
                  {localAvatarUrl ? (
                    <img 
                      src={localAvatarUrl} 
                      alt="Perfil" 
                      className={`w-full h-full object-cover transition-opacity ${isUploadingPhoto ? 'opacity-50' : 'opacity-100'}`}
                    />
                  ) : (
                    <span className="text-slate-400 font-bold text-2xl">
                      {initialData.full_name.charAt(0).toUpperCase()}
                    </span>
                  )}
                  
                  {/* Overlay de Carga */}
                  {isUploadingPhoto && (
                    <div className="absolute inset-0 flex items-center justify-center bg-slate-900/40">
                      <svg className="animate-spin h-6 w-6 text-indigo-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>
                  )}
                </div>
              </div>

              {/* Input Oculto y Botón */}
              <input
                type="file"
                accept="image/png, image/jpeg, image/webp"
                className="hidden"
                ref={fileInputRef}
                onChange={handlePhotoUpload}
                disabled={isUploadingPhoto}
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={isUploadingPhoto}
                className="text-xs font-medium px-3 py-1.5 bg-slate-800 text-slate-300 hover:text-white hover:bg-slate-700 rounded-md transition-all border border-slate-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isUploadingPhoto ? 'Procesando...' : (localAvatarUrl ? 'Cambiar Foto' : 'Subir Foto')}
              </button>
            </div>
          )}
          {/* 👆 FIN DE LA SECCIÓN DE FOTO 👆 */}

          {/* Nombre */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-300">Nombre Completo</label>
            <input 
              {...register('name')}
              className={`w-full bg-slate-950 border rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 transition-all ${errors.name ? 'border-rose-500/50 focus:ring-rose-500/20' : 'border-slate-800 focus:ring-indigo-500/50'}`}
              placeholder="Ej. Rafael Dev"
            />
            {errors.name && <span className="text-xs text-rose-400">{errors.name.message}</span>}
          </div>

          {/* Email */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-300">Correo Electrónico</label>
            <input 
              {...register('email')}
              className={`w-full bg-slate-950 border rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 transition-all ${errors.email ? 'border-rose-500/50 focus:ring-rose-500/20' : 'border-slate-800 focus:ring-indigo-500/50'}`}
              placeholder="rafael@forjatrabajo.com"
            />
            {errors.email && <span className="text-xs text-rose-400">{errors.email.message}</span>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            {/* Rol */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-300">Rol</label>
              <select 
                {...register('role')}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
              >
                <option value="admin">Administrador</option>
                <option value="worker">Prestador</option>
                <option value="client">Cliente</option>
              </select>
              {errors.role && <span className="text-xs text-rose-400">{errors.role.message}</span>}
            </div>

            {/* Estado */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-slate-300">Estado</label>
              <select 
                {...register('status')}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
              >
                <option value="active">Activo</option>
                <option value="pending">Pendiente</option>
                <option value="inactive">Inactivo</option>
              </select>
            </div>
          </div>

        </form>

        {/* Footer con los botones (Fijo abajo) */}
        <div className="p-6 border-t border-slate-800 flex justify-end gap-3 shrink-0 bg-slate-900/90 backdrop-blur-sm">
          <button 
            type="button" 
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-slate-300 hover:text-white transition-colors"
          >
            Cancelar
          </button>
          <button 
            type="button" 
            onClick={handleSubmit(onSubmit)}
            disabled={isSubmitting}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-medium rounded-lg shadow-lg shadow-indigo-500/20 transition-all flex items-center gap-2"
          >
            {isSubmitting && (
              <svg className="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            )}
            {initialData ? 'Guardar Cambios' : 'Crear Usuario'}
          </button>
        </div>

      </div>
    </div>
  );
};