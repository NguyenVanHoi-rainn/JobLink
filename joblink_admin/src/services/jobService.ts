import api from './api';

export type AdminJobStatus = 'DRAFT' | 'PUBLISHED' | 'CLOSED' | 'HIDDEN';

export const jobService = {
  getJobs: async (status?: string) => {
    const response = await api.get('/admin/jobs', {
      params: status ? { status } : undefined,
    });
    return response.data;
  },

  updateJobStatus: async (jobId: string, status: AdminJobStatus) => {
    const response = await api.patch(`/admin/jobs/${jobId}/status`, { status });
    return response.data;
  },
};