import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Eye, PlusCircle, Search } from 'lucide-react';
import { getServices, createService } from '../services/service.service';
import { getCategories } from '../services/category.service';
import { getUsersApi } from '../../users/services/user.service';

export const ServicesPage = () => {
  const navigate = useNavigate();
  const [services, setServices] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [users, setUsers] = useState<any[]>([]);
  
  // 🟢 Estado de las pestañas
  const [filterMode, setFilterMode] = useState<'active' | 'inactive' | 'MATCHED' | 'COMPLETED' |'all'>('active');

  useEffect(() => {
    const fetchAllData = async () => {
      try {
        setIsLoading(true);
        const [servicesData, categoriesData, usersData] = await Promise.all([
          getServices(),
          getCategories(),
          getUsersApi()
        ]);

        console.log("👀 RAW DATA DE FASTAPI:", servicesData); // 🟢 Agrega esto temporalmente
        
        setServices(servicesData);
        setCategories(categoriesData);
        setUsers(usersData);
      } catch (error) {
        toast.error('Error de sincronización con el servidor');
      } finally {
        setIsLoading(false);
      }
    };
    fetchAllData();
  }, []);

  // 🟢 LÓGICA COMBINADA: Pestañas + Buscador
  const filteredServices = useMemo(() => {
    return services.filter(service => {
      // 1. Normalizamos a MAYÚSCULAS para comparar con seguridad
      const currentStatus = (service.status || 'OPEN').toUpperCase();
      
      let statusMatch = false;

      if (filterMode === 'active') {
        // Pestaña Activas: Está activo Y no ha sido aceptado
        statusMatch = service.isActive === true && currentStatus === 'OPEN';
      } 
      else if (filterMode === 'inactive') {
        // Pestaña Baneadas: Solo las que tú deshabilitaste
        statusMatch = service.isActive === false && currentStatus !== 'MATCHED';
      } 
      else if (filterMode === 'MATCHED') {
        // 🟢 Pestaña En Proceso: SOLO los que tienen el estado MATCHED
        // Aquí ignoramos el isActive, porque un trabajo aceptado ya no está "activo" en el mercado
        statusMatch = currentStatus === 'MATCHED';
      } 
      else if (filterMode === 'COMPLETED') {
      statusMatch = currentStatus === 'COMPLETED';
      }
      else {
        statusMatch = true; // 'all'
      }

      const searchMatch = 
        service.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        service.description?.toLowerCase().includes(searchTerm.toLowerCase());

      return statusMatch && searchMatch;
    });
  }, [services, searchTerm, filterMode]);

  // Funciones de ayuda
  const getCategoryName = (categoryId: string) => {
    const cat = categories.find(c => c.id === categoryId);
    return cat ? cat.name : 'Sin Categoría';
  };

  const getUserName = (clientId: string) => {
    const user = users.find(u => u.id === clientId);
    return user ? user.full_name : 'Usuario Desconocido';
  };

  const handleCreateTestService = async () => {
    if (categories.length === 0) {
      toast.error('Crea una categoría primero para poder vincular la prueba');
      return;
    }
    try {
      const payloadPrueba = {
        title: "Servicio de Prueba Admin",
        description: "Generado desde el panel de React para validar sincronización.",
        base_price: 1200.00,
        category_id: categories[0].id
      };
      await createService(payloadPrueba as any); 
      toast.success('¡Publicación de prueba enviada a FastAPI!');
      setTimeout(() => window.location.reload(), 1000);
    } catch (error) {
      toast.error('Fallo en la conexión con el Backend');
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500 max-w-7xl mx-auto">
      
      {/* --- HEADER Y BUSCADOR --- */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Publicaciones del Mercado</h2>
          <p className="text-slate-400 text-sm mt-1">Gestión y moderación de ofertas en Ciudad Hidalgo.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={16} />
            <input 
              type="text"
              placeholder="Buscar servicio..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-xl text-sm text-slate-200 focus:ring-2 focus:ring-indigo-500/50 outline-none transition-all w-64"
            />
          </div>
          <button 
            onClick={handleCreateTestService}
            className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2 rounded-xl text-sm font-bold transition-all shadow-lg shadow-indigo-600/20"
          >
            <PlusCircle size={18} /> Prueba
          </button>
        </div>
      </div>

      {/* --- PESTAÑAS (TABS) --- */}
      <div className="flex items-center gap-2 bg-slate-900 p-2 rounded-xl w-fit border border-slate-800 mb-6">
        <button
          onClick={() => setFilterMode('active')}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
            filterMode === 'active' ? 'bg-indigo-500 text-white shadow-md' : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Publicaciones Activas
        </button>

        <button
          onClick={() => setFilterMode('MATCHED')}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
            filterMode === 'MATCHED' ? 'bg-emerald-500 text-white shadow-md' : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          En Proceso 
        </button>

        <button
          onClick={() => setFilterMode('COMPLETED')}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
            filterMode === 'COMPLETED' 
              ? 'bg-blue-500 text-white shadow-md' 
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Terminados 
        </button>
        
        <button
          onClick={() => setFilterMode('inactive')}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
            filterMode === 'inactive' ? 'bg-rose-500 text-white shadow-md' : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Deshabilitadas / Baneadas
        </button>

        <button
          onClick={() => setFilterMode('all')}
          className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
            filterMode === 'all' ? 'bg-slate-700 text-white shadow-md' : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Ver Todas
        </button>
      </div>

      {/* --- GRID DE SERVICIOS --- */}
      {isLoading ? (
        <div className="p-20 text-center text-slate-500 animate-pulse border-2 border-dashed border-slate-800 rounded-2xl">
          Consultando base de datos de servicios...
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filteredServices.map((service) => (
            <div key={service.id} className="group relative flex flex-col justify-between overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/40 p-5 hover:border-indigo-500/50 transition-all hover:shadow-2xl hover:shadow-indigo-500/10 backdrop-blur-md">
              
              {/* Etiqueta de Inactivo (Oculto) si aplica */}
              {!service.isActive && (
                <div className="absolute top-0 right-0 bg-rose-500 text-white text-[10px] font-black uppercase px-3 py-1 rounded-bl-lg z-10">
                  Oculta / Baneada
                </div>
              )}

              <div>
                <div className="flex items-center justify-between mb-4 mt-2">
                  <span className="bg-indigo-500/10 text-indigo-400 text-[10px] font-black px-2 py-1 rounded-md uppercase tracking-tighter border border-indigo-500/20">
                    {getCategoryName(service.category_id || service.categoryId)}
                  </span>
                  <div className="text-emerald-400 font-black text-lg tracking-tighter">
                    ${service.base_price || service.basePrice}
                  </div>
                </div>

                <h4 className={`text-md font-bold transition-colors line-clamp-1 ${!service.isActive ? 'text-slate-500 line-through' : 'text-slate-100 group-hover:text-indigo-300'}`}>
                  {service.title}
                </h4>
                <p className="mt-3 text-xs text-slate-400 leading-relaxed line-clamp-3 h-12">
                  {service.description}
                </p>
              </div>

              {/* ACCIONES DE LA TARJETA */}
              <div className="mt-6 flex items-center justify-between pt-4 border-t border-slate-800/50">
                <div className="flex items-center gap-2">
                  <div className="h-6 w-6 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-[10px] text-slate-400 font-bold uppercase">
                    {(service.client_id || service.clientId || 'U').charAt(0)}
                  </div>
                  <span className="text-[10px] text-slate-500 font-bold uppercase tracking-widest line-clamp-1">
                    {getUserName(service.client_id || service.clientId)}
                  </span>
                </div>
                
                <div className="flex gap-2 relative z-20">
                  <button 
                    onClick={() => navigate(`/services/${service.id}`)}
                    className="p-2 bg-indigo-500/10 text-indigo-400 rounded-lg hover:bg-indigo-500 hover:text-white transition-all shadow-sm"
                    title="Ver detalles completos"
                  >
                    <Eye size={16} />
                  </button>
                </div>
              </div>

            </div>
          ))}
          
          {filteredServices.length === 0 && (
            <div className="col-span-full py-20 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-2xl bg-slate-900/20">
              <p className="font-medium">No se encontraron publicaciones con ese criterio.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};