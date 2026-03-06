import sqlite3

def upgrade_database():
    print("Iniciando migración de la base de datos local (SQLite)...")
    
    # Conectamos a la base de datos de desarrollo
    conn = sqlite3.connect('forja.db')
    cursor = conn.cursor()

    try:
        # 1. Agregar is_email_verified
        print("Agregando columna 'is_email_verified'...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT 0")
        print("✅ Columna 'is_email_verified' agregada con éxito.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna 'is_email_verified' ya existe. Ignorando...")
        else:
            print(f"❌ Error al agregar 'is_email_verified': {e}")

    try:
        # 2. Agregar verification_code
        print("Agregando columna 'verification_code'...")
        cursor.execute("ALTER TABLE users ADD COLUMN verification_code VARCHAR(6)")
        print("✅ Columna 'verification_code' agregada con éxito.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("⚠️ La columna 'verification_code' ya existe. Ignorando...")
        else:
            print(f"❌ Error al agregar 'verification_code': {e}")

    # En SQLite, no se puede hacer ALTER TABLE para añadir restricciones UNIQUE
    # a una columna existente fácilmente (hay que recrear la tabla). 
    # Para desarrollo, con que SQLAlchemy lo valide es suficiente. 
    # En producción con PostgreSQL sí se creará correctamente.

    # Guardamos los cambios y cerramos la conexión
    conn.commit()
    conn.close()
    
    print("🎉 Migración completada. Puedes iniciar el servidor.")

if __name__ == "__main__":
    upgrade_database()
