export interface User {
  id: string;
  email: string;
  role: 'WORKER' | 'EMPLOYER' | 'ADMIN';
  status: 'ACTIVE' | 'LOCKED';
  createdAt: string;
}