import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool

# Leemos la URL de la base de datos desde el archivo .env o variables del sistema
# Si no existe, usamos la base de datos SQLite local de siempre
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./forja.db")

# Si la URL empieza con sqlite, necesitamos "check_same_thread"
# Si es PostgreSQL (para producción), no necesitamos eso.
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}
    engine = create_engine(DATABASE_URL, connect_args=connect_args)
else:
    # Supabase/PgBouncer ya maneja el pool, deshabilitamos el de SQLAlchemy
    engine = create_engine(DATABASE_URL, poolclass=NullPool, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
