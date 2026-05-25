export type UserRole = 'admin' | 'client' | 'worker'; 
export type UserStatus = 'active' | 'inactive' | 'pending' | 'banned';

export interface User {
  id: string;
  full_name: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  avatarUrl?: string;
  createdAt: string; 
  lastLogin?: string;
}