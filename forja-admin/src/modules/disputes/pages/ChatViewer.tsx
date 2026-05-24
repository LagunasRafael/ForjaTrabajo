import { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { toast } from 'sonner';
import { getConversationMessagesApi, sendAdminMessageApi, resolveDisputeApi } from '../services/disputes.service';
import { useWebSocketChat } from '../../../hooks/useWebSocketChat';
import type { Message } from '../types/dispute.types';

export const ChatViewer = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const clientName = searchParams.get('client') || '';
  const workerName = searchParams.get('worker') || '';

  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [adminMessage, setAdminMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isResolving, setIsResolving] = useState(false);
  const [showResolveModal, setShowResolveModal] = useState(false);

  const { isConnected, lastMessage } = useWebSocketChat(id);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback((behavior: ScrollBehavior = 'smooth') => {
    if (messagesContainerRef.current) {
      messagesContainerRef.current.scrollTo({
        top: messagesContainerRef.current.scrollHeight,
        behavior,
      });
    }
  }, []);

  useEffect(() => {
    if (!isLoading && messages.length > 0) {
      scrollToBottom('instant');
    }
  }, [isLoading, messages.length, scrollToBottom]);

  useEffect(() => {
    if (lastMessage) {
      scrollToBottom('smooth');
    }
  }, [lastMessage, scrollToBottom]);

  useEffect(() => {
    if (id) {
      loadMessages(id);
    }
  }, [id]);

  const addMessageToState = useCallback((newMsg: Message) => {
    setMessages(prev => {
      if (prev.some(m => m.id === newMsg.id)) return prev;
      return [...prev, newMsg];
    });
  }, []);

  useEffect(() => {
    if (lastMessage) {
      console.log('[ChatViewer] New WebSocket message received:', lastMessage);
      addMessageToState(lastMessage as Message);
    }
  }, [lastMessage, addMessageToState]);

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

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminMessage.trim() || !id) return;

    try {
      setIsSending(true);
      await sendAdminMessageApi(id, adminMessage.trim());
      setAdminMessage('');
      toast.success('Mensaje enviado');
    } catch (error) {
      toast.error('Error al enviar mensaje');
    } finally {
      setIsSending(false);
    }
  };

  const handleResolve = async (winner: 'client' | 'worker') => {
    if (!id) return;
    try {
      setIsResolving(true);
      await resolveDisputeApi(id, winner);
      toast.success('Disputa resuelta exitosamente');
      setShowResolveModal(false);
      await loadMessages(id); // Recargar
    } catch (error) {
      toast.error('Error al resolver la disputa');
    } finally {
      setIsResolving(false);
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
          <h2 className="text-xl font-bold text-white tracking-tight">Visor de Chat y Mediación</h2>
          <p className="text-xs text-slate-400 mt-1">Modo administrador (Disputas)</p>
        </div>
      </div>

      <div className="flex gap-4 shrink-0">
        <button 
          onClick={() => setShowResolveModal(true)}
          className="px-4 py-2 bg-red-600 hover:bg-red-500 text-white rounded-lg text-sm font-semibold transition-colors flex items-center gap-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
          Resolver Disputa
        </button>
      </div>

      {/* CHAT BOX */}
      <div className="flex-1 rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm overflow-hidden shadow-xl flex flex-col relative">
        
        <div className="p-4 border-b border-slate-800 bg-slate-900 flex justify-between items-center shrink-0">
          <span className="text-sm font-medium text-slate-300">Historial de mensajes</span>
          <div className="flex items-center gap-2">
            <span className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`}></span>
            <span className="text-xs px-2 py-1 bg-amber-500/10 text-amber-500 rounded ring-1 ring-amber-500/20">Solo Lectura</span>
          </div>
        </div>

        <div ref={messagesContainerRef} className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-6 scrollbar-thin scrollbar-track-slate-900 scrollbar-thumb-slate-700">
          {isLoading ? (
            <div className="flex justify-center items-center h-full">
              <span className="text-slate-500 animate-pulse">Cargando mensajes...</span>
            </div>
          ) : messages.length === 0 ? (
            <div className="flex justify-center items-center h-full">
              <span className="text-slate-500">No hay mensajes en este chat.</span>
            </div>
          ) : (
            (() => {
              // Identificar remitentes no-sistema para el fallback dinámico
              const nonSystemSenders = Array.from(
                new Set(messages.filter(m => m.message_type !== 'system').map(m => m.sender_id))
              );

              return messages.map((msg, idx) => {
                // Agrupamos los mensajes para ver si cambia el sender
                const isNewSender = idx === 0 || messages[idx - 1].sender_id !== msg.sender_id;
                
                const isSystem = msg.message_type === 'system';
                
                // Determinar alineación usando los nombres de cliente y trabajador pasados por navegación
                let isClient = false;
                if (clientName && workerName && msg.sender_name) {
                  // Comparación insensible a mayúsculas/minúsculas y espacios
                  isClient = msg.sender_name.trim().toLowerCase() === clientName.trim().toLowerCase();
                } else {
                  // Fallback dinámico ultra-robusto: el primer emisor va a la izquierda (trabajador), el segundo a la derecha (cliente)
                  const senderIndex = nonSystemSenders.indexOf(msg.sender_id);
                  isClient = senderIndex === 1; // Si es el segundo emisor único, va a la derecha (cliente)
                }

                return (
                  <div key={msg.id} className={`flex flex-col ${isSystem ? 'items-center w-full' : isClient ? 'items-end' : 'items-start'}`}>
                    {isNewSender && !isSystem && (
                      <span className="text-xs text-slate-500 mb-1 ml-1 mr-1">
                        {msg.sender_name || 'Usuario'}
                      </span>
                    )}
                    <div className={`${isSystem ? 'max-w-[90%] text-center border border-red-500/30' : 'max-w-[80%] sm:max-w-[70%]'} rounded-2xl px-4 py-2.5 text-sm ${
                      isSystem ? 'bg-red-900/20 text-red-200' :
                      isClient 
                        ? 'bg-indigo-600 text-white rounded-tr-sm' 
                        : 'bg-slate-800 text-slate-200 rounded-tl-sm'
                    }`}>
                      {msg.message_type === 'offer' ? (
                        <div className="flex items-center gap-2">
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2v20"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                          <span className="font-semibold">Oferta enviada: {msg.content}</span>
                        </div>
                      ) : msg.message_type === 'image' || msg.message_type === 'gallery' ? (
                        <div className="space-y-2">
                          <img 
                            src={msg.content} 
                            alt="Evidencia" 
                            className="max-w-xs sm:max-w-sm rounded-lg object-contain border border-slate-700/50 hover:opacity-90 transition-opacity cursor-pointer shadow-md bg-slate-950/20"
                            onClick={() => window.open(msg.content, '_blank')}
                          />
                          <span className="text-[10px] text-slate-400 block italic">Haz clic para abrir en grande</span>
                        </div>
                      ) : msg.message_type === 'audio' || (msg.content.startsWith('http') && (msg.content.endsWith('.m4a') || msg.content.endsWith('.mp3') || msg.content.endsWith('.wav') || msg.content.endsWith('.ogg') || msg.content.endsWith('.aac') || msg.content.endsWith('.opus'))) ? (
                        <div className="space-y-2 py-1 min-w-[240px]">
                          <div className="flex items-center gap-2 text-xs text-slate-300 font-medium">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-indigo-400"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" x2="12" y1="19" y2="22"/></svg>
                            <span>Nota de voz</span>
                          </div>
                          <audio 
                            src={msg.content} 
                            controls 
                            className="w-full max-w-xs h-9 rounded-lg"
                          />
                        </div>
                      ) : msg.content.startsWith('http') ? (
                        <a 
                          href={msg.content} 
                          target="_blank" 
                          rel="noreferrer" 
                          className="text-indigo-400 hover:text-indigo-300 underline break-all flex items-center gap-1.5"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
                          Ver archivo adjunto
                        </a>
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
          })()
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* ADMIN INPUT AREA */}
        <form onSubmit={handleSendMessage} className="p-4 bg-slate-900 border-t border-slate-800 flex gap-3 shrink-0">
          <input
            type="text"
            value={adminMessage}
            onChange={(e) => setAdminMessage(e.target.value)}
            placeholder="Escribe un mensaje como Administrador para pedir evidencia..."
            className="flex-1 bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-sm text-white focus:outline-none focus:border-indigo-500 transition-colors"
            disabled={isSending}
          />
          <button
            type="submit"
            disabled={isSending || !adminMessage.trim()}
            className="bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-700 disabled:text-slate-500 text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2"
          >
            {isSending ? 'Enviando...' : 'Enviar'}
          </button>
        </form>
      </div>

      {/* RESOLVE MODAL */}
      {showResolveModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
            <div className="p-6">
              <h3 className="text-xl font-bold text-white mb-2">Resolver Disputa</h3>
              <p className="text-sm text-slate-400 mb-6">
                Selecciona quién es el ganador de la disputa en base a la evidencia proporcionada. Esta acción es <b>irreversible</b> y notificará a ambas partes.
              </p>
              
              <div className="space-y-3">
                <button 
                  onClick={() => handleResolve('client')}
                  disabled={isResolving}
                  className="w-full text-left p-4 rounded-xl border border-slate-700 bg-slate-800 hover:border-indigo-500 hover:bg-slate-800/80 transition-colors group"
                >
                  <div className="font-semibold text-white group-hover:text-indigo-400">A favor del Cliente (Reembolso)</div>
                  <div className="text-xs text-slate-400 mt-1">El dinero congelado será devuelto a la tarjeta del cliente y el trabajo se cancelará.</div>
                </button>

                <button 
                  onClick={() => handleResolve('worker')}
                  disabled={isResolving}
                  className="w-full text-left p-4 rounded-xl border border-slate-700 bg-slate-800 hover:border-emerald-500 hover:bg-slate-800/80 transition-colors group"
                >
                  <div className="font-semibold text-white group-hover:text-emerald-400">A favor del Trabajador (Pago)</div>
                  <div className="text-xs text-slate-400 mt-1">El dinero congelado será liberado al trabajador como pago por sus servicios.</div>
                </button>
              </div>
            </div>
            <div className="p-4 border-t border-slate-800 bg-slate-900/50 flex justify-end">
              <button 
                onClick={() => setShowResolveModal(false)}
                disabled={isResolving}
                className="px-4 py-2 text-sm font-medium text-slate-300 hover:text-white"
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}
      
    </div>
  );
};

export default ChatViewer;
