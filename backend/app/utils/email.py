import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import random

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
# Se leerán del archivo .env
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")

def generate_verification_code() -> str:
    """Genera un código numérico aleatorio de 6 dígitos."""
    return str(random.randint(100000, 999999))

def send_verification_email(to_email: str, code: str):
    """Envía un correo electrónico con el código de verificación."""
    
    if not SMTP_USER or not SMTP_PASSWORD:
        print(f"⚠️ [MOCK EMAIL] Para {to_email}. Código generado: {code}. (Faltan credenciales SMTP en .env)")
        return
        
    try:
        msg = MIMEMultipart()
        msg['From'] = SMTP_USER
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

        # Conectar al servidor SMTP
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()  # Encriptación
        server.login(SMTP_USER, SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        
        print(f"✅ Correo de verificación enviado exitosamente a {to_email}")
        
    except Exception as e:
        print(f"❌ Error al enviar el correo a {to_email}: {str(e)}")
        # No lanzamos excepción para no romper el registro de usuario si el mail falla,
        # pero en producción podrías querer manejarlo distinto.
