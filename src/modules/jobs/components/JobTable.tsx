import type { JobPost, JobStatus } from '../types/job.types';

interface JobTableProps {
  jobs: JobPost[];
  isLoading: boolean;
  onDelete: (id: string) => void;
}

export const JobTable = ({ jobs, isLoading, onDelete }: JobTableProps) => {
  
  const statusStyles: Record<JobStatus, { label: string; color: string; dot: string }> = {
    open: { label: 'Buscando', color: 'bg-blue-500/10 text-blue-400 ring-blue-500/20', dot: 'bg-blue-500' },
    matched: { label: 'En Proceso', color: 'bg-emerald-500/10 text-emerald-400 ring-emerald-500/20', dot: 'bg-emerald-500' },
    completed: { label: 'Terminado', color: 'bg-purple-500/10 text-purple-400 ring-purple-500/20', dot: 'bg-purple-500' },
    cancelled: { label: 'Cancelado', color: 'bg-slate-500/10 text-slate-400 ring-slate-500/20', dot: 'bg-slate-500' },
  };

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm overflow-hidden shadow-xl">
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm text-slate-300">
          <thead className="border-b border-slate-800 bg-slate-900/50 text-xs uppercase text-slate-400">
            <tr>
              <th scope="col" className="px-6 py-4 font-semibold">Oferta / Ubicación</th>
              <th scope="col" className="px-6 py-4 font-semibold">Fotos</th>
              <th scope="col" className="px-6 py-4 font-semibold">Categoría</th>
              <th scope="col" className="px-6 py-4 font-semibold">Estado</th>
              <th scope="col" className="px-6 py-4 font-semibold text-right">Acciones</th>
            </tr>
          </thead>
          
          <tbody className="divide-y divide-slate-800">
            {isLoading ? (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center text-slate-500 animate-pulse">Cargando ofertas de trabajo...</td>
              </tr>
            ) : jobs.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center text-slate-500">No hay publicaciones activas.</td>
              </tr>
            ) : (
              jobs.map((job) => (
                <tr key={job.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-200">{job.title}</div>
                    <div className="text-xs text-slate-500 flex items-center gap-1 mt-1">
                      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                      {job.location_city}
                    </div>
                  </td>

                  {/* MINIATURAS DE AWS S3 */}
                  <td className="px-6 py-4">
                    <div className="flex -space-x-2 overflow-hidden">
                      {job.image_urls.length > 0 ? (
                        job.image_urls.map((url, index) => (
                          <img 
                            key={index} 
                            src={url} 
                            alt={`Preview ${index}`} 
                            className="inline-block h-8 w-8 rounded-full ring-2 ring-slate-900 object-cover hover:scale-110 transition-transform cursor-pointer"
                          />
                        ))
                      ) : (
                        <span className="text-xs text-slate-600">Sin fotos</span>
                      )}
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <span className="text-slate-400">{job.category}</span>
                  </td>

                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${statusStyles[job.status].color}`}>
                      <span className={`h-1.5 w-1.5 rounded-full ${statusStyles[job.status].dot}`}></span>
                      {statusStyles[job.status].label}
                    </span>
                  </td>

                  <td className="px-6 py-4 text-right">
                    <button 
                      onClick={() => onDelete(job.id)}
                      className="p-2 text-slate-500 hover:text-rose-400 transition-colors"
                      title="Eliminar publicación"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};