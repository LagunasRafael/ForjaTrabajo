import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useNavigate } from 'react-router-dom';
import { getConversationsApi } from '../services/disputes.service';
import type { Conversation } from '../types/dispute.types';

export const DisputesPage = () => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    loadConversations();
  }, []);

  const loadConversations = async () => {
    try {
      const data = await getConversationsApi();
      setConversations(data);
    } catch (error) {
      toast.error('Error al cargar conversaciones');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      
      {/* HEADER */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Disputas (Visor de Chats)</h2>
          <p className="text-sm text-slate-400 mt-1">Supervisa las conversaciones entre clientes y trabajadores.</p>
        </div>
      </div>

      {/* TABLA DE CONVERSACIONES */}
      <div className="rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="border-b border-slate-800 bg-slate-900/50 text-xs uppercase text-slate-400">
              <tr>
                <th scope="col" className="px-6 py-4 font-semibold">Cliente</th>
                <th scope="col" className="px-6 py-4 font-semibold">Trabajador</th>
                <th scope="col" className="px-6 py-4 font-semibold">Estado</th>
                <th scope="col" className="px-6 py-4 font-semibold">Última Actividad</th>
                <th scope="col" className="px-6 py-4 font-semibold text-right">Acciones</th>
              </tr>
            </thead>
            
            <tbody className="divide-y divide-slate-800">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-500 animate-pulse">Cargando conversaciones...</td>
                </tr>
              ) : conversations.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-500">No hay conversaciones activas.</td>
                </tr>
              ) : (
                conversations.map((conv) => (
                  <tr key={conv.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4">
                      <div className="font-medium text-slate-200">{conv.client_name}</div>
                    </td>

                    <td className="px-6 py-4">
                      <div className="text-slate-300">{conv.worker_name}</div>
                    </td>

                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${
                        conv.status === 'open' 
                          ? 'bg-emerald-500/10 text-emerald-400 ring-emerald-500/20' 
                          : 'bg-slate-500/10 text-slate-400 ring-slate-500/20'
                      }`}>
                        {conv.status === 'open' ? 'Abierto' : 'Cerrado'}
                      </span>
                    </td>

                    <td className="px-6 py-4 text-slate-400">
                      {new Date(conv.updated_at).toLocaleString('es-MX')}
                    </td>

                    <td className="px-6 py-4 text-right">
                      <button 
                        onClick={() => navigate(`/disputes/${conv.id}`)}
                        className="text-indigo-400 hover:text-indigo-300 text-sm font-medium transition-colors"
                      >
                        Ver Chat &rarr;
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
      
    </div>
  );
};

export default DisputesPage;
