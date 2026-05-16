from dotenv import load_dotenv
import os
load_dotenv()

from app.db.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    # pyrefly: ignore [unsupported-operation]
    print(f"DATABASE_URL: {os.getenv('DATABASE_URL')[:20]}...")
    res = db.execute(text("SELECT email, role FROM users")).fetchall()
    for row in res:
        print(f"Email: {row[0]}, Role: {row[1]}")
finally:
    db.close()
