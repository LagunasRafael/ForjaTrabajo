const trustItems = [
  {
    icon: "🛡️",
    title: "Tu dinero está protegido",
    description: "Utilizamos Stripe, la pasarela de pagos más segura del mundo. El dinero se mantiene en escrow hasta que confirmes que el trabajo está bien hecho.",
  },
  {
    icon: "🔐",
    title: "Verificación de identidad",
    description: "Cada trabajador verifica su identidad con INE y selfie. Nuestro equipo de moderación revisa cada perfil antes de ser activado.",
  },
  {
    icon: "📞",
    title: "Soporte 24/7",
    description: "¿Tienes un problema? Nuestro equipo está disponible para ayudarte en cualquier momento. Resolvemos disputas de forma justa y rápida.",
  },
];

export default function Trust() {
  return (
    <section id="confianza" className="max-w-[1200px] mx-auto px-6 md:px-8 py-20 md:py-24">
      <div className="bg-[#0F172A] border border-[#1E293B] rounded-2xl p-8 md:p-12 lg:p-16">
        <div className="text-center mb-12">
          <span className="text-[#6366F1] text-xs font-semibold tracking-[0.2em] uppercase">
            Confianza y Seguridad
          </span>
          <h2 className="text-3xl md:text-4xl font-bold text-white mt-4 leading-tight">
            Tu seguridad es nuestra prioridad
          </h2>
          <p className="text-[#94A3B8] text-lg mt-4 max-w-2xl mx-auto">
            Cada aspecto de Forja Trabajo está diseñado para proteger tanto a clientes como a trabajadores.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {trustItems.map((item, index) => (
            <div key={index} className="text-center">
              <div className="text-4xl mb-4">{item.icon}</div>
              <h3 className="text-white font-semibold text-lg mb-3">
                {item.title}
              </h3>
              <p className="text-[#94A3B8] text-sm leading-relaxed">
                {item.description}
              </p>
            </div>
          ))}
        </div>

        <div className="mt-12 pt-8 border-t border-[#1E293B] flex flex-wrap justify-center gap-8 text-[#94A3B8] text-sm">
          <div className="flex items-center gap-2">
            <span className="text-green-400">✓</span>
            <span>Powered by Stripe</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-green-400">✓</span>
            <span>SSL Encriptado</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-green-400">✓</span>
            <span>Datos protegidos</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-green-400">✓</span>
            <span>Disputas resueltas</span>
          </div>
        </div>
      </div>
    </section>
  );
}
