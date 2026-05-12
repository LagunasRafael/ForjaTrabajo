import axios from 'axios';
import { toast } from 'sonner';

// 1. Configuración Base
// Se usa una variable de entorno para que sea fácil cambiar entre Local y Producción
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 segundos de espera máxima
});

// 2. Interceptor de SOLICITUD (Request)
// Antes de salir hacia FastAPI, revisamos si hay token y lo pegamos
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 3. Interceptor de RESPUESTA (Response)
// Aquí manejamos los errores globales para no repetirlos en cada componente
api.interceptors.response.use(
  (response) => {
    // Si la respuesta es exitosa (200-299), la dejamos pasar limpia
    return response;
  },
  async (error) => {
    const originalRequest = error.config;

    // A. Error de Autenticación (401) -> Token vencido o inválido
    if (error.response && error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true; // Evitar bucle infinito

      // 1. Intentamos refrescar el token
      try {
        const refreshToken = localStorage.getItem('refresh_token');
        if (refreshToken) {
          // Usamos axios puro (no 'api') para evitar que se intercepte de nuevo este refresco
          const response = await axios.post(`${api.defaults.baseURL}/auth/refresh`, {
            refresh_token: refreshToken
          });

          const newAccessToken = response.data.access_token;
          const newRefreshToken = response.data.refresh_token;

          // Guardamos los nuevos tokens
          localStorage.setItem('token', newAccessToken);
          localStorage.setItem('refresh_token', newRefreshToken);

          // Actualizamos el header de la petición fallida y la reintentamos
          originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
          return api(originalRequest);
        }
      } catch (refreshError) {
        // Falló el refresco (ej. token_refresco expirado)
        console.error("No se pudo refrescar el token", refreshError);
        // Continuamos al flujo de "Limpiar y Redirigir" que sigue...
      }

      // Si no tenemos refresh token o falló el refresco, desconectamos al usuario
      if (window.location.pathname !== '/login') {
        localStorage.removeItem('token'); // Borramos el token vencido
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        window.location.href = '/login'; // Redirigimos al usuario
        toast.error('Tu sesión ha expirado. Por favor ingresa nuevamente.');
      }
      return Promise.reject(error);
    }

    // B. Error de Permisos (403) -> Intentas entrar a zona de Admin siendo Usuario
    if (error.response && error.response.status === 403) {
      toast.warning('No tienes permisos para realizar esta acción.');
      return Promise.reject(error);
    }

    // C. Error de Servidor (500) -> FastAPI falló internamente
    if (error.response && error.response.status >= 500) {
      console.error('Error del servidor:', error.response.data);
      toast.error('Ocurrió un error en el servidor. Intenta más tarde.');
      return Promise.reject(error);
    }

    // D. Error de Conexión -> Backend apagado o sin internet
    if (error.code === 'ERR_NETWORK') {
      toast.error('No se pudo conectar con el servidor. Verifica tu conexión.');
      return Promise.reject(error);
    }

    // E. Otros errores (400, 404, 422 Validation Error)
    // Dejamos que pasen para que el componente específico decida qué mensaje mostrar
    // (Ej: "El email ya existe")
    return Promise.reject(error);
  }
);

export default api;