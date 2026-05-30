export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-[#0F172A] border-t border-[#1E293B] w-full mt-auto">
      <div className="flex flex-col md:flex-row justify-between items-center w-full px-6 md:px-8 py-8 max-w-[1200px] mx-auto gap-4">
        <a href="/" className="text-base font-bold text-white tracking-tight flex items-center gap-2">
          <span className="text-[#6366F1]">⚒️</span>
          Forja Trabajo
        </a>

        <div className="flex gap-6 flex-wrap justify-center">
          <a href="/privacy" className="text-xs text-[#94A3B8] hover:text-white transition-colors">
            Política de Privacidad
          </a>
          <a href="/terms" className="text-xs text-[#94A3B8] hover:text-white transition-colors">
            Términos y Condiciones
          </a>
          <a href="mailto:soporte@forjatrabajo.com" className="text-xs text-[#94A3B8] hover:text-white transition-colors">
            Contacto
          </a>
        </div>

        <div className="text-xs text-[#94A3B8] font-light">
          © {currentYear} Forja Trabajo. Todos los derechos reservados.
        </div>
      </div>
    </footer>
  );
}
