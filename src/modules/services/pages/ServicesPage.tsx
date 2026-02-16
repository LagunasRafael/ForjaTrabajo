import { useState, useEffect, useMemo } from 'react';
import { toast } from 'sonner';
import { getServices, createService, type Service } from '../services/service.service';
import { getCategories, type Category } from '../services/category.service';

export const ServicesPage = () => {
  const [services, setServices] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const fetchAllData = async () => {
      try {
        setIsLoading(true);
        const [servicesData, categoriesData] = await Promise.all([
          getServices(),
          getCategories()
        ]);
        setServices(servicesData);
        setCategories(categoriesData);
      } catch (error) {
        toast.error('Error al cargar las publicaciones');
      } finally {
        setIsLoading(false);
      }
    };

    fetchAllData();
  }, []);

  const getCategoryName = (categoryId: string) => {
    const cat = categories.find(c => c.id === categoryId);
    return cat ? cat.name : 'Categoría Desconocida';
  };

  const filteredServices = useMemo(() => {
    return services.filter(service => 
      service.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      service.description?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [services, searchTerm]);

  const handleDelete = (id: string) => {
    toast.success('Publicación ocultada de la plataforma (Simulación)');
  };

  // --- INICIO DEL HACK TEMPORAL ---
  const handleCreateTestService = async () => {
    if (categories.length === 0) {
      toast.error('Necesitas tener al menos una categoría creada primero');
      return;
    }

    try {
      const payloadPrueba = {
        title: "Reparación urgente de tubería (Prueba)",
        description: "Esto es un servicio generado automáticamente desde el panel de React para probar la conexión.",
        base_price: 450.50,
        category_id: categories[0].id // Toma el ID de tu primera categoría
      };

      await createService(payloadPrueba as any); 
      
      toast.success('¡Publicación de prueba creada con éxito!');
      setTimeout(() => window.location.reload(), 1000);
      
    } catch (error) {
      console.error(error);
      toast.error('Ups, algo falló al crear la prueba');
    }
  };
  // --- FIN DEL HACK TEMPORAL ---

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      
      {/* HEADER AJUSTADO A LA LÓGICA DE NEGOCIO */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Publicaciones de Clientes</h2>
          <p className="text-slate-400 text-sm mt-1">Supervisa las ofertas de trabajo o necesidades publicadas por los usuarios.</p>
        </div>
        <div className="flex w-full md:w-auto gap-3">
          
          {/* 👇 AQUÍ ESTÁ EL BOTÓN DE PRUEBA 👇 */}
          <button 
            onClick={handleCreateTestService}
            className="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2.5 rounded-lg text-sm font-medium transition-colors whitespace-nowrap shadow-lg shadow-emerald-900/20"
          >
            + Crear Prueba
          </button>

          <input 
            type="text"
            placeholder="Buscar por título o descripción..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full md:w-80 bg-slate-900 border border-slate-800 rounded-lg px-4 py-2.5 text-sm text-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 transition-all shadow-inner"
          />
        </div>
      </div>

      {/* GRID DE PUBLICACIONES */}
      {isLoading ? (
        <div className="p-12 text-center text-slate-500 animate-pulse border-2 border-dashed border-slate-800 rounded-xl">
          Cargando publicaciones activas...
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filteredServices.map((service) => (
            <div key={service.id} className="group flex flex-col justify-between overflow-hidden rounded-xl border border-slate-800 bg-slate-900/50 p-5 hover:border-slate-700 transition-all hover:shadow-xl hover:shadow-slate-950/50 backdrop-blur-sm">
              
              <div>
                <div className="flex items-start justify-between mb-4">
                  <span className="inline-flex items-center rounded-md bg-indigo-500/10 px-2 py-1 text-xs font-medium text-indigo-400 ring-1 ring-inset ring-indigo-500/20 uppercase tracking-wide">
                    {getCategoryName(service.category_id)}
                  </span>
                  <span className="text-emerald-400 font-bold text-lg">
                    ${service.base_price}
                  </span>
                </div>

                <h4 className="text-lg font-bold text-slate-200 group-hover:text-white transition-colors line-clamp-1">
                  {service.title}
                </h4>
                <p className="mt-2 text-sm text-slate-400 leading-relaxed line-clamp-3">
                  {service.description}
                </p>
              </div>

              {/* FOOTER DE LA TARJETA */}
              <div className="mt-6 flex items-center justify-between pt-4 border-t border-slate-800/50">
                <div className="flex items-center gap-2">
                  <div className="inline-flex h-6 w-6 rounded-full ring-2 ring-slate-900 bg-emerald-600 items-center justify-center text-[10px] text-white font-bold shadow-inner">
                    C
                  </div>
                  <span className="text-xs text-slate-500 font-medium">Cliente</span>
                </div>
                
                <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button 
                    onClick={() => handleDelete(service.id)}
                    className="text-xs font-bold text-rose-400 hover:text-rose-300 transition-colors uppercase tracking-wider bg-rose-500/10 px-2 py-1 rounded"
                  >
                    Ocultar
                  </button>
                </div>
              </div>

            </div>
          ))}
          
          {filteredServices.length === 0 && (
            <div className="col-span-full py-16 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-xl">
              <p>No hay publicaciones de trabajo activas en este momento.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};