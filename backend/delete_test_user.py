import psycopg2

DB_URL = "postgresql://forjadb_user:lx5paY7hoBAQ5dV3I5w4m62Oe0rPV3GU@dpg-d6k8tjfkijhs73cpq01g-a.oregon-postgres.render.com/forjadb"

def delete_user(email):
    try:
        print(f"Conectando a Render para eliminar a {email}...")
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor()
        
        # Eliminar al usuario
        cursor.execute("DELETE FROM users WHERE email = %s;", (email,))
        deleted_rows = cursor.rowcount
        conn.commit()
        
        if deleted_rows > 0:
            print(f"✅ Usuario {email} eliminado exitosamente de la base de datos de producción.")
        else:
            print(f"⚠️ El usuario {email} no se encontró en la base de datos (quizá ya fue eliminado).")
            
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Error crítico durante la eliminación: {e}")

if __name__ == "__main__":
    delete_user("forjatrabajo@gmail.com")
