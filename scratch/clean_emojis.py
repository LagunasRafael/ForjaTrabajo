import sys
import os

# Añadir el directorio raíz al path para poder importar la app
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.models import Message

def clean_messages_emojis():
    db: Session = SessionLocal()
    try:
        print("🔍 Buscando mensajes con emojis para limpiar...")
        # Lista de emojis y textos viejos que queremos limpiar
        replacements = {
            "👨‍ADMIN:": "ADMINISTRADOR:",
            "🚨": "",
            "👨‍⚖️": "",
            "⚖️": "",
            "🚩": "",
            "RESOLUCIÓN FINAL:": "RESOLUCION FINAL:",
        }

        messages = db.query(Message).all()
        updated_count = 0

        for msg in messages:
            original_content = msg.content
            new_content = original_content
            
            for old, new in replacements.items():
                if old in new_content:
                    new_content = new_content.replace(old, new).strip()
            
            if new_content != original_content:
                msg.content = new_content
                updated_count += 1
        
        db.commit()
        print(f"✅ ¡Limpieza completada! Se actualizaron {updated_count} mensajes.")
        
    except Exception as e:
        print(f"❌ Error durante la limpieza: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    clean_messages_emojis()
