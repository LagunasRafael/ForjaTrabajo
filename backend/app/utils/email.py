import os
import random
import logging
import resend

# Configurar el logger para que imprima directamente en consola (útil para Render)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
if not logger.handlers:
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)




def generate_verification_code() -> str:
    """Genera un código numérico aleatorio de 6 dígitos."""
    return str(random.randint(100000, 999999))

def send_verification_email(to_email: str, code: str):
    """Envía un correo electrónico con el código de verificación."""
    
    resend_api_key = os.getenv("RESEND_API_KEY", "").replace('"', '').replace("'", '').strip()
    
    if not resend_api_key:
        logger.warning(f"⚠️ [MOCK EMAIL] Para {to_email}. Código generado: {code}. (Falta RESEND_API_KEY en .env)")
        return
        
    try:
        resend.api_key = resend_api_key

        # Cuerpo del correo en HTML
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
                <h2 style="color: #2e6c80;">¡Bienvenido a Forja Trabajo!</h2>
                <p>Para completar tu registro, ingresa el siguiente código de verificación en la aplicación:</p>
                <div style="font-size: 32px; font-weight: bold; background-color: #f4f4f4; padding: 15px; margin: 20px auto; width: fit-content; border-radius: 8px; letter-spacing: 5px;">
                    {code}
                </div>
                <p style="color: #777;">Si no solicitaste esta cuenta, ignora este correo.</p>
            </body>
        </html>
        """
        
        # En Resend.com (modo gratuito/testing sin dominio verificado):
        # 1. El remitente ("from") siempre DEBE ser "onboarding@resend.dev"
        # 2. El destinatario ("to") temporalmente DEBE ser el mismo correo con el que abriste tu cuenta en Resend.
        params = {
            "from": "Forja Trabajo <hola@forjatrabajo.com.mx>",
            "to": [to_email],
            "subject": "Verifica tu cuenta - Forja Trabajo",
            "html": html_body,
        }
        
        email_response = resend.Emails.send(params)
        logger.info(f"✅ Correo de verificación enviado vía Resend a {to_email}. ID: {email_response}")
        
    except Exception as e:
        logger.error(f"❌ Error al enviar el correo a {to_email} con Resend", exc_info=True)
        # No lanzamos excepción para no bloquear la app de Flutter


def send_password_reset_email(to_email: str, code: str):
    """Envía un correo electrónico con el código para restablecer la contraseña."""
    
    resend_api_key = os.getenv("RESEND_API_KEY", "").replace('"', '').replace("'", '').strip()
    
    if not resend_api_key:
        logger.warning(f"⚠️ [MOCK EMAIL] Reset para {to_email}. Código: {code}. (Falta RESEND_API_KEY)")
        return
        
    try:
        resend.api_key = resend_api_key

        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
                <h2 style="color: #2e6c80;">Recuperar Contraseña</h2>
                <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en <b>Forja Trabajo</b>.</p>
                <p>Ingresa el siguiente código en la aplicación:</p>
                <div style="font-size: 32px; font-weight: bold; background-color: #f4f4f4; padding: 15px; margin: 20px auto; width: fit-content; border-radius: 8px; letter-spacing: 5px;">
                    {code}
                </div>
                <p style="color: #777;">Si no solicitaste este cambio, ignora este correo. Tu contraseña seguirá igual.</p>
            </body>
        </html>
        """
        
        params = {
            "from": "Forja Trabajo <hola@forjatrabajo.com.mx>",
            "to": [to_email],
            "subject": "Recuperar contraseña - Forja Trabajo",
            "html": html_body,
        }
        
        email_response = resend.Emails.send(params)
        logger.info(f"✅ Correo de reset enviado vía Resend a {to_email}. ID: {email_response}")
        
    except Exception as e:
        logger.error(f"❌ Error al enviar correo de reset a {to_email}", exc_info=True)


def send_dispute_opened_email(to_email: str, is_client: bool):
    """Envía un correo cuando se abre una disputa en un trabajo."""
    resend_api_key = os.getenv("RESEND_API_KEY", "").replace('"', '').replace("'", '').strip()
    
    if not resend_api_key:
        logger.warning(f"⚠️ [MOCK EMAIL] Disputa Abierta a {to_email}. (Falta RESEND_API_KEY)")
        return
        
    try:
        resend.api_key = resend_api_key
        role_text = "Cliente" if is_client else "Trabajador"

        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; padding: 20px;">
                <h2 style="color: #d9534f;">Aviso de Disputa Abierta</h2>
                <p>Hola,</p>
                <p>Te informamos que se ha abierto una disputa en uno de tus trabajos activos.</p>
                <p>Tu rol en este trabajo: <b>{role_text}</b></p>
                <p><b>No te preocupes:</b> El dinero relacionado con este trabajo se mantendrá <b>congelado y seguro</b> hasta que uno de nuestros administradores revise el caso.</p>
                <p>Un administrador podría contactarte a través del chat de la aplicación para solicitarte más evidencias (como fotos o mensajes).</p>
                <p style="color: #777;">Gracias por tu paciencia.</p>
            </body>
        </html>
        """
        
        params = {
            "from": "Forja Trabajo <hola@forjatrabajo.com.mx>",
            "to": [to_email],
            "subject": "Aviso Importante: Disputa Abierta - Forja Trabajo",
            "html": html_body,
        }
        
        resend.Emails.send(params)
        logger.info(f"✅ Correo de disputa abierta enviado a {to_email}.")
    except Exception as e:
        logger.error(f"❌ Error al enviar correo de disputa abierta a {to_email}", exc_info=True)


def send_dispute_resolved_email(to_email: str, has_won: bool, role: str):
    """Envía un correo con la resolución final de la disputa."""
    resend_api_key = os.getenv("RESEND_API_KEY", "").replace('"', '').replace("'", '').strip()
    
    if not resend_api_key:
        logger.warning(f"⚠️ [MOCK EMAIL] Resolución Disputa a {to_email}. (Falta RESEND_API_KEY)")
        return
        
    try:
        resend.api_key = resend_api_key

        if has_won:
            title_color = "#5cb85c"
            if role == "client":
                result_text = "La disputa se ha resuelto a tu favor. Se ha autorizado la devolución/liberación de tu dinero. En breve procesaremos el reembolso o la cancelación."
            else:
                result_text = "La disputa se ha resuelto a tu favor. Hemos marcado el trabajo como completado y tu pago será liberado correspondientemente."
        else:
            title_color = "#d9534f"
            if role == "client":
                result_text = "La disputa se ha resuelto a favor del trabajador. El dinero retenido será liberado para cubrir sus honorarios por el servicio brindado."
            else:
                result_text = "La disputa se ha resuelto a favor del cliente. El dinero retenido será reembolsado al cliente de acuerdo con nuestras políticas."

        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; padding: 20px;">
                <h2 style="color: {title_color};">Resolución de Disputa</h2>
                <p>Hola,</p>
                <p>Un administrador ha revisado cuidadosamente tu caso y las evidencias aportadas.</p>
                <div style="background-color: #f9f9f9; padding: 15px; border-left: 5px solid {title_color}; margin: 20px 0;">
                    {result_text}
                </div>
                <p>Si tienes dudas sobre esta resolución, por favor ponte en contacto con nuestro equipo de soporte.</p>
                <p style="color: #777;">Atentamente,<br>El equipo de Forja Trabajo</p>
            </body>
        </html>
        """
        
        params = {
            "from": "Forja Trabajo <hola@forjatrabajo.com.mx>",
            "to": [to_email],
            "subject": "Resolución de Disputa - Forja Trabajo",
            "html": html_body,
        }
        
        resend.Emails.send(params)
        logger.info(f"✅ Correo de resolución enviado a {to_email}.")
    except Exception as e:
        logger.error(f"❌ Error al enviar correo de resolución a {to_email}", exc_info=True)
