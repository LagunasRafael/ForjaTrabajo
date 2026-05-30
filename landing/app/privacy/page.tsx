import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Política de Privacidad | Forja Trabajo",
  description: "Política de Privacidad de Forja Trabajo",
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen py-20 px-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-8">
          Política de Privacidad
        </h1>

        <div className="prose prose-invert max-w-none">
          <p className="text-[#94A3B8] text-sm mb-6">
            Última actualización: Mayo 2026
          </p>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">1. Información que recopilamos</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              En Forja Trabajo recopilamos la información que nos proporcionas al crear una cuenta, publicar servicios, postularte a trabajos o comunicarte con otros usuarios. Esto incluye:
            </p>
            <ul className="text-[#94A3B8] text-sm list-disc list-inside mt-2 space-y-1">
              <li>Nombre completo y correo electrónico</li>
              <li>Número de teléfono (opcional)</li>
              <li>Foto de perfil</li>
              <li>Documentos de verificación de identidad (INE)</li>
              <li>Ubicación geográfica (solo con tu permiso)</li>
              <li>Información de pago procesada por Stripe</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">2. Cómo usamos tu información</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Utilizamos tu información para:
            </p>
            <ul className="text-[#94A3B8] text-sm list-disc list-inside mt-2 space-y-1">
              <li>Conectar clientes con trabajadores verificados</li>
              <li>Procesar pagos seguros a través de Stripe</li>
              <li>Verificar la identidad de los usuarios</li>
              <li>Enviar notificaciones relevantes sobre tus servicios</li>
              <li>Mejorar la experiencia de la plataforma</li>
              <li>Cumplir con obligaciones legales</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">3. Compartir información</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              No vendemos tu información personal. Solo compartimos datos con:
            </p>
            <ul className="text-[#94A3B8] text-sm list-disc list-inside mt-2 space-y-1">
              <li><strong>Stripe:</strong> Para procesar pagos de forma segura</li>
              <li><strong>AWS S3:</strong> Para almacenar fotos y documentos de forma encriptada</li>
              <li><strong>Autoridades:</strong> Cuando sea requerido por ley</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">4. Eliminación de datos</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Puedes solicitar la eliminación de tu cuenta y todos tus datos personales en cualquier momento desde la aplicación o visitando nuestra{" "}
              <a href="/delete-account" className="text-[#6366F1] hover:underline">
                página de eliminación de cuenta
              </a>
              . Una vez eliminada, la acción es irreversible.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">5. Seguridad</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Implementamos medidas de seguridad técnicas y organizativas para proteger tu información, incluyendo encriptación SSL, autenticación JWT y almacenamiento seguro de documentos.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-xl font-semibold text-white mb-4">6. Contacto</h2>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              Si tienes preguntas sobre esta política de privacidad, contáctanos en:
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
