from slowapi import Limiter
from slowapi.util import get_remote_address

# Inicializamos el limitador aquí para evitar importaciones circulares
limiter = Limiter(key_func=get_remote_address)
