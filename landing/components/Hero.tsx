export default function Hero() {
  return (
    <section className="max-w-[1200px] mx-auto px-6 md:px-8 pt-20 md:pt-32 pb-16 md:pb-24">
      <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">
        <div className="flex-1 text-center lg:text-left">
          <div className="inline-flex items-center gap-2 bg-[#6366F1]/10 border border-[#6366F1]/20 rounded-full px-4 py-1.5 mb-6">
            <span className="w-2 h-2 bg-[#6366F1] rounded-full animate-pulse"></span>
            <span className="text-[#6366F1] text-xs font-semibold tracking-wide uppercase">
              Disponible en México
            </span>
          </div>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight tracking-tight">
            Encuentra al profesional ideal o{" "}
            <span className="gradient-text">consigue trabajos</span>
            {" "}cerca de ti
          </h1>

          <p className="text-[#94A3B8] text-lg md:text-xl mt-6 max-w-xl mx-auto lg:mx-0 leading-relaxed">
            Conectamos clientes con trabajadores verificados. Pagos seguros con escrow, chat en tiempo real y calificaciones transparentes.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 mt-8 justify-center lg:justify-start">
            <a
              href="#descargar"
              className="bg-[#6366F1] text-white font-semibold px-8 py-4 rounded-lg hover:bg-[#4F46E5] transition-all shadow-lg hover:shadow-[#6366F1]/25 hover:-translate-y-0.5 text-center"
            >
              Descargar Gratis
            </a>
            <a
              href="#como-funciona"
              className="border border-[#1E293B] text-white font-semibold px-8 py-4 rounded-lg hover:bg-[#0F172A] transition-all text-center"
            >
              Cómo Funciona
            </a>
          </div>

          <div className="flex items-center gap-6 mt-8 justify-center lg:justify-start">
            <div className="flex -space-x-2">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="w-8 h-8 rounded-full bg-[#1E293B] border-2 border-[#020617] flex items-center justify-center text-xs"
                >
                  {i === 1 ? "👷" : i === 2 ? "🔧" : i === 3 ? "🧹" : "⚡"}
                </div>
              ))}
            </div>
            <p className="text-[#94A3B8] text-sm">
              <span className="text-white font-semibold">+500</span> profesionales activos
            </p>
          </div>
        </div>

        <div className="flex-1 flex justify-center">
          <div className="relative w-64 md:w-72">
            <div className="absolute inset-0 bg-[#6366F1]/20 blur-3xl rounded-full"></div>
            <div className="relative bg-[#0F172A] border border-[#1E293B] rounded-3xl p-4 glow-effect">
              <div className="bg-[#020617] rounded-2xl overflow-hidden aspect-[9/16] flex items-center justify-center">
                <div className="text-center p-6">
                  <div className="text-4xl mb-4">⚒️</div>
                  <p className="text-white font-bold text-lg">Forja Trabajo</p>
                  <p className="text-[#94A3B8] text-sm mt-2">Tu app de servicios locales</p>
                  <div className="mt-6 space-y-3">
                    <div className="bg-[#0F172A] rounded-lg p-3 text-left">
                      <p className="text-white text-xs font-semibold">🔧 Plomería urgente</p>
                      <p className="text-[#94A3B8] text-[10px] mt-1">$350 MXN • 2.5 km</p>
                    </div>
                    <div className="bg-[#0F172A] rounded-lg p-3 text-left">
                      <p className="text-white text-xs font-semibold">🧹 Limpieza profunda</p>
                      <p className="text-[#94A3B8] text-[10px] mt-1">$500 MXN • 1.8 km</p>
                    </div>
                    <div className="bg-[#0F172A] rounded-lg p-3 text-left">
                      <p className="text-white text-xs font-semibold">⚡ Electricista</p>
                      <p className="text-[#94A3B8] text-[10px] mt-1">$400 MXN • 3.2 km</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
