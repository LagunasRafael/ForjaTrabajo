import os
import getpass
import sys

# Agregamos el directorio actual al path para poder importar módulos de 'app'
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.auth.models import User
from app.services.models import Service # Importante para que SQLAlchemy mapee la relación
from app.core.roles import Role

# Usamos bcrypt directamente para evitar bugs de passlib
import bcrypt as _bcrypt

# URL de Producción en Render
DB_URL = "postgresql://forjadb_user:lx5paY7hoBAQ5dV3I5w4m62Oe0rPV3GU@dpg-d6k8tjfkijhs73cpq01g-a.oregon-postgres.render.com/forjadb"

engine = create_engine(DB_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_admin():
    print("\n" + "="*50)
    print("🛠️  CREACIÓN DE CUENTA DE ADMINISTRADOR")
    print("="*50 + "\n")
    
    full_name = input("Nombre completo: ").strip()
    email = input("Correo electrónico: ").strip()
    phone = input("Teléfono (opcional): ").strip()
    
    # Usamos input() en vez de getpass porque getpass captura basura en Windows PowerShell
    password = input("Contraseña: ").strip()
    password_confirm = input("Confirmar contraseña: ").strip()
    
    if password != password_confirm:
        print("\n❌ Error: Las contraseñas no coinciden.")
        return
        
    if not email or not password or not full_name:
        print("\n❌ Error: Nombre, correo y contraseña son obligatorios.")
        return
        
    print(f"\nConectando a la base de datos de producción...")
    db = SessionLocal()
    try:
        # 1. Verificar si el usuario ya existe
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"\n❌ Error: El correo '{email}' ya está registrado (Rol actual: {existing_user.role}).")
            return
            
        # 2. Generar el hash directamente con bcrypt (evita bugs de passlib)
        pwd_bytes = password.encode("utf-8")[:72]  # Truncar a 72 BYTES (límite de bcrypt)
        hashed_pw = _bcrypt.hashpw(pwd_bytes, _bcrypt.gensalt()).decode("utf-8")
        
        # 3. Crear el nuevo usuario administrador
        new_admin = User(
            full_name=full_name,
            email=email,
            phone=phone if phone else None,
            hashed_password=hashed_pw,
            role=Role.ADMIN,
            is_email_verified=True  # El administrador no necesita verificar su correo
        )
        
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)
        
        print("\n✅ ¡Administrador creado exitosamente en Producción!")
        print("-" * 30)
        print(f"ID     : {new_admin.id}")
        print(f"Nombre : {new_admin.full_name}")
        print(f"Correo : {new_admin.email}")
        print(f"Rol    : {new_admin.role}")
        print("-" * 30 + "\n")
        print("Ya puedes iniciar sesión en la app con este correo.\n")
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Error crítico de base de datos: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
