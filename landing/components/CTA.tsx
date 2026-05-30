export default function CTA() {
  return (
    <section id="descargar" className="relative w-full overflow-hidden py-20 md:py-32">
      <div className="absolute inset-0 z-0 pointer-events-none">
        <div
          className="absolute top-1/4 left-1/4 w-[300px] h-[300px] rounded-full blur-[80px] opacity-20"
          style={{ background: "#6366F1", animation: "float 12s infinite ease-in-out" }}
        ></div>
        <div
          className="absolute top-1/3 right-1/4 w-[400px] h-[400px] rounded-full blur-[100px] opacity-15"
          style={{ background: "#818CF8", animation: "float 15s infinite ease-in-out reverse" }}
        ></div>
        <div
          className="absolute bottom-1/4 left-1/3 w-[250px] h-[250px] rounded-full blur-[70px] opacity-20"
          style={{ background: "#A78BFA", animation: "float 14s infinite ease-in-out" }}
        ></div>
      </div>

      <div className="relative z-10 max-w-[1200px] mx-auto px-6 md:px-8 text-center">
        <h2 className="text-3xl md:text-5xl font-bold text-white leading-tight max-w-3xl mx-auto">
          ¿Listo para encontrar al profesional perfecto o{" "}
          <span className="gradient-text">conseguir tu próximo trabajo</span>?
        </h2>
        <p className="text-[#94A3B8] text-lg md:text-xl mt-6 max-w-xl mx-auto leading-relaxed">
          Únete a miles de usuarios que ya confían en Forja Trabajo para sus servicios locales en México.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 mt-10 justify-center">
          <a
            href="#"
            className="bg-white text-[#020617] font-bold px-8 py-4 rounded-lg hover:bg-gray-100 transition-all shadow-lg hover:-translate-y-0.5 flex items-center justify-center gap-3"
          >
            <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
            </svg>
            <div className="text-left">
              <div className="text-[10px] font-normal">Descargar en</div>
              <div className="text-sm font-bold -mt-1">App Store</div>
            </div>
          </a>
          <a
            href="#"
            className="bg-white text-[#020617] font-bold px-8 py-4 rounded-lg hover:bg-gray-100 transition-all shadow-lg hover:-translate-y-0.5 flex items-center justify-center gap-3"
          >
            <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.807 1.626a1 1 0 010 1.732l-2.807 1.626L15.206 12l2.492-2.492zM5.864 2.658L16.8 8.99l-2.302 2.302-8.634-8.634z"/>
            </svg>
            <div className="text-left">
              <div className="text-[10px] font-normal">Disponible en</div>
              <div className="text-sm font-bold -mt-1">Google Play</div>
            </div>
          </a>
        </div>
      </div>
    </section>
  );
}
