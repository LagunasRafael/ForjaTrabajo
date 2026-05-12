from datetime import timedelta

SECRET_KEY = "super-secret-key-cambiar-luego"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Stripe
# IMPORTANTE: En producción, usa variables de entorno en lugar de hardcodear
# import os
# STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
STRIPE_SECRET_KEY = "sk_test_51TJMelEEBDNiDvB28AuDKrE08OQAAU4Cq2vVGRmXqRRLbCsmSzClMrMkK2vJPrQZH6IbIw0e8828olGuwcN94MsU001MkjN0JB"
STRIPE_PUBLISHABLE_KEY = "pk_test_51TJMelEEBDNiDvB2T001jsfxYvutidQ8BQqrJCQutevL29fBc1IDFdo2Yfvdmf8H0UHWKw8y98kl9ABuFYRMLneC00e16IS4Qy"
