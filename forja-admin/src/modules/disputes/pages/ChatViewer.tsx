import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { getConversationMessagesApi } from '../services/disputes.service';
import type { Message } from '../types/dispute.types';

export const ChatViewer = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (id) {
      loadMessages(id);
    }
  }, [id]);

  const loadMessages = async (conversationId: string) => {
    try {
      const data = await getConversationMessagesApi(conversationId);
      setMessages(data);
    } catch (error) {
      toast.error('Error al cargar los mensajes');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500 h-[calc(100vh-8rem)] flex flex-col">
      
      {/* HEADER */}
      <div className="flex items-center gap-4 shrink-0">
        <button 
          onClick={() => navigate('/disputes')}
          className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-colors"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">Visor de Chat</h2>
          <p className="text-xs text-slate-400 mt-1">Modo lectura para administradores (Disputas)</p>
        </div>
      </div>

      {/* CHAT BOX */}
      <div className="flex-1 rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm overflow-hidden shadow-xl flex flex-col relative">
        
        <div className="p-4 border-b border-slate-800 bg-slate-900 flex justify-between items-center shrink-0">
          <span className="text-sm font-medium text-slate-300">Historial de mensajes</span>
          <span className="text-xs px-2 py-1 bg-amber-500/10 text-amber-500 rounded ring-1 ring-amber-500/20">Solo Lectura</span>
        </div>

        <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-6 scrollbar-thin scrollbar-track-slate-900 scrollbar-thumb-slate-700">
          {isLoading ? (
            <div className="flex justify-center items-center h-full">
              <span className="text-slate-500 animate-pulse">Cargando mensajes...</span>
            </div>
          ) : messages.length === 0 ? (
            <div className="flex justify-center items-center h-full">
              <span className="text-slate-500">No hay mensajes en este chat.</span>
            </div>
          ) : (
            messages.map((msg, idx) => {
              // Agrupamos los mensajes para ver si cambia el sender
              const isNewSender = idx === 0 || messages[idx - 1].sender_id !== msg.sender_id;
              
              // Determinar color de burbuja de manera determinista (pseudo-hash del ID)
              const isClient = msg.sender_name.toLowerCase().includes('cliente') || msg.sender_id.charCodeAt(0) % 2 === 0;

              return (
                <div key={msg.id} className={`flex flex-col ${isClient ? 'items-end' : 'items-start'}`}>
                  {isNewSender && (
                    <span className="text-xs text-slate-500 mb-1 ml-1 mr-1">
                      {msg.sender_name}
                    </span>
                  )}
                  <div className={`max-w-[80%] sm:max-w-[70%] rounded-2xl px-4 py-2.5 text-sm ${
                    isClient 
                      ? 'bg-indigo-600 text-white rounded-tr-sm' 
                      : 'bg-slate-800 text-slate-200 rounded-tl-sm'
                  }`}>
                    {msg.message_type === 'offer' ? (
                      <div className="flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2v20"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                        <span className="font-semibold">Oferta enviada: {msg.content}</span>
                      </div>
                    ) : (
                      <p className="whitespace-pre-wrap">{msg.content}</p>
                    )}
                  </div>
                  <span className="text-[10px] text-slate-600 mt-1">
                    {new Date(msg.created_at).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              );
            })
          )}
        </div>
      </div>
      
    </div>
  );
};

export default ChatViewer;
