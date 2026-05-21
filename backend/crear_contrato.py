import sqlite3
import uuid
from datetime import datetime

# Configuración
db_name = 'forja.db' # Asegúrate que este sea el nombre correcto

def create_fake_contract():
    try:
        conn = sqlite3.connect(db_name)
        cursor = conn.cursor()
        
        print("🔍 Buscando usuarios...")
        # 1. Buscamos un Cliente y un Trabajador reales
        cursor.execute("SELECT id, full_name FROM users WHERE role='client' LIMIT 1")
        client = cursor.fetchone()
        
        cursor.execute("SELECT id, full_name FROM users WHERE role='worker' LIMIT 1")
        worker = cursor.fetchone()

        # Si no hay usuarios con rol, agarramos cualquiera para probar
        if not client:
            cursor.execute("SELECT id, full_name FROM users LIMIT 1")
            client = cursor.fetchone()
            print("⚠️ No encontré Cliente, usaré el primer usuario que vi.")
        
        if not worker:
            cursor.execute("SELECT id, full_name FROM users ORDER BY id DESC LIMIT 1")
            worker = cursor.fetchone()
            print("⚠️ No encontré Worker, usaré el último usuario que vi.")

        if not client or not worker:
            print("❌ ERROR: La tabla 'users' está vacía. Crea usuarios primero con la App o Thunder Client.")
            return

        client_id = client[0]
        worker_id = worker[0]
        print(f"👤 Cliente: {client[1]} (ID: {client_id[:8]}...)")
        print(f"👷 Worker:  {worker[1]} (ID: {worker_id[:8]}...)")

        # 2. Generamos UUIDs nuevos
        job_id = str(uuid.uuid4())
        contract_id = str(uuid.uuid4())
        request_id = str(uuid.uuid4()) # ID falso de solicitud
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        print("\n🛠️ Creando Trabajo (Job)...")
        # Insertamos en JOBS (Aquí va el dinero: final_price)
        query_job = """
        INSERT INTO jobs (id, request_id, provider_id, client_id, status, final_price, started_at)
        VALUES (?, ?, ?, ?, 'in_progress', 3000.00, ?)
        """
        cursor.execute(query_job, (job_id, request_id, worker_id, client_id, now))

        print("📜 Creando Contrato vinculado...")
        # Insertamos en CONTRACTS
        query_contract = """
        INSERT INTO contracts (id, job_id, client_id, status, created_at)
        VALUES (?, ?, ?, 'active', ?)
        """
        cursor.execute(query_contract, (contract_id, job_id, client_id, now))

        conn.commit()
        print("\n✅ ¡ÉXITO TOTAL!")
        print(f"💰 Se creó un contrato de $3000 MXN para {client[1]}")
        print("🚀 Ahora ve a tu App -> Perfil -> Mis Contratos y dale Pull-to-Refresh.")

    except Exception as e:
        print(f"\n❌ Ocurrió un error: {e}")
        # Si el error es por columnas faltantes, imprimimos ayuda
        if "no column" in str(e):
            print("💡 Pista: Verifica si la tabla 'jobs' tiene 'provider_id' o se llama 'worker_id'.")
    finally:
        conn.close()

if __name__ == "__main__":
    create_fake_contract()