import api from './api';

export const jobService = {
  getJobs: async (status?: string) => {
    const response = await api.get('/admin/jobs', { params: { status } });
    return response.data;
  },

  updateJobStatus: async (jobId: string, status: 'PUBLISHED' | 'REJECTED' | 'DELETED') => {
    const response = await api.patch(`/admin/jobs/${jobId}/status`, { status });
    return response.data;
  },
};