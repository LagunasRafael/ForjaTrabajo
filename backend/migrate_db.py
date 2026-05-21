import sqlite3
import os

DB_PATH = "forja.db"

def migrate():
    if not os.path.exists(DB_PATH):
        print("❌ No se encontró la base de datos sqlite en", DB_PATH)
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    try:
        # Añadir fcm_token
        print("Intentando añadir la columna fcm_token a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255);")
        print("✅ Columna fcm_token añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna fcm_token ya existía.")
        else:
            print(f"Error al añadir fcm_token: {e}")

    try:
        # Añadir created_at
        print("Intentando añadir la columna created_at a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN created_at DATETIME;")
        print("✅ Columna created_at añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna created_at ya existía.")
        else:
            print(f"Error al añadir created_at: {e}")

    try:
        # Añadir is_deleted_by_client
        print("Intentando añadir la columna is_deleted_by_client a conversations...")
        cursor.execute("ALTER TABLE conversations ADD COLUMN is_deleted_by_client BOOLEAN DEFAULT FALSE;")
        print("✅ Columna is_deleted_by_client añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna is_deleted_by_client ya existía.")
        else:
            print(f"Error al añadir is_deleted_by_client: {e}")

    try:
        # Añadir is_deleted_by_worker
        print("Intentando añadir la columna is_deleted_by_worker a conversations...")
        cursor.execute("ALTER TABLE conversations ADD COLUMN is_deleted_by_worker BOOLEAN DEFAULT FALSE;")
        print("Columna is_deleted_by_worker añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("La columna is_deleted_by_worker ya existía.")
        else:
            print(f"Error al añadir is_deleted_by_worker: {e}")

    try:
        # Añadir stripe_customer_id
        print("Intentando añadir la columna stripe_customer_id a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(255);")
        print("✅ Columna stripe_customer_id añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna stripe_customer_id ya existía.")
        else:
            print(f"Error al añadir stripe_customer_id: {e}")

    try:
        # Añadir is_email_verified
        print("Intentando añadir la columna is_email_verified a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT FALSE;")
        print("✅ Columna is_email_verified añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna is_email_verified ya existía.")
        else:
            print(f"Error al añadir is_email_verified: {e}")

    try:
        # Añadir verification_code
        print("Intentando añadir la columna verification_code a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN verification_code VARCHAR(6);")
        print("✅ Columna verification_code añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna verification_code ya existía.")
        else:
            print(f"Error al añadir verification_code: {e}")

    try:
        # Añadir is_identity_verified
        print("Intentando añadir la columna is_identity_verified a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_identity_verified BOOLEAN DEFAULT FALSE;")
        print("✅ Columna is_identity_verified añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna is_identity_verified ya existía.")
        else:
            print(f"Error al añadir is_identity_verified: {e}")

    try:
        # Añadir stripe_account_id
        print("Intentando añadir la columna stripe_account_id a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN stripe_account_id VARCHAR(255);")
        print("✅ Columna stripe_account_id añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna stripe_account_id ya existía.")
        else:
            print(f"Error al añadir stripe_account_id: {e}")
        print("Intentando añadir la columna is_banned a users...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_banned BOOLEAN DEFAULT FALSE;")
        print("Columna is_banned añadida correctamente.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("La columna is_banned ya existía.")
        else:
            print(f"Error al añadir is_banned: {e}")

    try:
        print("Creando tabla reports...")
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
                created_at DATETIME,
                resolved_at DATETIME,
                FOREIGN KEY (reporter_id) REFERENCES users(id),
                FOREIGN KEY (reported_user_id) REFERENCES users(id),
                FOREIGN KEY (reported_service_id) REFERENCES services(id),
                FOREIGN KEY (admin_id) REFERENCES users(id)
            )
        """)
        print("Tabla reports creada correctamente.")
    except sqlite3.OperationalError as e:
        print(f"Error al crear reports: {e}")

    conn.commit()
    conn.close()
    print("Migración finalizada.")

if __name__ == "__main__":
    migrate()
