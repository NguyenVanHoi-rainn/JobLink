import api from './api';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AuthenticatedUser {
  sub: string;
  email: string;
  role: 'WORKER' | 'EMPLOYER' | 'ADMIN';
}

export const authService = {
  login: async (credentials: LoginCredentials) => {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  },

  logout: async () => {
    localStorage.removeItem('admin_token');
  },

  getCurrentAdmin: async (token?: string): Promise<AuthenticatedUser> => {
    const response = await api.get<AuthenticatedUser>(
      '/auth/me',
      token
        ? { headers: { Authorization: `Bearer ${token}` } }
        : undefined,
    );
    return response.data;
  },
};