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
