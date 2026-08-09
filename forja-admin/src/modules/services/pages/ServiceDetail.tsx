import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { ConfirmModal } from '../../../components/ConfirmModal';
import { 
  ArrowLeft, MapPin, DollarSign, Clock, User, 
  ShieldCheck, ShieldAlert, ExternalLink, Box, Trash2
} from 'lucide-react';
import { getServiceById, toggleServiceActive, type ServiceEntity, getServiceOffers,deleteServiceAdmin } from '../services/service.service';



export const ServiceDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [service, setService] = useState<ServiceEntity | null>(null);
  const [loading, setLoading] = useState(true);
  const [offers, setOffers] = useState<any[]>([]);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Carga de datos
  useEffect(() => {
  const loadFullData = async () => {
    try {
      setLoading(true);
      
      // Traemos el servicio y las ofertas
      const serviceData = await getServiceById(id!); 
      const offersData = await getServiceOffers(id!); 
      
      // Guardamos los datos
      setService(serviceData);
      setOffers(offersData); 
    } catch (error) {
      toast.error("Error al sincronizar con FastAPI");
    } finally {
      setLoading(false);
    }
  };

  loadFullData();
}, [id]);

  // 🛡️ Lógica para Deshabilitar/Habilitar
  const handleToggleStatus = async () => {
    if (!service) return;
    try {
      // Llamamos al PATCH (Asegúrate de que Juan Luis lo haya creado)
      const updated = await toggleServiceActive(service.id, !service.isActive);
      setService(updated);
      toast.success(updated.isActive ? 'Publicación Visible' : 'Publicación Oculta');
    } catch (error) {
      toast.error('Error al cambiar la visibilidad. ¿El backend tiene la ruta?');
    }
  };

  // 🗑️ Lógica para Eliminar Definitivamente
  const handleDelete = async () => {
    if (!service) return;

    setIsDeleting(true);
    try {
      await deleteServiceAdmin(service.id);
      toast.success('Servicio eliminado de la base de datos');
      setShowDeleteConfirm(false);
      navigate('/services');
    } catch (error) {
      toast.error('Error al eliminar el servicio');
      setIsDeleting(false);
    }
  };

  if (loading) return <div className="p-20 text-center text-slate-500 animate-pulse font-mono">Obteniendo datos de FastAPI...</div>;
  if (!service) return <div className="p-20 text-center text-rose-500 font-bold">404: Servicio no encontrado</div>;

  return (
    <div className="space-y-6 animate-in fade-in duration-500 max-w-7xl mx-auto">
      
      {/* --- CABECERA DE ACCIONES --- */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <button 
          onClick={() => navigate(-1)}
          className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors text-sm font-medium w-fit"
        >
          <ArrowLeft size={16} /> Volver al listado
        </button>
        
        <div className="flex items-center gap-3">
          {/* BOTÓN 1: DESHABILITAR / HABILITAR */}
          <button 
            onClick={handleToggleStatus}
            className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-bold border transition-all ${
              service.isActive 
              ? 'bg-amber-500/10 text-amber-500 border-amber-500/20 hover:bg-amber-500/20' 
              : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
            }`}
          >
            {service.isActive ? <ShieldAlert size={16} /> : <ShieldCheck size={16} />}
            {service.isActive ? 'Ocultar Publicación' : 'Reactivar Publicación'}
          </button>

          {/* BOTÓN 2: ELIMINAR DEFINITIVAMENTE */}
          <button 
            onClick={() => setShowDeleteConfirm(true)}
            className="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-bold border transition-all bg-rose-500/10 text-rose-500 border-rose-500/20 hover:bg-rose-500/20 hover:text-rose-400"
          >
            <Trash2 size={16} />
            Eliminar
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* --- COLUMNA DE CONTENIDO (Descripción y S3) --- */}
        <div className="lg:col-span-2 space-y-6">
          <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-8 backdrop-blur-md shadow-xl">
            <div className="flex justify-between items-start mb-6">
              <div>
                <div className="flex items-center gap-3 mb-2 text-indigo-400 font-mono text-[10px] tracking-widest uppercase">
                  <Box size={14} /> UUID: {service.id}
                </div>
                <h1 className="text-3xl font-black text-white tracking-tight">{service.title}</h1>
              </div>
              <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-tighter ${
                service.isActive ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'
              }`}>
                {service.isActive ? 'Visible' : 'Oculto'}
              </span>
            </div>

            <p className="text-slate-300 leading-relaxed text-lg mb-10 border-l-2 border-indigo-500/30 pl-6 italic">
              {service.description}
            </p>

            {/* Galería de AWS S3 */}
            <h3 className="mb-4 text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Evidencias de Trabajo (AWS S3)</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {service.imageUrls.map((url, index) => (
                <div key={index} className="group relative aspect-video rounded-xl border border-slate-800 overflow-hidden bg-slate-950">
                  <img src={url} alt="Evidencia" className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110 opacity-80 group-hover:opacity-100" />
                  <a 
                    href={url} target="_blank" rel="noreferrer"
                    className="absolute inset-0 flex items-center justify-center bg-slate-950/40 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <ExternalLink className="text-white" size={24} />
                  </a>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* --- COLUMNA DE METADATOS (Ficha Técnica) --- */}
        <div className="space-y-6">
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6 shadow-2xl">
            <h3 className="mb-6 text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Ficha de Moderación</h3>
            
            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 shadow-inner">
                  <DollarSign size={24} />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-slate-500 uppercase tracking-tighter">Precio Base Sugerido</p>
                  <p className="text-xl font-black text-white">${service.basePrice.toLocaleString()} MXN</p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-400">
                  <User size={24} />
                </div>
                <div className="overflow-hidden">
                  <p className="text-[10px] font-bold text-slate-500 uppercase tracking-tighter">ID del Cliente</p>
                  <p className="text-xs font-mono text-slate-300 truncate">{service.clientId}</p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-400">
                  <Clock size={24} />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-slate-500 uppercase tracking-tighter">Fecha de Creación</p>
                  <p className="text-sm font-bold text-slate-200">{new Date(service.createdAt).toLocaleDateString('es-MX', { day: '2-digit', month: 'long', year: 'numeric' })}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Sección de Geolocalización */}
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-6">
             <div className="flex items-center gap-2 mb-4 text-rose-500">
                <MapPin size={18} />
                <h3 className="text-[10px] font-bold uppercase tracking-[0.2em]">Ubicación Registrada</h3>
             </div>
             
             {/* 🟢 CONTENEDOR DEL MAPA REAL */}
             <div className="h-64 w-full rounded-xl bg-slate-950 border border-slate-800 flex flex-col items-center justify-center text-slate-600 mb-4 overflow-hidden relative">
                
                {service.location.lat && service.location.lng ? (
                  <iframe 
                    title="Mapa de ubicación del servicio"
                    width="100%" 
                    height="100%" 
                    style={{ border: 0 }} 
                    loading="lazy" 
                    allowFullScreen 
                    referrerPolicy="no-referrer-when-downgrade" 
                    // Pasamos la latitud y longitud directamente a la URL de Google Maps
                    src={`https://maps.google.com/maps?q=${service.location.lat},${service.location.lng}&z=16&output=embed`}
                    className="absolute inset-0 w-full h-full"
                  ></iframe>
                ) : (
                  <span className="text-xs font-mono">Coordenadas no disponibles</span>
                )}

             </div>

             <p className="text-sm text-slate-300 leading-snug font-medium text-center">
               {service.location.address || "Dirección no especificada"}
             </p>
          </div>
        </div>
      </div>
      {/* 🟢 Agregar esto al final, antes del último </div> */}
<div className="mt-8">
  <h2 className="text-xl font-bold text-white mb-4">Postulaciones Recibidas</h2>
  {offers.length === 0 ? (
    <div className="p-8 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-2xl bg-slate-900/20">
      <p className="font-medium">No se han recibido postulaciones para este servicio.</p>
    </div>
  ) : (
    <div className="grid grid-cols-1 gap-4">
      {offers.map((offer) => (
        <div key={offer.id} className="p-4 rounded-xl border border-slate-800 bg-slate-900 hover:border-indigo-500/30 transition-all">
          <div className="flex items-center gap-3 mb-3">
            <div className="h-8 w-8 rounded-full bg-indigo-500/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400 text-xs font-bold uppercase">
              {(offer.workerName || 'T').charAt(0)}
            </div>
            <div>
              <p className="text-sm font-bold text-slate-200">{offer.workerName || 'Trabajador'}</p>
              <p className="text-[10px] text-slate-500 uppercase tracking-tighter">{offer.status}</p>
            </div>
            <div className="ml-auto text-emerald-400 font-black text-lg">
              ${offer.proposedPrice?.toLocaleString() || '0'}
            </div>
          </div>
          {offer.description && (
            <p className="text-xs text-slate-400 leading-relaxed pl-11 border-l border-slate-800 ml-4">
              "{offer.description}"
            </p>
          )}
        </div>
      ))}

      <ConfirmModal
        isOpen={showDeleteConfirm}
        onClose={() => setShowDeleteConfirm(false)}
        onConfirm={handleDelete}
        title="Eliminar servicio"
        message="¿Estás seguro de ELIMINAR este servicio? Esta acción no se puede deshacer."
        confirmLabel="Eliminar"
        confirmClass="bg-red-600 hover:bg-red-500"
        isLoading={isDeleting}
      />
    </div>
  )}
    </div>
    </div>
  );

};
