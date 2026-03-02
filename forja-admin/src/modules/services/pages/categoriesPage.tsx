import { useState, useMemo } from 'react';
import { toast } from 'sonner';
import { useCategories } from '../hooks/useCategories'; // <--- Usamos el hook inteligente
import { CategoryFormSlideOver } from '../components/CategoryFormSlideOver';
import type { Category } from '../services/category.service';

export const CategoriesPage = () => {
  const { categories, isLoading, addCategory, editCategory, removeCategory } = useCategories();
  
  const [isCreating, setIsCreating] = useState(false);
  const [newName, setNewName] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const [isSlideOverOpen, setIsSlideOverOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  const filteredCategories = useMemo(() => {
    return categories.filter(cat => 
      cat.name.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [categories, searchTerm]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;

    try {
      setIsCreating(true);
      await addCategory(newName, newDesc);
      toast.success('Categoría creada exitosamente');
      setNewName('');
      setNewDesc('');
    } catch (error) {
      toast.error('No se pudo crear la categoría');
    } finally {
      setIsCreating(false);
    }
  };

  const handleDelete = async (id: string) => {
    toast.promise(removeCategory(id), {
      loading: 'Eliminando oficio...',
      success: 'Categoría eliminada',
      error: 'No se pudo eliminar la categoría',
    });
  };

  const handleOpenEdit = (cat: Category) => {
    setSelectedCategory(cat);
    setIsSlideOverOpen(true);
  };

  const handleSave = async (data: { name: string; description: string }) => {
    try {
      if (selectedCategory) {
        await editCategory(selectedCategory.id, data.name, data.description);
        toast.success('Categoría actualizada');
      } else {
        await addCategory(data.name, data.description);
        toast.success('Categoría creada');
      }
      setIsSlideOverOpen(false);
    } catch (error) {
      toast.error('Error al guardar');
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Categorías de Servicios</h2>
          <p className="text-slate-400 text-sm mt-1">Configura los tipos de servicios disponibles en la plataforma.</p>
        </div>
        <input 
          type="text"
          placeholder="Buscar oficio..."
          onChange={(e) => setSearchTerm(e.target.value)}
          className="hidden md:block bg-slate-900 border border-slate-800 rounded-lg px-4 py-2 text-sm text-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
        />
      </div>

      {/* --- FORMULARIO RÁPIDO --- */}
      <div className="rounded-xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm shadow-xl shadow-indigo-500/5">
        <h3 className="mb-4 text-xs font-semibold text-slate-500 uppercase tracking-widest">Nueva Categoría</h3>
        <form onSubmit={handleCreate} className="flex flex-col gap-4 md:flex-row md:items-end">
          <div className="flex-1 space-y-2">
            <label className="text-xs font-medium text-slate-400">Nombre del Oficio</label>
            <input 
              type="text" 
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="Ej: Carpintería"
              className="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-slate-200 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 transition-all"
            />
          </div>
          <div className="flex-[2] space-y-2">
            <label className="text-xs font-medium text-slate-400">Descripción Corta</label>
            <input 
              type="text" 
              value={newDesc}
              onChange={(e) => setNewDesc(e.target.value)}
              placeholder="Ej: Reparación y construcción de muebles de madera"
              className="w-full rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-slate-200 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 transition-all"
            />
          </div>
          <button 
            type="submit" 
            disabled={isCreating || !newName}
            className="flex items-center justify-center rounded-lg bg-indigo-600 px-6 py-2.5 font-semibold text-white transition-all hover:bg-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-indigo-600/20"
          >
            {isCreating ? 'Guardando...' : 'Agregar'}
          </button>
        </form>
      </div>

      {/* --- TABLA DE LISTADO (Grid Layout) --- */}
      {isLoading ? (
          <div className="p-12 text-center text-slate-500 animate-pulse">Cargando catálogo...</div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredCategories.map((cat) => (
            <div key={cat.id} className="group relative overflow-hidden rounded-xl border border-slate-800 bg-slate-900 p-5 hover:border-slate-700 transition-all hover:shadow-lg hover:shadow-slate-950/50">
              <div className="flex items-start justify-between">
                <div className="flex-1 pr-4">
                  <h4 className="text-lg font-semibold text-slate-200 group-hover:text-indigo-400 transition-colors">
                    {cat.name}
                  </h4>
                  <p className="mt-2 text-sm text-slate-400 leading-relaxed line-clamp-2">
                    {cat.description || "Sin descripción"}
                  </p>
                </div>
                <div className="h-10 w-10 shrink-0 rounded-lg bg-slate-800 border border-slate-700 flex items-center justify-center text-indigo-400 font-bold shadow-inner">
                  {cat.name.charAt(0)}
                </div>
              </div>

              <div className="mt-4 flex items-center gap-3 pt-4 border-t border-slate-800/50 opacity-0 group-hover:opacity-100 transition-opacity">
                {/* 1. AGREGAMOS EL ONCLICK AQUÍ 👇 */}
                <button 
                  onClick={() => handleOpenEdit(cat)}
                  className="text-xs font-semibold text-slate-400 hover:text-indigo-400 transition-colors uppercase tracking-wider"
                >
                  Editar
                </button>
                <button 
                  onClick={() => handleDelete(cat.id)}
                  className="text-xs font-semibold text-slate-400 hover:text-rose-400 transition-colors uppercase tracking-wider"
                >
                  Eliminar
                </button>
              </div>
            </div>
          ))}
          
          {filteredCategories.length === 0 && (
            <div className="col-span-full py-16 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-xl">
              <p>No se encontraron categorías que coincidan.</p>
            </div>
          )}
        </div>
      )}

      {/* 2. RENDERIZAMOS EL COMPONENTE AL FINAL 👇 */}
      <CategoryFormSlideOver 
        isOpen={isSlideOverOpen}
        onClose={() => setIsSlideOverOpen(false)}
        onSubmit={handleSave}
        initialData={selectedCategory}
      />
    </div>
  );
};