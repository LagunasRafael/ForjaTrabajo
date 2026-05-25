import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAutoRefresh } from '../../../hooks/useAutoRefresh';
import api from '../../../api/client';

interface ReportedService {
  id: string;
  title: string;
  description: string;
  owner_name: string;
  category_name: string;
  is_active: boolean;
  created_at: string;
  report_count: number;
}

export const ReportedServicesPage = () => {
  const [services, setServices] = useState<ReportedService[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchReportedServices = async () => {
    try {
      const response = await api.get('/services/admin/reported-services');
      setServices(response.data);
    } catch (e) {
      toast.error('Error al cargar servicios reportados');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReportedServices();
  }, []);

  useAutoRefresh(fetchReportedServices, 30000);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Servicios Reportados</h1>
        <p className="text-slate-400 mt-1">Publicaciones que han recibido reportes de usuarios</p>
      </div>

      {services.length === 0 ? (
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-12 text-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="mx-auto text-slate-600 mb-4"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/></svg>
          <h3 className="text-lg font-semibold text-white">No hay servicios reportados</h3>
          <p className="text-slate-400 mt-2">Todas las publicaciones están limpias</p>
        </div>
      ) : (
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 overflow-hidden">
          <table className="w-full text-left">
            <thead className="border-b border-slate-800 bg-slate-900/80">
              <tr>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Servicio</th>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Propietario</th>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Categoría</th>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Reportes</th>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Estado</th>
                <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {services.map((service) => (
                <tr key={service.id} className="hover:bg-slate-800/50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-white">{service.title}</div>
                    <div className="text-sm text-slate-500 truncate max-w-xs">{service.description}</div>
                  </td>
                  <td className="px-6 py-4 text-slate-300">{service.owner_name}</td>
                  <td className="px-6 py-4 text-slate-300">{service.category_name}</td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-500/10 text-red-400">
                      {service.report_count}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      service.is_active ? 'bg-green-500/10 text-green-400' : 'bg-slate-500/10 text-slate-400'
                    }`}>
                      {service.is_active ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => {
                        window.location.href = `/services/${service.id}`;
                      }}
                      className="text-sm font-medium text-indigo-400 hover:text-indigo-300 transition-colors"
                    >
                      Ver detalle
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
