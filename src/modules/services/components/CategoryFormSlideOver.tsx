import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import type { Category } from '../services/category.service';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: { name: string; description: string }) => void;
  initialData?: Category | null;
}

export const CategoryFormSlideOver = ({ isOpen, onClose, onSubmit, initialData }: Props) => {
  // Extraemos 'errors' para mostrar el feedback visual
  const { register, handleSubmit, reset, formState: { errors } } = useForm({
    defaultValues: { name: '', description: '' }
  });

  useEffect(() => {
    if (isOpen) {
      reset({
        name: initialData?.name || '',
        description: initialData?.description || ''
      });
    }
  }, [isOpen, initialData, reset]);

  const panelClass = isOpen ? 'translate-x-0' : 'translate-x-full';

  return (
    <div className={`fixed inset-0 z-50 flex justify-end ${isOpen ? '' : 'pointer-events-none'}`}>
      <div className={`absolute inset-0 bg-slate-950/60 backdrop-blur-sm transition-opacity duration-300 ${isOpen ? 'opacity-100' : 'opacity-0'}`} onClick={onClose} />
      
      <div className={`relative h-full w-full max-w-md bg-slate-900 border-l border-slate-800 p-6 transition-transform duration-300 ease-in-out ${panelClass}`}>
        <h2 className="text-xl font-bold text-white mb-6">
          {initialData ? 'Editar Oficio' : 'Nuevo Oficio'}
        </h2>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm text-slate-400">Nombre</label>
            {/* Agregamos validación requerida y trim para evitar espacios vacíos */}
            <input 
              {...register('name', { 
                required: "El nombre es obligatorio",
                validate: value => value.trim() !== "" || "El nombre no puede estar vacío"
              })} 
              className={`w-full bg-slate-950 border rounded-lg px-4 py-2 text-white outline-none focus:ring-2 transition-all ${
                errors.name ? 'border-rose-500 focus:ring-rose-500/20' : 'border-slate-800 focus:ring-indigo-500/50'
              }`} 
              placeholder="Ej: Plomería"
            />
            {/* Mensaje de error dinámico */}
            {errors.name && (
              <span className="text-xs text-rose-500 font-medium animate-in fade-in slide-in-from-top-1">
                {errors.name.message as string}
              </span>
            )}
          </div>

          <div className="space-y-2">
            <label className="text-sm text-slate-400">Descripción</label>
            <textarea 
              {...register('description')} 
              rows={4} 
              className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-2 text-white outline-none focus:ring-2 focus:ring-indigo-500/50 transition-all" 
              placeholder="Describe las tareas de este oficio..."
            />
          </div>

          <div className="pt-4 flex gap-3">
            <button 
              type="button" 
              onClick={onClose} 
              className="flex-1 px-4 py-2 text-slate-400 hover:text-white transition-colors"
            >
              Cancelar
            </button>
            <button 
              type="submit" 
              className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white py-2 rounded-lg font-bold transition-all shadow-lg shadow-indigo-600/20 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Guardar Cambios
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};