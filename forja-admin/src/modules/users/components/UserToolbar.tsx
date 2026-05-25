interface UserToolbarProps {
  onSearch: (value: string) => void;
  onCreateClick: () => void;
}

export const UserToolbar = ({ onSearch, onCreateClick }: UserToolbarProps) => {
  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
      {/* Buscador Estilizado */}
      <div className="relative w-full sm:w-96 group">
        <div className="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500 pointer-events-none group-focus-within:text-indigo-400 transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
        </div>
        <input 
          type="text" 
          placeholder="Buscar usuarios por nombre o email..." 
          className="block w-full rounded-lg border border-slate-800 bg-slate-900/50 py-2.5 pl-10 pr-4 text-sm text-slate-200 placeholder-slate-500 focus:border-indigo-500 focus:bg-slate-900 focus:ring-1 focus:ring-indigo-500 focus:outline-none transition-all"
          onChange={(e) => onSearch(e.target.value)}
        />
      </div>

      {/* Botón de Acción Principal */}
      <button 
        onClick={onCreateClick}
        className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-500/20 transition-all hover:bg-indigo-500 hover:scale-[1.02] active:scale-95"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
        Nuevo Usuario
      </button>
    </div>
  );
};