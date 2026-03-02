import { useState, useEffect } from 'react'; // 1. Añadimos useEffect
import { useForm } from 'react-hook-form';
import { toast } from 'sonner';
import { updateUserApi, uploadUserAvatarApi } from '../../users/services/user.service';

export const ProfilePage = () => {
  // 1. Estado inicial del usuario
  const [user, setUser] = useState(() => {
    const userString = localStorage.getItem('user');
    return userString ? JSON.parse(userString) : {};
  });

  const [isLoading, setIsLoading] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  // 2. CONFIGURAMOS EL FORMULARIO
  const { register, handleSubmit, reset, formState: { errors, isDirty } } = useForm({
    defaultValues: {
      full_name: user.full_name || '',
      email: user.email || '',
    }
  });

  // 🛡️ ESTA ES LA PIEZA QUE FALTABA: Escuchar cambios externos (de la tabla de usuarios)
  useEffect(() => {
    const syncProfile = () => {
      const userString = localStorage.getItem('user');
      if (userString) {
        const updatedData = JSON.parse(userString);
        setUser(updatedData);
        // Actualizamos los valores del formulario por si cambiaste tu nombre en la tabla
        reset({
          full_name: updatedData.full_name,
          email: updatedData.email
        });
      }
    };

    window.addEventListener('storage', syncProfile);
    return () => window.removeEventListener('storage', syncProfile);
  }, [reset]);

  // --- SUBIR FOTO ---
  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const toastId = toast.loading('Actualizando imagen en Amazon S3...');

    try {
      const updatedUserFromApi = await uploadUserAvatarApi(user.id, file);

      // Actualizamos la sesión local
      const updatedUser = { 
        ...user, 
        profile_picture_url: updatedUserFromApi.avatarUrl 
      };

      localStorage.setItem('user', JSON.stringify(updatedUser));
      setUser(updatedUser);

      // ¡IMPORTANTE! Avisamos al Navbar y a cualquier otro componente
      window.dispatchEvent(new Event('storage'));

      toast.success('¡Foto actualizada!', { id: toastId });
    } catch (error) {
      toast.error('Error al subir la imagen', { id: toastId });
    } finally {
      setIsUploading(false);
    }
  };

  // --- ACTUALIZAR DATOS ---
  const onSubmit = async (data: any) => {
    setIsLoading(true);
    try {
      const formDataToSubmit = {
        name: data.full_name,
        email: data.email,
        role: user.role,
        status: user.is_active ? 'active' : 'inactive'
      };

      await updateUserApi(user.id, formDataToSubmit as any);

      const updatedUser = { ...user, ...data };
      localStorage.setItem('user', JSON.stringify(updatedUser));
      setUser(updatedUser);
      
      window.dispatchEvent(new Event('storage'));
      toast.success('Datos actualizados correctamente');
      
    } catch (error) {
      toast.error('Error al guardar los cambios');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500 max-w-5xl">
      <header>
        <h2 className="text-2xl font-bold text-white tracking-tight">Mi Perfil</h2>
        <p className="text-sm text-slate-400 mt-1">Gestiona tu identidad en Forja Trabajo.</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* LADO IZQUIERDO: FOTO */}
        <div className="md:col-span-1">
          <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm text-center">
            <div className="relative group inline-block">
              <div className={`h-32 w-32 rounded-full overflow-hidden border-4 border-slate-800 bg-slate-800 flex items-center justify-center transition-all ${isUploading ? 'animate-pulse opacity-50' : ''}`}>
                {user.profile_picture_url ? (
                  <img 
                    key={user.profile_picture_url} // Forzamos a React a re-renderizar si la URL cambia
                    src={user.profile_picture_url} 
                    alt="Perfil" 
                    className="h-full w-full object-cover" 
                  />
                ) : (
                  <span className="text-4xl font-bold text-slate-400">{user.full_name?.charAt(0)}</span>
                )}
              </div>
              
              <label className="absolute inset-0 flex items-center justify-center bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity rounded-full cursor-pointer backdrop-blur-sm">
                <span className="text-xs font-bold text-white uppercase tracking-tighter">
                  {isUploading ? 'Subiendo...' : 'Editar'}
                </span>
                <input type="file" className="hidden" accept="image/*" onChange={handleFileChange} disabled={isUploading} />
              </label>
            </div>

            <h3 className="mt-4 text-lg font-bold text-white">{user.full_name}</h3>
            <p className="text-sm text-slate-400 truncate">{user.email}</p>
          </div>
        </div>

        {/* LADO DERECHO: FORMULARIO */}
        <div className="md:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-slate-400">Nombre</label>
                <input 
                  {...register('full_name', { required: true })}
                  className="w-full rounded-lg border border-slate-800 bg-slate-950 px-4 py-2 text-slate-200 focus:border-indigo-500 outline-none transition-all"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-slate-400">Correo</label>
                <input 
                  type="email"
                  {...register('email', { required: true })}
                  className="w-full rounded-lg border border-slate-800 bg-slate-950 px-4 py-2 text-slate-200 focus:border-indigo-500 outline-none transition-all"
                />
              </div>
            </div>
            <div className="flex justify-end pt-4 border-t border-slate-800">
              <button 
                type="submit" 
                disabled={!isDirty || isLoading}
                className="bg-indigo-600 px-6 py-2 rounded-lg font-bold text-white hover:bg-indigo-500 disabled:opacity-50 transition-all shadow-lg shadow-indigo-500/10"
              >
                {isLoading ? 'Guardando...' : 'Guardar Cambios'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};