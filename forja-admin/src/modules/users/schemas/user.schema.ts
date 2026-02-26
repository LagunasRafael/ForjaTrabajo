import { z } from 'zod';

const ROLES = ['admin', 'client', 'worker'] as const;
const STATUS = ['active', 'inactive', 'pending'] as const;

export const userSchema = z.object({
  name: z.string().min(3).max(50),
  email: z.string().email(),
  
  // Solución más compatible: Sin segundo argumento
  role: z.enum(ROLES), 

  status: z.enum(STATUS),
});

export type UserFormData = z.infer<typeof userSchema>;