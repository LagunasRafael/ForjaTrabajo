import { useState, useEffect, useMemo } from 'react';
import { getServices } from '../services/service.service'
import { getCategories } from '../services/category.service';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';

export const FinancePage = () => {
  const [services, setServices] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);
        // 1. Nombramos correctamente las variables que regresan de la API
        const [categoriesData, servicesData] = await Promise.all([
            getCategories(),
            getServices()
        ]);
        
        // 2. 🟢 ¡CRUCIAL! Guardamos los datos en los estados de React
        setCategories(categoriesData);
        setServices(servicesData);
        
      } catch (error) {
        console.error("Error financiero:", error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchData();
  }, []);

  // 💰 Lógica Financiera
  const stats = useMemo(() => {
    // Filtramos solo los terminados
    const completed = services.filter(s => (s.status || '').toUpperCase() === 'COMPLETED');
    const total = completed.reduce((acc, curr) => acc + (curr.basePrice || 0), 0);
    const average = completed.length > 0 ? total / completed.length : 0;
    
    // 3. 🟢 Cruce relacional: Dinero por categoría real
    const byCategory: Record<string, number> = {};
    
    completed.forEach(s => {
      // Buscamos la categoría en el arreglo de categorías usando el ID que trae el servicio
      const categoryObj = categories.find(c => c.id === s.categoryId);
      const name = categoryObj ? categoryObj.name : 'Otros';
      
      byCategory[name] = (byCategory[name] || 0) + (s.basePrice || 0);
    });

    const categoryData = Object.entries(byCategory)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value);

    return { total, average, completedCount: completed.length, categoryData };
  }, [services, categories]); // Agregamos categories a las dependencias

  const formatMXN = (val: number) => new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  // 📥 Función nativa para exportar a CSV
    const exportToCSV = () => {
    // 1. Filtramos solo los servicios terminados
    const completedServices = services.filter(s => (s.status || '').toUpperCase() === 'COMPLETED');
    
    if (completedServices.length === 0) {
        alert("No hay servicios liquidados para exportar.");
        return;
    }

    // 2. Definimos las cabeceras (Columnas del Excel)
    const headers = ['ID Servicio', 'Título', 'Categoría', 'Precio Base (MXN)', 'Fecha de Creación'];
    
    // 3. Mapeamos los datos y manejamos las comas internas
    const rows = completedServices.map(s => {
        // Buscamos el nombre de la categoría para que no salga solo el ID
        const catName = categories.find(c => c.id === s.categoryId)?.name || 'Otros';
        
        // Envolvemos los textos en comillas dobles por si el título tiene comas
        return [
        `"${s.id}"`,
        `"${s.title || 'Sin título'}"`,
        `"${catName}"`,
        s.basePrice || 0,
        `"${new Date(s.created_at || Date.now()).toLocaleDateString()}"` // Ajusta 'created_at' si Juan Luis le puso otro nombre
        ].join(',');
    });

    // 4. Unimos todo con saltos de línea
    const csvContent = [headers.join(','), ...rows].join('\n');

    // 5. Creamos el archivo virtual (Blob) y forzamos la descarga
    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' }); // \uFEFF ayuda a Excel a leer acentos
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    
    link.href = url;
    link.setAttribute('download', `ForjaTrabajo_Finanzas_${new Date().toLocaleDateString()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    };

  return (
    <div className="space-y-8 animate-in fade-in duration-500 pb-10">
     {/* Encabezado con Botón de Exportación */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Gestión Financiera</h2>
            <p className="text-sm text-slate-400 mt-1">Análisis del flujo económico de Ciudad Hidalgo.</p>
        </div>
        
        <button 
            onClick={exportToCSV}
            disabled={isLoading || stats.completedCount === 0}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-lg text-sm font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="7 10 12 15 17 10"/>
            <line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
            Exportar Reporte
        </button>
        </div>

      {/* Tarjetas de Dinero */}
      <div className="grid gap-6 sm:grid-cols-1 lg:grid-cols-3">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Volumen Total (GMV)</p>
          <h3 className="mt-2 text-3xl font-bold text-emerald-400">
            {isLoading ? '...' : formatMXN(stats.total)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Dinero total movido entre usuarios.</p>
        </div>
        
        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Ticket Promedio</p>
          <h3 className="mt-2 text-3xl font-bold text-blue-400">
            {isLoading ? '...' : formatMXN(stats.average)}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Costo medio por servicio terminado.</p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
          <p className="text-sm font-medium text-slate-400">Servicios Liquidados</p>
          <h3 className="mt-2 text-3xl font-bold text-indigo-400">
            {isLoading ? '...' : stats.completedCount}
          </h3>
          <p className="text-xs text-slate-500 mt-2">Trabajos que completaron el flujo de pago.</p>
        </div>
      </div>

      {/* Gráfica: ¿Qué categoría genera más dinero? */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
        <h3 className="text-lg font-bold text-white mb-6">Rentabilidad por Categoría</h3>
        
        {isLoading ? (
          <div className="h-[350px] w-full flex items-center justify-center text-slate-500 animate-pulse">
            Calculando métricas financieras...
          </div>
        ) : stats.categoryData.length === 0 ? (
          <div className="h-[350px] w-full flex flex-col items-center justify-center text-slate-500">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" className="mb-4 opacity-50"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
            <p>No hay servicios liquidados aún.</p>
          </div>
        ) : (
          <div className="h-[350px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={stats.categoryData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                <XAxis dataKey="name" stroke="#94a3b8" fontSize={12} />
                <YAxis stroke="#94a3b8" fontSize={12} tickFormatter={(val) => `$${val}`} />
                <Tooltip 
                  cursor={{ fill: '#1e293b', opacity: 0.4 }}
                  contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px' }}
                  itemStyle={{ color: '#34d399' }}
                  formatter={(value: any) => [formatMXN(Number(value)), 'Ingresos']}
                />
                <Bar dataKey="value" fill="#10b981" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
    </div>
  );
};