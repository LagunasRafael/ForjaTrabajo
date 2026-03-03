import os
import sys

# Agregamos la ruta del backend al sys.path para poder importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils.notifications import send_push_notification

def test_push():
    print("🔔 Iniciando prueba de Push Notification...")
    
    # Pegarás el FCM Token de tu celular/emulador aquí cuando Inicies Sesión en Flutter
    TEST_FCM_TOKEN = "e45NydqwQ6qAMa3TSi5tyF:APA91bHyZE9-Tme0tzNP7u6r1eXmuf5w-CU2zaa0AdlcRsLyWtB6Rz_60dAgMYOd5WVy92kHPJFwWWanUkgUyiG65aXUyvFxW7PBaqNck5LpqAfwW9JqmHA"
    
    if TEST_FCM_TOKEN == "INGRESA_AQUI_EL_TOKEN_FCM_CUANDO_LO_TENGAS":
        print("⚠️ Necesitas reemplazar TEST_FCM_TOKEN con el token real de tu dispositivo impreso en la consola de Flutter.")
        return

    result = send_push_notification(
        fcm_token=TEST_FCM_TOKEN,
        title="¡Hola Forja Trabajo! 🔥",
        body="Esta es tu primera notificación Push generada desde el backend local.",
        data={"action": "test", "id": "123"}
    )
    
    if result:
        print(f"✅ Notificación enviada exitosamente. ID: {result}")
    else:
        print("❌ Error al enviar la notificación.")

if __name__ == "__main__":
    test_push()
