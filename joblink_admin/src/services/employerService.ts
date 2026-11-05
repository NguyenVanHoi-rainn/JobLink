import api from './api';

export const employerService = {
  getPendingVerifications: async () => {
    const response = await api.get('/admin/employer-verifications');
    return response.data;
  },

  getVerificationDetail: async (id: string) => {
    const response = await api.get(`/admin/employer-verifications/${id}`);
    return response.data;
  },

  approveEmployer: async (id: string) => {
    const response = await api.patch(`/admin/employer-verifications/${id}/approve`);
    return response.data;
  },

  rejectEmployer: async (id: string, reason: string) => {
    const response = await api.patch(`/admin/employer-verifications/${id}/reject`, { reason });
    return response.data;
  },
};