from app.db.database import SessionLocal
from app.services.notifications import service
from app.services import models
import uuid

db = SessionLocal()
try:
    # Get a user id from the DB
    user = db.query(models.Service).first()
    if user:
        user_id = user.client_id
        print(f"Testing for user_id: {user_id}")
        notifs = service.get_user_notifications(db, str(user_id))
        print(f"Found {len(notifs)} notifications")
        for n in notifs:
            print(f"- {n.title}: {n.is_read}")
    else:
        print("No users/services found to test with.")
finally:
    db.close()
