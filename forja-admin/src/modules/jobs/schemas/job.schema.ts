import { z } from 'zod';

export const jobSchema = z.object({
  title: z.string().min(5, 'El título es muy corto'),
  description: z.string().min(20, 'Describe mejor el problema para el trabajador'),
  category: z.string().min(1, 'Selecciona una categoría'),
  location_city: z.string().min(3, 'La ciudad es obligatoria'),
});

export type JobFormData = z.infer<typeof jobSchema>;