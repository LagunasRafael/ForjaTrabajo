import os
import psycopg2
from dotenv import load_dotenv

def migrate_all():
    print("--- Iniciando migracion completa de PostgreSQL ---")
    # Buscamos el .env en la carpeta actual
    load_dotenv()
    
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("Error: No se encontro DATABASE_URL en el archivo .env")
        return

    try:
        # Conectar a la base de datos PostgreSQL
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cursor = conn.cursor()

        # --- TABLA USERS ---
        cols_users = [
            ("fcm_token", "VARCHAR(255)"),
            ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
            ("is_email_verified", "BOOLEAN DEFAULT FALSE"),
            ("verification_code", "VARCHAR(6)"),
            ("is_banned", "BOOLEAN DEFAULT FALSE"),
        ]
        
        # --- TABLA CONVERSATIONS ---
        cols_convos = [
            ("is_archived_by_client", "BOOLEAN DEFAULT FALSE"),
            ("is_archived_by_worker", "BOOLEAN DEFAULT FALSE"),
            ("is_deleted_by_client", "BOOLEAN DEFAULT FALSE"),
            ("is_deleted_by_worker", "BOOLEAN DEFAULT FALSE"),
            ("last_read_at_client", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
            ("last_read_at_worker", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
        ]

        def add_cols(table, cols):
            for col, type_ in cols:
                try:
                    cursor.execute(f"ALTER TABLE {table} ADD COLUMN {col} {type_};")
                    print(f"Columna '{col}' agregada a la tabla '{table}'.")
                except Exception as e:
                    if "already exists" in str(e).lower():
                        print(f"La columna '{col}' ya existia en '{table}'.")
                    else:
                        print(f"Error al agregar '{col}' a '{table}': {e}")

        print("Verificando tabla 'users'...")
        add_cols("users", cols_users)

        print("\nVerificando tabla 'conversations'...")
        # Primero intentamos crear la tabla por si no existe en Postgres
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS conversations (
                    id VARCHAR(36) PRIMARY KEY,
                    request_id VARCHAR(36) UNIQUE NOT NULL,
                    client_id VARCHAR(36) NOT NULL,
                    worker_id VARCHAR(36) NOT NULL,
                    status VARCHAR(20) DEFAULT 'open',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print("Tabla 'conversations' verificada/creada.")
        except Exception as e:
            print(f"Error creando tabla 'conversations': {e}")

        add_cols("conversations", cols_convos)

        # --- TABLA MESSAGES ---
        print("\nVerificando tabla 'messages'...")
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id VARCHAR(36) PRIMARY KEY,
                    conversation_id VARCHAR(36) NOT NULL,
                    sender_id VARCHAR(36) NOT NULL,
                    content TEXT NOT NULL,
                    message_type VARCHAR(20) DEFAULT 'text',
                    status VARCHAR(20) DEFAULT 'pending',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print("Tabla 'messages' verificada/creada.")
        except Exception as e:
            print(f"Error creando tabla 'messages': {e}")

        print("\nVerificando tabla 'reports'...")
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS reports (
                    id VARCHAR(36) PRIMARY KEY,
                    reporter_id VARCHAR(36) NOT NULL,
                    reported_user_id VARCHAR(36),
                    reported_service_id VARCHAR(36),
                    reason VARCHAR(30) NOT NULL,
                    description TEXT,
                    status VARCHAR(30) DEFAULT 'pending',
                    admin_id VARCHAR(36),
                    admin_note TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    resolved_at TIMESTAMP
                );
            """)
            print("Tabla 'reports' verificada/creada.")
        except Exception as e:
            print(f"Error creando tabla 'reports': {e}")

        cursor.close()
        conn.close()
        print("\nMigracion de PostgreSQL finalizada correctamente.")

    except Exception as e:
        print(f"Error critico durante la migracion: {e}")

if __name__ == "__main__":
    migrate_all()

