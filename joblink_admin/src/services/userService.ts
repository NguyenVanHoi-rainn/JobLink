import api from './api';

export const userService = {
  getUsers: async () => {
    const response = await api.get('/admin/users');
    return response.data;
  },

  lockUser: async (userId: string) => {
    const response = await api.patch(`/admin/users/${userId}/lock`);
    return response.data;
  },

  unlockUser: async (userId: string) => {
    const response = await api.patch(`/admin/users/${userId}/unlock`);
    return response.data;
  },
};