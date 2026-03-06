import requests
import time

BASE_URL = "http://127.0.0.1:8000"

def test_registration():
    print("🚀 Iniciando prueba de registro y correo electrónico...")
    
    # Datos del nuevo usuario de prueba
    test_user = {
        "email": f"test.forja.{int(time.time())}@yopmail.com", # Email aleatorio para no chocar
        "password": "Password123!",
        "full_name": "Usuario de Prueba",
        "phone": f"55{random_phone()}"
    }

    try:
        # 1. Registrar usuario
        print(f"📝 Registrando usuario: {test_user['email']}")
        response = requests.post(f"{BASE_URL}/auth/register", json=test_user)
        
        if response.status_code == 201:
            print("✅ Registro exitoso en la Base de Datos.")
            print("⏳ Por favor, revisa la terminal del servidor FastAPI. Debería mostrar un mensaje indicando que el correo se envió (o falló).")
            print("💡 Como usamos BackgroundTasks, el endpoint responde antes de enviar el correo.")
            return test_user['email']
        else:
            print(f"❌ Falló el registro: {response.status_code}")
            print(response.json())
            return None
            
    except requests.exceptions.ConnectionError:
        print("❌ Error de conexión. ¿Está el servidor corriendo en http://127.0.0.1:8000 ?")
        return None

def random_phone():
    import random
    return str(random.randint(10000000, 99999999))

if __name__ == "__main__":
    test_registration()
