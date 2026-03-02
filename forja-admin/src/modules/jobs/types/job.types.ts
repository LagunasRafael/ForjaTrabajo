// src/modules/jobs/types/job.types.ts

export type JobStatus = 'open' | 'matched' | 'completed' | 'cancelled';

export interface JobPost {
  id: string;
  title: string;           // Ej: "Fuga de agua en lavabo"
  description: string;
  client_name: string;
  category: string;        // Ej: "Plomería"
  location_city: string;   // <-- NUEVO: Solo la ciudad/municipio
  image_urls: string[];    // <-- NUEVO: Arreglo de fotos adjuntas
  status: JobStatus;
  budget?: number;         // Presupuesto sugerido (opcional)
  applicants_count: number;// Trabajadores interesados
  createdAt: string;
}