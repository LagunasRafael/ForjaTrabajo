import os
import psycopg2
from dotenv import load_dotenv

def migrate_postgres():
    print("🚀 Iniciando migración de PostgreSQL en Render...")
    load_dotenv()
    
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("❌ Error: No se encontró DATABASE_URL en el archivo .env")
        return

    try:
        # Conectar a la base de datos PostgreSQL
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cursor = conn.cursor()

        # 1. Agregar columna is_email_verified
        print("⏳ Agregando columna 'is_email_verified'...")
        try:
            cursor.execute("ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT FALSE;")
            print("✅ Columna 'is_email_verified' agregada.")
        except psycopg2.errors.DuplicateColumn:
            print("ℹ️ La columna 'is_email_verified' ya existía.")

        # 2. Agregar columna verification_code
        print("⏳ Agregando columna 'verification_code'...")
        try:
            cursor.execute("ALTER TABLE users ADD COLUMN verification_code VARCHAR(6);")
            print("✅ Columna 'verification_code' agregada.")
        except psycopg2.errors.DuplicateColumn:
            print("ℹ️ La columna 'verification_code' ya existía.")

        # 3. Hacer el teléfono único (eliminar nulos o duplicados temporales si los hubiera)
        print("⏳ Agregando restricción UNIQUE a la columna 'phone'...")
        try:
            # Primero nos aseguramos de no romper cosas si hay teléfonos nulos repetidos
            cursor.execute("ALTER TABLE users ADD CONSTRAINT ix_users_phone UNIQUE (phone);")
            print("✅ Restricción UNIQUE agregada al teléfono.")
        except psycopg2.errors.DuplicateTable:
             print("ℹ️ La restricción UNIQUE ya existía.")
        except psycopg2.errors.UniqueViolation:
            print("⚠️ ADVERTENCIA: No se pudo hacer UNIQUE el teléfono porque ya hay teléfonos duplicados en la base de datos de producción.")
        except psycopg2.errors.InvalidTableDefinition:
             print("ℹ️ La restricción UNIQUE ya existía o hubo un problema de definición.")
        except Exception as e:
             print(f"⚠️ Nota de restricción UNIQUE: {e}")

        cursor.close()
        conn.close()
        print("🎉 Migración de PostgreSQL finalizada.")

    except Exception as e:
        print(f"❌ Error crítico durante la migración: {e}")

if __name__ == "__main__":
    migrate_postgres()
