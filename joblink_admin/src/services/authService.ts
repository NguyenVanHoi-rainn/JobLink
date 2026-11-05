import api from './api';

export interface LoginCredentials {
  email: string;
  password: string;
}

export const authService = {
  login: async (credentials: LoginCredentials) => {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  },

  logout: async () => {
    localStorage.removeItem('admin_token');
  },

  getCurrentAdmin: async () => {
    const response = await api.get('/auth/me');
    return response.data;
  },
};