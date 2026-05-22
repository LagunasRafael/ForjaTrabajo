import os
import psycopg2
from dotenv import load_dotenv

def migrate():
    print("🚀 Agregando columnas de expiración a la tabla 'jobs'...")
    load_dotenv()

    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("❌ Error: No se encontró DATABASE_URL en el archivo .env")
        return

    try:
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cursor = conn.cursor()

        print("⏳ Agregando columna 'payment_due_at'...")
        try:
            cursor.execute("ALTER TABLE jobs ADD COLUMN payment_due_at TIMESTAMP;")
            print("✅ Columna 'payment_due_at' agregada.")
        except psycopg2.errors.DuplicateColumn:
            print("ℹ️ La columna 'payment_due_at' ya existía.")

        print("⏳ Agregando columna 'auto_release_at'...")
        try:
            cursor.execute("ALTER TABLE jobs ADD COLUMN auto_release_at TIMESTAMP;")
            print("✅ Columna 'auto_release_at' agregada.")
        except psycopg2.errors.DuplicateColumn:
            print("ℹ️ La columna 'auto_release_at' ya existía.")

        cursor.close()
        conn.close()
        print("🎉 Migración completada.")

    except Exception as e:
        print(f"❌ Error durante la migración: {e}")

if __name__ == "__main__":
    migrate()
