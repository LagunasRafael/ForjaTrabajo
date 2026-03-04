import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import random
import logging

# Configurar el logger para que imprima directamente en consola (útil para Render)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
if not logger.handlers:
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465 # Puerto SSL para brincar los firewalls de Render


def generate_verification_code() -> str:
    """Genera un código numérico aleatorio de 6 dígitos."""
    return str(random.randint(100000, 999999))

def send_verification_email(to_email: str, code: str):
    """Envía un correo electrónico con el código de verificación."""
    
    smtp_user = os.getenv("SMTP_USER", "").replace('"', '').replace("'", '').strip()
    smtp_password = os.getenv("SMTP_PASSWORD", "").replace('"', '').replace("'", '').strip()
    
    if not smtp_user or not smtp_password:
        logger.warning(f"⚠️ [MOCK EMAIL] Para {to_email}. Código modificado: {code}. (Faltan credenciales SMTP, smtp_user='{smtp_user}')")
        return
        
    try:
        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = to_email
        msg['Subject'] = "Verifica tu cuenta - Forja Trabajo"

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
        
        msg.attach(MIMEText(html_body, 'html'))

        # Conectar al servidor SMTP mediante SSL Directo (suele saltarse los firewalls)
        server = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT, timeout=10)
        server.set_debuglevel(1) # Forzar prints del servidor SMTP
        server.login(smtp_user, smtp_password)
        server.send_message(msg)
        server.quit()
        
        logger.info(f"✅ Correo de verificación enviado exitosamente a {to_email}")
        
    except Exception as e:
        logger.error(f"❌ Error al enviar el correo a {to_email}", exc_info=True)
        # No lanzamos excepción para no romper el registro de usuario si el mail falla,
        # pero en producción podrías querer manejarlo distinto.
