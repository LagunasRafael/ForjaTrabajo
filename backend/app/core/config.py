from datetime import timedelta
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Stripe
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")

# URL de la plataforma (para Stripe Connect, CORS, etc.)
# En producción: https://tudominio.com
PLATFORM_URL = os.getenv("PLATFORM_URL", "https://forja-trabajo.com")
FRONTEND_URL = os.getenv("FRONTEND_URL", "*")

# CORS - separado por comas si múltiples orígenes
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",")]

# Scheduler
ENABLE_SCHEDULER = os.getenv("ENABLE_SCHEDULER", "true").lower() == "true"
SCHEDULER_INTERVAL_MINUTES = int(os.getenv("SCHEDULER_INTERVAL_MINUTES", "1"))

# Plazos de expiración (en minutos)
# Producción: PAYMENT_DUE_MINUTES=1440 (24h), AUTO_RELEASE_MINUTES=4320 (3 días)
PAYMENT_DUE_MINUTES = int(os.getenv("PAYMENT_DUE_MINUTES", "3"))
AUTO_RELEASE_MINUTES = int(os.getenv("AUTO_RELEASE_MINUTES", "3"))
