import api from './api';

export const dashboardService = {
  getOverview: async () => {
    const response = await api.get('/admin/dashboard/overview');
    return response.data;
  },
};