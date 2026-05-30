import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Términos y Condiciones | Forja Trabajo",
  description: "Términos y Condiciones de Forja Trabajo",
};

export default function TermsPage() {
  return (
    <div className="min-h-screen py-20 px-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-8">
          Términos y Condiciones
        </h1>

        <div className="prose prose-invert max-w-none">
          <p className="text-[#94A3B8] text-sm mb-6">
            Última actualización: Mayo 2026
          </p>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">1. Aceptación de los términos</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Al crear una cuenta y utilizar Forja Trabajo, aceptas estos Términos y Condiciones en su totalidad. Si no estás de acuerdo, no utilices la plataforma.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">2. Descripción del servicio</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Forja Trabajo es una plataforma digital que conecta a clientes que necesitan servicios locales con trabajadores independientes verificados. Forja Trabajo no emplea a los trabajadores ni es responsable directo de la calidad del trabajo realizado.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">3. Pagos y comisiones</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Los pagos se procesan de forma segura a través de Stripe. Forja Trabajo retiene una comisión del 10% sobre el precio del servicio como tarifa de plataforma. El dinero del cliente se mantiene en escrow hasta que se confirme la finalización del trabajo.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">4. Responsabilidades del usuario</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Como usuario de Forja Trabajo, te comprometes a:
            </p>
            <ul className="text-[#94A3B8] text-sm list-disc list-inside mt-2 space-y-1">
              <li>Proporcionar información veraz y actualizada</li>
              <li>No publicar contenido ofensivo, fraudulento o ilegal</li>
              <li>Respetar los acuerdos establecidos con otros usuarios</li>
              <li>No utilizar la plataforma para actividades ilícitas</li>
              <li>Mantener la seguridad de tu cuenta y contraseña</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">5. Verificación de identidad</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Los trabajadores deben verificar su identidad mediante INE y selfie antes de poder recibir trabajos. Forja Trabajo se reserva el derecho de rechazar o revocar la verificación de cualquier usuario.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">6. Cancelaciones y disputas</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Los clientes pueden cancelar servicios antes de que comience el trabajo. Una vez iniciado, las cancelaciones están sujetas a revisión. En caso de disputa, Forja Trabajo actuará como mediador y tomará una decisión basada en la evidencia proporcionada por ambas partes.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">7. Eliminación de cuenta</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Puedes eliminar tu cuenta en cualquier momento. La eliminación es permanente e irreversible. Todos tus datos, servicios y historial serán borrados de nuestros sistemas.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">8. Limitación de responsabilidad</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Forja Trabajo no garantiza la disponibilidad ininterrumpida del servicio ni se hace responsable de daños indirectos. La plataforma se proporciona "tal cual" sin garantías adicionales.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">9. Contacto</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Si tienes preguntas sobre estos términos, contáctanos en:
            </p>
            <p className="text-[#94A3B8] text-sm mt-2">
              📧 <a href="mailto:soporte@forjatrabajo.com" className="text-[#6366F1] hover:underline">soporte@forjatrabajo.com</a>
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
