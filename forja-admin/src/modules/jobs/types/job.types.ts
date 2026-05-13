// src/modules/jobs/types/job.types.ts

export type JobStatus = 'open' | 'matched' | 'completed' | 'cancelled';

export interface JobPost {
  id: string;
  title: string;           
  description: string;
  client_name: string;
  worker_name: string;
  category: string;        
  location_city: string;   
  image_urls: string[];    
  status: JobStatus;
  budget?: number;         
  final_price: number;
  applicants_count: number;
  createdAt: string;
  started_at: string;
  completed_at: string | null;
  service_title: string;
}