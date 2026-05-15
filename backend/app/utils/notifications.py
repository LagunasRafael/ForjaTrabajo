import firebase_admin
from firebase_admin import credentials, messaging
import os
import logging

logger = logging.getLogger(__name__)

# OJO: Necesitarás colocar el archivo google-services.json o las credenciales del service account de Firebase
# en la carpeta backend/ o en la ruta que especifiques aquí. El admin panel asume que está en app/core/firebase-adminsdk.json

# Inicializamos Firebase la primera vez que se importa este módulo
try:
    if not firebase_admin._apps:
        # Intenta cargar la credencial. Deberás asegurarte que este archivo existe antes de pasar a prod.
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-adminsdk.json")
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("🔥 Firebase Admin SDK inicializado exitosamente.")
        else:
            logger.warning(f"⚠️ Archivo de credenciales de Firebase no encontrado en: {cred_path}. Las notificaciones no funcionarán.")
except Exception as e:
    logger.error(f"❌ Error al inicializar Firebase Admin: {e}")

def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None):
    """
    Envía una notificación Push a un dispositivo específico usando su FCM Token.
    Returns: El ID del mensaje si fue exitoso, o None si falló.
    """
    if not firebase_admin._apps:
        logger.warning("No se puede enviar la notificación porque Firebase no está inicializado.")
        return None

    if not fcm_token:
        logger.warning("FCM Token nulo, ignorando envío de notificación.")
        return None

    if data is None:
        data = {}

    try:
        # 📱 Configuración específica para que Android muestre el "Pop" (Heads-up)
        android_config = messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='forja_notif_channel',
                default_sound=True
            )
        )

        # Preparamos el mensaje
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data,
            token=fcm_token,
            android=android_config
        )

        # Lo enviamos
        response = messaging.send(message)
        logger.info(f"✅ Notificación enviada con éxito: {response}")
        return response

    except Exception as e:
        logger.error(f"❌ Error al enviar notificación Push: {e}")
        return None
