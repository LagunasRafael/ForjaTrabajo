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

    conn.commit()
    conn.close()
    print("Migración finalizada.")

if __name__ == "__main__":
    migrate()
