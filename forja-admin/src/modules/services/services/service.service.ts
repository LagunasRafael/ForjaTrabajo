import api from '../../../api/client';

export type JobStatus = 'open' | 'in_progress' | 'completed' | 'matched' |'cancelled';

export interface ServiceEntity {
  id: string;
  title: string;
  summary: string | null;
  description: string;
  basePrice: number;
  categoryId: string;
  location: {
    lat: number;
    lng: number;
    address: string;
  };
  imageUrls: string[];
  clientId: string;
  status: JobStatus;
  isActive: boolean;
  createdAt: string;
}

interface ServiceDTO {
  id: string;
  title: string;
  summary: string | null;
  description: string;
  base_price: number;
  category_id: string;
  latitude: number;
  longitude: number;
  exact_address: string;
  image_urls: string[];
  client_id: string;
  status: string;
  is_active: boolean;
  created_at: string;
}

const mapServiceFromApi = (dto: ServiceDTO): ServiceEntity => {
  // 🟢 AGREGA ESTE LOG TEMPORAL:
  if (dto.status !== 'open') {
    console.log(`🔍 Servicio [${dto.id}] -> Status en JSON:`, dto.status);
  }

  return {
    id: dto.id,
    title: dto.title,
    summary: dto.summary,
    description: dto.description,
    basePrice: dto.base_price,
    categoryId: dto.category_id,
    location: {
      lat: dto.latitude,
      lng: dto.longitude,
      address: dto.exact_address,
    },
    imageUrls: dto.image_urls,
    clientId: dto.client_id,
    status: (dto.status?.toLowerCase() || 'open') as JobStatus, // 🛡️ Blindaje: lo pasamos a minúsculas
    isActive: dto.is_active,
    createdAt: dto.created_at,
  };
};

export const getServiceById = async (id: string): Promise<ServiceEntity> => {
  const { data } = await api.get<ServiceDTO>(`/services/${id}`);
  return mapServiceFromApi(data);
};

export const getServices = async (): Promise<ServiceEntity[]> => {
  const { data } = await api.get<ServiceDTO[]>('/services?include_inactive=true');
  return data.map(mapServiceFromApi);
};

// 🔵 ACTUALIZAR STATUS (Para el flujo de trabajo: open, in_progress, etc.)
export const updateServiceStatus = async (id: string, status: JobStatus): Promise<ServiceEntity> => {
  const { data } = await api.patch<ServiceDTO>(`/services/${id}/status`, { status });
  return mapServiceFromApi(data);
};

// 🟠 ACTUALIZAR ESTADO DE ACTIVACIÓN (Para el botón de Banear/Activar)
export const toggleServiceActive = async (id: string, isActive: boolean): Promise<ServiceEntity> => {
  const payload = { is_active: isActive };
  
  // PATCH es ideal para actualizaciones parciales en FastAPI
  const { data } = await api.patch<ServiceDTO>(`/services/${id}/active`, payload);
  return mapServiceFromApi(data);
};

// 2. Función para ELIMINAR DEFINITIVAMENTE (Este endpoint YA EXISTE en FastAPI)
export const deleteServiceAdmin = async (id: string): Promise<void> => {
  await api.delete(`/services/${id}`);
};

// 🟢 CREAR: Traduce del Frontend al Backend
export const createService = async (service: Partial<ServiceEntity> | any): Promise<ServiceEntity> => {
  const payload = {
    title: service.title,
    description: service.description,
    // Soportamos ambos casos por si el componente aún envía snake_case
    base_price: service.basePrice || service.base_price, 
    category_id: service.categoryId || service.category_id,
    // Si Juan Luis requiere ubicación por defecto en la prueba:
    latitude: service.location?.lat || 19.69, 
    longitude: service.location?.lng || -100.54,
    exact_address: service.location?.address || "Ciudad Hidalgo, Centro"
  };

  const { data } = await api.post<ServiceDTO>('/services', payload);
  return mapServiceFromApi(data);
};


// --- AGREGAR EN service.service.ts ---

// Lo que viene de FastAPI (ServiceRequest de Juan Luis)
interface ServiceOfferDTO {
  id: string;
  service_id: string;
  worker_id: string;
  status: string;
  created_at: string;
  description: string;
  proposed_price: number; // Viene como Decimal/Number
  worker_name?: string;
}

// Lo que tú usas en React (Tu contrato de datos)
export interface ServiceOffer {
  id: string;
  serviceId: string;
  workerId: string;
  status: string;
  createdAt: string;
  description: string;
  proposedPrice: number;
  workerName: string;
}

// Mapper para transformar snake_case a camelCase
const mapOfferFromApi = (dto: ServiceOfferDTO): ServiceOffer => ({
  id: dto.id,
  serviceId: dto.service_id,
  workerId: dto.worker_id,
  status: dto.status,
  createdAt: dto.created_at,
  description: dto.description,
  proposedPrice: dto.proposed_price,
  workerName: dto.worker_name || 'Trabajador',
});

// Función para el endpoint de ofertas que discutimos
export const getServiceOffers = async (serviceId: string): Promise<ServiceOffer[]> => {
  const { data } = await api.get<ServiceOfferDTO[]>(`/services/${serviceId}/offers`);
  
  // Transformamos la lista de DTOs a nuestra entidad de React
  return data.map(dto => ({
    id: dto.id,
    serviceId: dto.service_id,
    workerId: dto.worker_id,
    status: dto.status,
    createdAt: dto.created_at,
    description: dto.description,
    proposedPrice: Number(dto.proposed_price), // Convertimos Decimal a Number
    workerName: dto.worker_name || 'Trabajador',
  }));
};
