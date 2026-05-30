const features = [
  {
    icon: "🔒",
    title: "Pagos seguros con Escrow",
    description: "El dinero del cliente se mantiene protegido hasta que el trabajo esté completado. Sin sorpresas, sin estafas.",
  },
  {
    icon: "💬",
    title: "Chat en tiempo real",
    description: "Comunícate directamente con el trabajador o cliente. Envía fotos, ubicación y detalles del trabajo.",
  },
  {
    icon: "✅",
    title: "Perfiles verificados",
    description: "Todos los trabajadores pasan por un proceso de verificación de identidad con INE y selfie.",
  },
  {
    icon: "📍",
    title: "Geolocalización",
    description: "Encuentra profesionales cerca de ti o publica servicios en tu zona para recibir propuestas rápidas.",
  },
  {
    icon: "⭐",
    title: "Calificaciones transparentes",
    description: "Sistema de reseñas bidireccional. Clientes y trabajadores se evalúan mutuamente para mantener la calidad.",
  },
  {
    icon: "⚡",
    title: "Respuesta inmediata",
    description: "Recibe propuestas en minutos. Nuestro sistema conecta tu necesidad con los profesionales disponibles.",
  },
];

export default function Features() {
  return (
    <section id="funcionalidades" className="max-w-[1200px] mx-auto px-6 md:px-8 py-20 md:py-24">
      <div className="text-center mb-16">
        <span className="text-[#6366F1] text-xs font-semibold tracking-[0.2em] uppercase">
          Funcionalidades
        </span>
        <h2 className="text-3xl md:text-4xl font-bold text-white mt-4 leading-tight">
          Todo lo que necesitas en una sola app
        </h2>
        <p className="text-[#94A3B8] text-lg mt-4 max-w-2xl mx-auto">
          Diseñada para hacer que contratar servicios locales sea simple, seguro y transparente.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {features.map((feature, index) => (
          <div
            key={index}
            className="bg-[#0F172A] border border-[#1E293B] rounded-xl p-6 hover:border-[#6366F1]/50 transition-all group hover:-translate-y-1"
          >
            <div className="w-12 h-12 bg-[#6366F1]/10 rounded-lg flex items-center justify-center text-2xl mb-4 group-hover:bg-[#6366F1]/20 transition-colors">
              {feature.icon}
            </div>
            <h3 className="text-white font-semibold text-lg mb-2 group-hover:text-[#818CF8] transition-colors">
              {feature.title}
            </h3>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              {feature.description}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
