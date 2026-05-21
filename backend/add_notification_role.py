import os
import sys
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("DATABASE_URL no configurada")
    sys.exit(1)

# Fix for Render/Heroku postgres:// vs postgresql://
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    try:
        print("Añadiendo columna target_role a notifications...")
        conn.execute(text("ALTER TABLE notifications ADD COLUMN target_role VARCHAR(20);"))
        conn.commit()
        print("¡Columna añadida con éxito!")
    except Exception as e:
        print(f"Error o la columna ya existe: {e}")
