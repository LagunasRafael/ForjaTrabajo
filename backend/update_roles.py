from app.db.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("UPDATE users SET role='client' WHERE email LIKE '%diegogabrielmartinezalanis%'"))
    db.execute(text("UPDATE users SET role='worker' WHERE email LIKE '%gm7338701%'"))
    db.commit()
    print("Roles actualizados correctamente mediante SQL directo")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
