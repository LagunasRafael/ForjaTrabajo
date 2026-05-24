import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LegalDocumentType {
  termsAndConditions,
  privacyPolicy,
}

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = type == LegalDocumentType.termsAndConditions
        ? 'Términos y Condiciones'
        : 'Aviso de Privacidad';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: type == LegalDocumentType.termsAndConditions
                ? _buildTermsAndConditions(theme, isDark)
                : _buildPrivacyPolicy(theme, isDark),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTermsAndConditions(ThemeData theme, bool isDark) {
    return [
      _buildHeader('Términos y Condiciones de Uso', theme),
      _buildSubtitle('Última actualización: Mayo 2026', theme),
      const SizedBox(height: 20),
      _buildParagraph(
        'Bienvenido a Forja Trabajo. Al descargar, instalar o utilizar nuestra aplicación móvil, aceptas cumplir y estar sujeto a los siguientes Términos y Condiciones. Por favor, léelos detenidamente antes de utilizar nuestros servicios.',
        theme,
      ),
      _buildSection('1. Naturaleza del Servicio', theme),
      _buildParagraph(
        'Forja Trabajo es una plataforma digital de intermediación que conecta a usuarios que requieren servicios independientes ("Clientes") con proveedores de servicios independientes ("Trabajadores"). Forja Trabajo únicamente facilita el contacto y la gestión de la relación a través de herramientas tecnológicas, por lo que NO tiene una relación de subordinación, patrón-empleado, ni de representación con ninguno de los usuarios.',
        theme,
      ),
      _buildSection('2. Registro y Uso de Cuentas', theme),
      _buildParagraph(
        'Para utilizar los servicios, los usuarios deben registrarse y crear una cuenta personal. Te comprometes a proporcionar información verídica, exacta y actualizada durante el registro. Eres el único responsable de la confidencialidad de tu contraseña y de todas las actividades que ocurran bajo tu cuenta.',
        theme,
      ),
      _buildSection('3. Sistema de Pagos Seguro (Escrow)', theme),
      _buildParagraph(
        'Para garantizar la seguridad de las transacciones, Forja Trabajo utiliza un mecanismo de retención de fondos (Escrow) administrado por Stripe Connect:',
        theme,
      ),
      _buildBulletPoint(
        'El Cliente deposita el costo final acordado del servicio al momento de confirmar el emparejamiento (Match).',
        theme,
      ),
      _buildBulletPoint(
        'Los fondos permanecen retenidos de forma segura en la plataforma y NO son liberados al Trabajador de manera inmediata.',
        theme,
      ),
      _buildBulletPoint(
        'Una vez que el Trabajador completa el servicio y el Cliente confirma la finalización exitosa, los fondos son liberados y transferidos a la billetera configurada del Trabajador.',
        theme,
      ),
      _buildSection('4. Política de Disputas y Cancelaciones', theme),
      _buildParagraph(
        'En caso de que surja un conflicto sobre la ejecución del servicio (por ejemplo, trabajo incompleto o insatisfactorio), cualquiera de las partes podrá solicitar la intervención de la administración de Forja Trabajo mediante la apertura de una Disputa en el chat del servicio:',
        theme,
      ),
      _buildBulletPoint(
        'Un administrador de la plataforma revisará la conversación, las evidencias de trabajo subidas por ambas partes y cualquier otro factor relevante.',
        theme,
      ),
      _buildBulletPoint(
        'El administrador dictará una resolución definitiva que puede resultar en un reembolso total o parcial al Cliente, o en la liberación del pago al Trabajador.',
        theme,
      ),
      _buildBulletPoint(
        'Al aceptar estos términos, aceptas acatar las resoluciones emitidas por la administración del sistema como definitivas y vinculantes.',
        theme,
      ),
      _buildSection('5. Obligaciones y Conducta del Usuario', theme),
      _buildParagraph(
        'Te comprometes a utilizar la aplicación de buena fe y a abstenerte de realizar conductas fraudulentas, hostigamiento, difamación, o uso de lenguaje ofensivo en el chat de la plataforma. Forja Trabajo se reserva el derecho de suspender o expulsar permanentemente a cualquier usuario que infrinja estas reglas.',
        theme,
      ),
      _buildSection('6. Limitación de Responsabilidad', theme),
      _buildParagraph(
        'Dado que los servicios son prestados por Trabajadores independientes ajenos a Forja Trabajo, la plataforma no otorga garantías sobre la calidad, puntualidad o idoneidad de los trabajos. El Trabajador asume toda la responsabilidad civil, fiscal y legal derivada del servicio prestado.',
        theme,
      ),
      _buildSection('7. Jurisdicción Aplicable', theme),
      _buildParagraph(
        'Para la interpretación y cumplimiento de estos Términos y Condiciones, las partes se someten expresamente a las leyes aplicables de la República Mexicana, renunciando a cualquier otro fuero que pudiere corresponderles por razón de sus domicilios presentes o futuros.',
        theme,
      ),
      const SizedBox(height: 30),
    ];
  }

  List<Widget> _buildPrivacyPolicy(ThemeData theme, bool isDark) {
    return [
      _buildHeader('Aviso de Privacidad Simplificado', theme),
      _buildSubtitle('Última actualización: Mayo 2026', theme),
      const SizedBox(height: 20),
      _buildParagraph(
        'Forja Trabajo, con domicilio en México, es el responsable del tratamiento de tus datos personales. De conformidad con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP), nos comprometemos a garantizar la confidencialidad, integridad y seguridad de la información recopilada a través de nuestra aplicación móvil.',
        theme,
      ),
      _buildSection('1. Datos Personales que Recopilamos', theme),
      _buildParagraph(
        'Para el correcto funcionamiento de la plataforma, recopilamos los siguientes datos personales:',
        theme,
      ),
      _buildBulletPoint(
        'Información de perfil: Nombre completo, correo electrónico, número telefónico y fotografía de perfil.',
        theme,
      ),
      _buildBulletPoint(
        'Datos de ubicación (Geolocalización): Recopilamos y utilizamos tu ubicación exacta en tiempo real para buscar y sugerir servicios cercanos a tu área geográfica.',
        theme,
      ),
      _buildBulletPoint(
        'Documentos de Verificación: Identificaciones oficiales proporcionadas voluntariamente por el Trabajador para verificar su identidad y otorgar el distintivo de perfil verificado.',
        theme,
      ),
      _buildBulletPoint(
        'Información de Pago: Los datos bancarios y de tarjetas son procesados directamente por la pasarela segura Stripe Connect. Forja Trabajo NO almacena números completos de tarjetas de crédito o contraseñas bancarias.',
        theme,
      ),
      _buildSection('2. Finalidad del Tratamiento de Datos', theme),
      _buildParagraph(
        'Tus datos personales serán utilizados exclusivamente para las siguientes finalidades principales:',
        theme,
      ),
      _buildBulletPoint(
        'Facilitar el emparejamiento de servicios y la comunicación entre Clientes y Trabajadores.',
        theme,
      ),
      _buildBulletPoint(
        'Procesar pagos de forma segura y facilitar transferencias electrónicas a los Trabajadores.',
        theme,
      ),
      _buildBulletPoint(
        'Garantizar la seguridad dentro de la plataforma mediante la verificación de perfiles y la resolución de reportes o disputas de servicio.',
        theme,
      ),
      _buildSection('3. Transferencia de Datos', theme),
      _buildParagraph(
        'Tus datos podrán ser compartidos de forma limitada con:',
        theme,
      ),
      _buildBulletPoint(
        'La contraparte del servicio (Cliente o Trabajador) exclusivamente para coordinar el trabajo (se muestra nombre, teléfono y aproximación geográfica).',
        theme,
      ),
      _buildBulletPoint(
        'Nuestra pasarela de pagos Stripe Connect, para cumplir con los requerimientos regulatorios "Conoce a tu Cliente" (KYC) y procesar transferencias financieras.',
        theme,
      ),
      _buildSection('4. Derechos ARCO', theme),
      _buildParagraph(
        'Tienes derecho en cualquier momento de Acceder, Rectificar, Cancelar u Oponerte (Derechos ARCO) al uso de tus datos personales. Para ejercer estos derechos o solicitar la baja permanente de tu cuenta y eliminación total de tus datos, puedes ponerte en contacto con nuestro equipo legal escribiendo al correo: soporte@forjatrabajo.com.',
        theme,
      ),
      const SizedBox(height: 30),
    ];
  }

  Widget _buildHeader(String text, ThemeData theme) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSubtitle(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildSection(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, ThemeData theme) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: theme.colorScheme.onSurface.withOpacity(0.85),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildBulletPoint(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
