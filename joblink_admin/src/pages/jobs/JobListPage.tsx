import React, { useEffect, useState } from 'react';
import { jobService } from '../../services/jobService';

interface Job {
  id: string;
  title: string;
  salary: string;
  status: string;
  createdAt: string;
  employer: {
    companyName: string;
  };
}

export const JobListPage: React.FC = () => {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = async () => {
    try {
      setLoading(true);
      const data = await jobService.getJobs();
      setJobs(data.items || data);
    } catch (err: any) {
      setError('Không thể tải danh sách tin tuyển dụng.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, []);

  const handleUpdateStatus = async (jobId: string, newStatus: 'PUBLISHED' | 'REJECTED' | 'DELETED') => {
    const actionText = newStatus === 'PUBLISHED' ? 'duyệt' : newStatus === 'REJECTED' ? 'từ chối' : 'gỡ bỏ';
    if (!window.confirm(`Bạn có chắc chắn muốn ${actionText} tin tuyển dụng này không?`)) return;

    try {
      await jobService.updateJobStatus(jobId, newStatus);
      fetchJobs();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Không thể cập nhật trạng thái tin tuyển dụng.');
    }
  };

  if (loading) {
    return <div style={{ padding: '24px', textAlign: 'center' }}>Đang tải danh sách tin tuyển dụng...</div>;
  }

  if (error) {
    return <div style={{ padding: '24px', color: 'red', textAlign: 'center' }}>{error}</div>;
  }

  return (
    <div style={{ padding: '24px', backgroundColor: '#F5F7FB', minHeight: '100vh' }}>
      <h2 style={{ marginBottom: '24px', color: '#1E293B', fontWeight: 800 }}>Kiểm duyệt Tin tuyển dụng</h2>

      <div style={{ background: 'white', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#64748B', fontSize: '14px' }}>
              <th style={{ padding: '16px' }}>Tiêu đề công việc</th>
              <th style={{ padding: '16px' }}>Nhà tuyển dụng</th>
              <th style={{ padding: '16px' }}>Mức lương</th>
              <th style={{ padding: '16px' }}>Trạng thái</th>
              <th style={{ padding: '16px', textAlign: 'center' }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {jobs.map((job) => (
              <tr key={job.id} style={{ borderBottom: '1px solid #F1F5F9', fontSize: '14px', color: '#334155' }}>
                <td style={{ padding: '16px', fontWeight: 600 }}>{job.title}</td>
                <td style={{ padding: '16px' }}>{job.employer?.companyName || 'N/A'}</td>
                <td style={{ padding: '16px' }}>{job.salary || 'Thỏa thuận'}</td>
                <td style={{ padding: '16px' }}>
                  <span style={{
                    padding: '4px 10px',
                    borderRadius: '20px',
                    fontSize: '12px',
                    fontWeight: 600,
                    background: job.status === 'PUBLISHED' ? '#DCFCE7' : '#FEF3C7',
                    color: job.status === 'PUBLISHED' ? '#16A34A' : '#D97706',
                  }}>
                    {job.status}
                  </span>
                </td>
                <td style={{ padding: '16px', textAlign: 'center', display: 'flex', justifyContent: 'center', gap: '8px' }}>
                  {job.status !== 'PUBLISHED' && (
                    <button
                      onClick={() => handleUpdateStatus(job.id, 'PUBLISHED')}
                      style={{ padding: '6px 12px', background: '#16A34A', color: 'white', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: 'pointer' }}
                    >
                      Duyệt
                    </button>
                  )}
                  <button
                    onClick={() => handleUpdateStatus(job.id, 'REJECTED')}
                    style={{ padding: '6px 12px', background: '#DC2626', color: 'white', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: 'pointer' }}
                  >
                    Từ chối
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};