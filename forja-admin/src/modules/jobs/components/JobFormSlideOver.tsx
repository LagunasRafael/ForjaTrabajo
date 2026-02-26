import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { jobSchema, type JobFormData } from '../schemas/job.schema';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: JobFormData, files: File[]) => void;
}

export const JobFormSlideOver = ({ isOpen, onClose, onSubmit }: Props) => {
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<JobFormData>({
    resolver: zodResolver(jobSchema)
  });

  // Generar miniaturas cuando se seleccionan fotos
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const filesArray = Array.from(e.target.files);
      setSelectedFiles(prev => [...prev, ...filesArray]);

      const newPreviews = filesArray.map(file => URL.createObjectURL(file));
      setPreviews(prev => [...prev, ...newPreviews]);
    }
  };

  const removeImage = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
    setPreviews(prev => prev.filter((_, i) => i !== index));
  };

  const onFormSubmit = (data: JobFormData) => {
    onSubmit(data, selectedFiles);
    reset();
    setSelectedFiles([]);
    setPreviews([]);
  };

  return (
    <div className={`fixed inset-0 z-50 flex justify-end transition-opacity ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      
      <div className={`relative w-full max-w-lg bg-slate-900 h-full shadow-2xl transition-transform duration-300 ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
        <div className="p-6 border-b border-slate-800 flex justify-between items-center">
          <h2 className="text-xl font-bold text-white">Publicar Nueva Oferta</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white">✕</button>
        </div>

        <form onSubmit={handleSubmit(onFormSubmit)} className="p-6 space-y-5 overflow-y-auto h-[calc(100vh-100px)]">
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Título del problema</label>
            <input {...register('title')} className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-white" placeholder="Ej: Fuga de gas en cocina" />
            {errors.title && <p className="text-rose-500 text-xs mt-1">{errors.title.message}</p>}
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Ubicación (Ciudad)</label>
            <input {...register('location_city')} className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-white" placeholder="Ej: Ciudad Hidalgo, Mich." />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">Categoría</label>
              <select {...register('category')} className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-white">
                <option value="Plomería">Plomería</option>
                <option value="Electricidad">Electricidad</option>
                <option value="Carpintería">Carpintería</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Descripción detallada</label>
            <textarea {...register('description')} rows={4} className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-white" placeholder="Explica qué necesitas exactamente..." />
          </div>

          {/* ÁREA DE FOTOS */}
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-2">Fotos del problema (Máx 5)</label>
            <div className="grid grid-cols-3 gap-3 mb-4">
              {previews.map((src, i) => (
                <div key={i} className="relative aspect-square rounded-lg overflow-hidden border border-slate-700">
                  <img src={src} className="w-full h-full object-cover" />
                  <button type="button" onClick={() => removeImage(i)} className="absolute top-1 right-1 bg-rose-600 text-white rounded-full w-5 h-5 text-xs">✕</button>
                </div>
              ))}
              <label className="aspect-square rounded-lg border-2 border-dashed border-slate-700 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500 hover:bg-indigo-500/5 transition-colors">
                <span className="text-2xl text-slate-500">+</span>
                <span className="text-[10px] text-slate-500 uppercase">Subir</span>
                <input type="file" multiple accept="image/*" className="hidden" onChange={handleFileChange} />
              </label>
            </div>
          </div>

          <button type="submit" className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3 rounded-lg shadow-lg shadow-indigo-600/20 transition-all">
            Publicar Oferta
          </button>
        </form>
      </div>
    </div>
  );
};