import uuid
from fastapi import requests

# URL donde vive tu servidor (la cocina)
BASE_URL = "http://127.0.0.1:8000"

def create_prerequisites():
    """Crea una categoría y un servicio (usando UUIDs de Luis)."""
    print("🏗️  1. Creando Categoría y Servicio...")

    # 1. Crear Categoría
    cat_data = {
        "name": f"Categoría {uuid.uuid4().hex[:4]}",
        "description": "Categoría de prueba"
    }
   
    try:
        response_cat = requests.post(f"{BASE_URL}/services/categories", json=cat_data)
        if response_cat.status_code == 404:
             response_cat = requests.post(f"{BASE_URL}/categories/", json=cat_data)
    except:
        print("❌ No pude conectar con el servidor. ¿Está prendido uvicorn?")
        return None
    
    if response_cat.status_code not in [200, 201]:
        print("❌ Error creando categoría:", response_cat.text)
        return None
    
    category_id = response_cat.json()["id"]
    print(f"   ✅ Categoría creada (ID): {category_id}")

    # 2. Crear Servicio
    service_data = {
        "title": "Reparación Final",
        "description": "Servicio de integración",
        "base_price": 200.00,
        "category_id": category_id
    }
    
    response_serv = requests.post(f"{BASE_URL}/services/services", json=service_data)
    if response_serv.status_code == 404:
         response_serv = requests.post(f"{BASE_URL}/services/", json=service_data)

    if response_serv.status_code not in [200, 201]:
        print("❌ Error creando servicio:", response_serv.text)
        return None

    service_id = response_serv.json()["id"]
    print(f"   ✅ Servicio creado (ID): {service_id}")
    return service_id

def test_create_payment(service_id):
    """Prueba el pago."""
    print("\n💳 2. Probando Módulo de Pagos...")

    payment_data = {
        "amount": 200.00,
        "service_id": service_id,    
        "payer_id": 1,               
        "payment_method": "card"
    }

    response = requests.post(f"{BASE_URL}/payments/", json=payment_data)

    if response.status_code in [200, 201]:
        data = response.json()
        print("   ✅ ¡ÉXITO TOTAL! Pago registrado.")
        print(f"   🆔 ID Pago: {data.get('id')}")
        print(f"   💰 Estado: {data.get('status')}")
    else:
        print("   ❌ FALLÓ el pago.")
        print("   Status:", response.status_code)
        print("   Error:", response.text)

if __name__ == "__main__":
    real_service_id = create_prerequisites()
    
    if real_service_id:
        test_create_payment(real_service_id)