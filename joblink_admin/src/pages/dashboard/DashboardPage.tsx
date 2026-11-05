import React, { useEffect, useState } from 'react';
import { dashboardService } from '../../services/dashboardService';
import { DashboardOverview } from '../../types/dashboard';

export const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardOverview | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchOverview = async () => {
      try {
        setLoading(true);
        const data = await dashboardService.getOverview();
        setStats(data);
      } catch (err: any) {
        setError('Không thể tải dữ liệu thống kê từ hệ thống.');
      } finally {
        setLoading(false); 
      }
    };

    fetchOverview();
  }, []);

  if (loading) {
    return <div style={{ padding: '24px', textAlign: 'center' }}>Đang tải số liệu thống kê...</div>;
  }

  if (error) {
    return <div style={{ padding: '24px', color: 'red', textAlign: 'center' }}>{error}</div>;
  }

  return (
    <div style={{ padding: '24px', backgroundColor: '#F5F7FB', minHeight: '100vh' }}>
      <h2 style={{ marginBottom: '24px', color: '#1E293B', fontWeight: 800 }}>Tổng quan hệ thống (Dashboard)</h2>

      {stats && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
          {/* Card Người dùng */}
          <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
            <h4 style={{ color: '#64748B', marginBottom: '8px' }}>Tổng Người Dùng</h4>
            
            <p style={{ fontSize: '28px', fontWeight: 700, color: '#2563EB' }}>
              {stats.users.workers + stats.users.employers}
            </p>
            
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '8px' }}>
              Worker: {stats.users.workers} | Employer: {stats.users.employers}
            </div>
          </div>

          {/* Card Việc làm */}
          <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
            <h4 style={{ color: '#64748B', marginBottom: '8px' }}>Tổng Tin Tuyển Dụng</h4>
            <p style={{ fontSize: '28px', fontWeight: 700, color: '#16A34A' }}>{stats.jobs.total}</p>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '8px' }}>
              Đang hiển thị: {stats.jobs.published}
            </div>
          </div>

          {/* Card Đơn ứng tuyển */}
          <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
            <h4 style={{ color: '#64748B', marginBottom: '8px' }}>Lượt Ứng Tuyển</h4>
            <p style={{ fontSize: '28px', fontWeight: 700, color: '#D97706' }}>{stats.applications.total}</p>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '8px' }}>Tổng số đơn gửi đi</div>
          </div>

          {/* Card Báo cáo vi phạm */}
          <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
            <h4 style={{ color: '#64748B', marginBottom: '8px' }}>Báo Cáo Vi Phạm</h4>
            <p style={{ fontSize: '28px', fontWeight: 700, color: '#DC2626' }}>{stats.reports.total}</p>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '8px' }}>
              Cần xử lý: {stats.reports.open}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};