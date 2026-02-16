import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { getServices, createService, type Service } from '../services/service.service';
import { getCategories, type Category } from '../services/category.service';

export const ServicesPage = () => {
  const [services, setServices] = useState<Service[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreating, setIsCreating] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    category_id: ''
  });

  // 1. CARGA SIMULTÁNEA (Promise.all es más rápido)
  useEffect(() => {
    const loadData = async () => {
      try {
        const [servicesData, categoriesData] = await Promise.all([
          getServices(),
          getCategories()
        ]);
        setServices(servicesData);
        setCategories(categoriesData);
      } catch (error) {
        toast.error('Error al cargar datos');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  // 2. CREAR SERVICIO
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.category_id) {
      toast.warning('Debes seleccionar una categoría');
      return;
    }

    try {
      setIsCreating(true);
      const newService = await createService({
        ...formData,
        price: Number(formData.price) // Convertir string a number
      });
      
      setServices([...services, newService]);
      toast.success('Servicio publicado correctamente');
      
      // Limpiar form
      setFormData({ name: '', description: '', price: '', category_id: '' });
    } catch (error) {
      toast.error('Error al publicar el servicio');
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-white">Servicios</h2>
      </div>

      {/* --- FORMULARIO DE CREACIÓN --- */}
      <div className="p-6 rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm">
        <h3 className="text-sm font-medium text-slate-300 uppercase tracking-wider mb-4">Publicar Nuevo Servicio</h3>
        <form onSubmit={handleSubmit} className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 items-end">
          
          {/* Nombre */}
          <div className="space-y-2">
            <label className="text-xs text-slate-500">Título del Servicio</label>
            <input 
              required
              type="text" 
              placeholder="Ej: Instalación de Aire Acondicionado"
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none"
              value={formData.name}
              onChange={e => setFormData({...formData, name: e.target.value})}
            />
          </div>

          {/* Categoría (DROPDOWN) */}
          <div className="space-y-2">
            <label className="text-xs text-slate-500">Categoría</label>
            <select 
              required
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none appearance-none"
              value={formData.category_id}
              onChange={e => setFormData({...formData, category_id: e.target.value})}
            >
              <option value="">Selecciona una opción...</option>
              {categories.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
          </div>

          {/* Precio */}
          <div className="space-y-2">
            <label className="text-xs text-slate-500">Precio Base ($)</label>
            <input 
              required
              type="number" 
              placeholder="0.00"
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none"
              value={formData.price}
              onChange={e => setFormData({...formData, price: e.target.value})}
            />
          </div>

          {/* Botón */}
          <button 
            type="submit" 
            disabled={isCreating}
            className="h-10 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-lg transition-colors disabled:opacity-50"
          >
            {isCreating ? 'Publicando...' : 'Publicar Servicio'}
          </button>

          {/* Descripción (Fila completa) */}
          <div className="md:col-span-2 lg:col-span-4 space-y-2">
            <label className="text-xs text-slate-500">Descripción Detallada</label>
            <textarea 
              required
              rows={2}
              placeholder="Describe qué incluye tu servicio..."
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none resize-none"
              value={formData.description}
              onChange={e => setFormData({...formData, description: e.target.value})}
            />
          </div>
        </form>
      </div>

      {/* --- GRID DE SERVICIOS --- */}
      {isLoading ? (
        <div className="text-center py-10 text-slate-500 animate-pulse">Cargando servicios...</div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {services.map((service) => (
            <div key={service.id} className="relative group bg-slate-900 border border-slate-800 rounded-xl overflow-hidden hover:border-slate-700 transition-all">
              <div className="p-5">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs font-semibold text-indigo-400 bg-indigo-500/10 px-2 py-1 rounded">
                    {/* Buscamos el nombre de la categoría en el array que ya tenemos */}
                    {categories.find(c => c.id === service.category_id)?.name || 'General'}
                  </span>
                  <span className="text-slate-200 font-mono font-bold">${service.price}</span>
                </div>
                <h4 className="text-lg font-bold text-white mb-2">{service.name}</h4>
                <p className="text-sm text-slate-400 line-clamp-2">{service.description}</p>
              </div>
            </div>
          ))}
          
          {services.length === 0 && (
            <div className="col-span-full py-12 text-center border border-dashed border-slate-800 rounded-xl text-slate-500">
              No tienes servicios publicados. ¡Crea el primero arriba!
            </div>
          )}
        </div>
      )}
    </div>
  );
};