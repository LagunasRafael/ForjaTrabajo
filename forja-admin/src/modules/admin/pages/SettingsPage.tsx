import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import api from '../../../api/client';

export const SettingsPage = () => {
  const [isLoading, setIsLoading] = useState(false);

  // 1. Estados para la configuración
  const [config, setConfig] = useState({
    siteName: '',
    supportEmail: '',
    maintenanceMode: false,
    commissionRate: 10,
  });

  useEffect(() => {
    const fetchConfig = async () => {
      try {
        const response = await api.get('/config');
        setConfig({
          siteName: response.data.site_name,
          supportEmail: response.data.support_email,
          maintenanceMode: response.data.maintenance_mode,
          commissionRate: response.data.commission_rate,
        });
        localStorage.setItem('maintenance_mode', JSON.stringify(response.data.maintenance_mode));
        window.dispatchEvent(new Event('maintenance_changed'));
      } catch (error) {
        toast.error('Error al cargar la configuración.');
      }
    };
    fetchConfig();
  }, []);

  const [passwords, setPasswords] = useState({
    current: '',
    new: '',
    confirm: ''
  });

  // 2. Handlers
  const handleSaveGeneral = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await api.put('/config', {
        site_name: config.siteName,
        support_email: config.supportEmail,
        maintenance_mode: config.maintenanceMode,
        commission_rate: config.commissionRate,
      });
      localStorage.setItem('maintenance_mode', JSON.stringify(config.maintenanceMode));
      window.dispatchEvent(new Event('maintenance_changed'));
      toast.success('Configuración general actualizada y guardada en el servidor.');
    } catch (error) {
      toast.error('Error al guardar la configuración.');
    } finally {
      setIsLoading(false);
    }
  };

  // Dentro de SettingsPage.tsx

  const toggleMaintenance = async () => {
    const newValue = !config.maintenanceMode;
    setConfig({ ...config, maintenanceMode: newValue });

    try {
      await api.put('/config', { maintenance_mode: newValue });
      localStorage.setItem('maintenance_mode', JSON.stringify(newValue));
      window.dispatchEvent(new Event('maintenance_changed'));

      if (newValue) {
        toast.warning('Modo mantenimiento activado.');
      } else {
        toast.success('Plataforma activada correctamente.');
      }
    } catch (error) {
      setConfig({ ...config, maintenanceMode: !newValue });
      toast.error('Error al cambiar el modo mantenimiento.');
    }
  };

  // En tu botón de Toggle del return:
  <button
    type="button"
    onClick={toggleMaintenance}
    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${config.maintenanceMode ? 'bg-amber-500' : 'bg-slate-700'}`}
  >
    <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${config.maintenanceMode ? 'translate-x-6' : 'translate-x-1'}`} />
  </button>

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (passwords.new !== passwords.confirm) {
      return toast.error('Las contraseñas no coinciden');
    }
    toast.success('Contraseña actualizada correctamente');
    setPasswords({ current: '', new: '', confirm: '' });
  };

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500 pb-12">
      {/* Encabezado */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight">Configuración</h2>
        <p className="text-sm text-slate-400 mt-1">Gestiona las preferencias del panel y la seguridad de tu cuenta.</p>
      </div>

      <div className="grid gap-8 lg:grid-cols-3">

        {/* COLUMNA IZQUIERDA: GENERAL */}
        <div className="lg:col-span-2 space-y-6">
          <section className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
            <h3 className="text-lg font-semibold text-white mb-6 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-indigo-400"><rect width="20" height="16" x="2" y="4" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" /></svg>
              Información de la Plataforma
            </h3>

            <form onSubmit={handleSaveGeneral} className="space-y-4">
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Nombre del Sitio</label>
                  <input
                    type="text"
                    value={config.siteName}
                    onChange={(e) => setConfig({ ...config, siteName: e.target.value })}
                    className="w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Email de Soporte</label>
                  <input
                    type="email"
                    value={config.supportEmail}
                    onChange={(e) => setConfig({ ...config, supportEmail: e.target.value })}
                    className="w-full rounded-xl border border-slate-700 bg-slate-800/50 px-4 py-2 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>
              </div>

              <div className="flex items-center justify-between p-4 rounded-xl bg-slate-800/30 border border-slate-700/50 mt-4">
                <div>
                  <p className="text-sm font-medium text-white">Modo Mantenimiento</p>
                  <p className="text-xs text-slate-500">Desactiva temporalmente el marketplace para los usuarios.</p>
                </div>
                <button
                  type="button"
                  onClick={toggleMaintenance}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${config.maintenanceMode ? 'bg-indigo-600' : 'bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${config.maintenanceMode ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>

              <div className="flex justify-end mt-6">
                <button
                  type="submit"
                  disabled={isLoading}
                  className="px-6 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-bold transition-all disabled:opacity-50"
                >
                  {isLoading ? 'Guardando...' : 'Guardar Cambios'}
                </button>
              </div>
            </form>
          </section>

          {/* SECCIÓN DE COMISIONES (Finanzas) */}
          <section className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
            <h3 className="text-lg font-semibold text-white mb-6 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-emerald-400"><path d="M12 2v20" /><path d="m17 5-5-3-5 3" /><path d="m17 19-5 3-5-3" /><path d="M2 12h20" /><path d="m5 7-3 5 3 5" /><path d="m19 7 3 5-3 5" /></svg>
              Reglas de Negocio
            </h3>
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Comisión de la Plataforma (%)</label>
                <div className="flex items-center gap-4">
                  <input
                    type="range"
                    min="0" max="30"
                    value={config.commissionRate}
                    onChange={(e) => setConfig({ ...config, commissionRate: parseInt(e.target.value) })}
                    className="flex-1 h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500"
                  />
                  <span className="text-lg font-bold text-white w-12">{config.commissionRate}%</span>
                </div>
                <p className="text-xs text-slate-500 italic">Este valor se usará para el cálculo de proyecciones en el módulo de Finanzas.</p>
              </div>
            </div>
          </section>
        </div>

        {/* COLUMNA DERECHA: SEGURIDAD */}
        <div className="space-y-6">
          <section className="rounded-2xl border border-slate-800 bg-slate-900/50 p-6 backdrop-blur-sm">
            <h3 className="text-lg font-semibold text-white mb-6 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-rose-400"><rect width="18" height="11" x="3" y="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
              Seguridad
            </h3>

            <form onSubmit={handleChangePassword} className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Contraseña Actual</label>
                <input
                  type="password"
                  value={passwords.current}
                  onChange={(e) => setPasswords({ ...passwords, current: e.target.value })}
                  className="w-full rounded-xl border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-rose-500 focus:outline-none transition-colors"
                />
              </div>
              <div className="space-y-2 pt-2 border-t border-slate-800">
                <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Nueva Contraseña</label>
                <input
                  type="password"
                  value={passwords.new}
                  onChange={(e) => setPasswords({ ...passwords, new: e.target.value })}
                  className="w-full rounded-xl border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Confirmar Nueva</label>
                <input
                  type="password"
                  value={passwords.confirm}
                  onChange={(e) => setPasswords({ ...passwords, confirm: e.target.value })}
                  className="w-full rounded-xl border border-slate-700 bg-slate-800 px-4 py-2 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>
              <button
                type="submit"
                className="w-full mt-2 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-sm font-bold border border-slate-700 transition-all"
              >
                Actualizar Contraseña
              </button>
            </form>
          </section>

          {/* INFO DE SESIÓN */}
          <div className="rounded-2xl border border-dashed border-slate-800 p-6 text-center">
            <p className="text-xs text-slate-500">
              ID de Administrador: <code className="text-slate-400">admin-7742-hidalgo</code>
            </p>
            <p className="text-xs text-slate-500 mt-1">Último acceso: Hace 23 minutos</p>
          </div>
        </div>

      </div>
    </div>
  );
};