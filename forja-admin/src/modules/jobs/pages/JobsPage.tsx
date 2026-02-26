import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { JobTable } from '../components/JobTable'; // Suponiendo que moviste la tabla a un componente
import { JobFormSlideOver } from '../components/JobFormSlideOver';
import { createJobApi, getJobsApi } from '../services/job.services';
import type { JobPost } from '../types/job.types';
import type { JobFormData } from '../schemas/job.schema';

export const JobsPage = () => {
  // 1. ESTADOS
  const [jobs, setJobs] = useState<JobPost[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSlideOverOpen, setIsSlideOverOpen] = useState(false);

  // 2. CARGA INICIAL
  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    try {
      const data = await getJobsApi();
      setJobs(data);
    } catch (error) {
      toast.error('Error al conectar con el servidor');
    } finally {
      setIsLoading(false);
    }
  };

  // 3. FUNCIÓNhandleCreateJob (La que hace la magia)
  const handleCreateJob = async (formData: JobFormData, files: File[]) => {
    // Usamos toast.promise para que el admin vea el progreso de subida a AWS
    toast.promise(createJobApi(formData, files), {
      loading: 'Subiendo fotos a AWS y creando oferta...',
      success: (newJob) => {
        setJobs((prev) => [newJob, ...prev]); // Actualización inmediata
        setIsSlideOverOpen(false); // Cerramos el panel
        return 'Oferta publicada con éxito 🚀';
      },
      error: (err) => {
        console.error(err);
        return 'Error al publicar: Revisa tu conexión o el tamaño de las fotos';
      }
    });
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      
      {/* HEADER CON BOTÓN DE ACCIÓN */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Ofertas de Trabajo</h2>
          <p className="text-sm text-slate-400 mt-1">Supervisa y modera las solicitudes del marketplace.</p>
        </div>
        
        <button 
          onClick={() => setIsSlideOverOpen(true)}
          className="flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2.5 rounded-lg font-semibold shadow-lg shadow-indigo-600/20 transition-all active:scale-95"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
          Nueva Oferta
        </button>
      </div>

      {/* TABLA (Pasamos los datos reales) */}
      <JobTable 
        jobs={jobs} 
        isLoading={isLoading} 
        onDelete={(id) => setJobs(jobs.filter(j => j.id !== id))} 
      />

      {/* EL COMPONENTE SLIDEOVER */}
      <JobFormSlideOver 
        isOpen={isSlideOverOpen}
        onClose={() => setIsSlideOverOpen(false)}
        onSubmit={handleCreateJob} // <-- Conectamos la función
      />
      
    </div>
  );
};

export default JobsPage;