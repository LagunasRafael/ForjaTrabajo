# Usa una imagen oficial de Python ligera
FROM python:3.12-slim

# Evita que Python escriba archivos .pyc en el disco
ENV PYTHONDONTWRITEBYTECODE=1
# Evita que Python haga buffer a la salida estándar, útil para ver logs de Docker
ENV PYTHONUNBUFFERED=1

# Instala dependencias del sistema requeridas para compilar paquetes (como psycopg2)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Establece el directorio de trabajo
WORKDIR /app

# Copia los requerimientos e instálalos
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copia el código de la aplicación
COPY . /app/

# Expone el puerto donde FastApi responderá (Render lo hace por defecto en el 8000 si no se dice lo contrario, pero usamos uvicorn estándar)
EXPOSE 8000

# Comando para ejecutar la aplicación
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
