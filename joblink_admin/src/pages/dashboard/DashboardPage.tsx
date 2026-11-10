import React, { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { dashboardService } from '../../services/dashboardService';
import { DashboardOverview } from '../../types/dashboard';

export const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOverview = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      setStats(await dashboardService.getOverview());
    } catch {
      setError('Không thể tải dữ liệu thống kê. Hãy thử tải lại.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchOverview();
  }, [fetchOverview]);

  const cards = stats
    ? [
        {
          label: 'Người dùng',
          value: stats.users.total,
          note: `${stats.users.active} đang hoạt động · ${stats.users.locked} bị khóa`,
          color: '#315bd6',
        },
        {
          label: 'Hồ sơ chờ xác minh',
          value: stats.employers.pendingVerifications,
          note: 'Nhà tuyển dụng chờ duyệt',
          color: '#d88716',
        },
        {
          label: 'Tin tuyển dụng',
          value: stats.jobs.total,
          note: `${stats.jobs.published} đang hiển thị`,
          color: '#14804a',
        },
        {
          label: 'Đơn ứng tuyển',
          value: stats.applications.total,
          note: 'Tổng số đơn gửi đi',
          color: '#7c52c5',
        },
        {
          label: 'Báo cáo cần xử lý',
          value: stats.reports.open + stats.reports.reviewing,
          note: `${stats.reports.total} báo cáo tất cả`,
          color: '#c13d4b',
        },
      ]
    : [];

  return (
    <section className="admin-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">TỔNG QUAN</p>
          <h1>Dashboard</h1>
          <p className="page-description">Tình hình hoạt động hiện tại của JobLink.</p>
        </div>
        <button className="button button-secondary" onClick={() => void fetchOverview()} disabled={loading}>
          {loading ? 'Đang cập nhật...' : 'Làm mới số liệu'}
        </button>
      </div>

      {error && <div className="state-message state-error" role="alert">{error}</div>}
      {loading && !stats && <div className="state-message">Đang tải số liệu thống kê...</div>}

      {stats && (
        <>
          <div className="stats-grid">
            {cards.map((card) => (
              <article className="stat-card" style={{ '--accent': card.color } as React.CSSProperties} key={card.label}>
                <div className="stat-label">{card.label}</div>
                <div className="stat-value">{card.value.toLocaleString('vi-VN')}</div>
                <div className="stat-note">{card.note}</div>
              </article>
            ))}
          </div>

          <div className="dashboard-lower">
            <section className="dashboard-panel">
              <h2>Trạng thái hệ thống</h2>
              <div className="breakdown-row"><span>Tài khoản đang hoạt động</span><strong>{stats.users.active}</strong></div>
              <div className="breakdown-row"><span>Tài khoản bị khóa</span><strong>{stats.users.locked}</strong></div>
              <div className="breakdown-row"><span>Tin bản nháp</span><strong>{stats.jobs.draft}</strong></div>
              <div className="breakdown-row"><span>Tin đã đóng</span><strong>{stats.jobs.closed}</strong></div>
              <div className="breakdown-row"><span>Tin đang ẩn</span><strong>{stats.jobs.hidden}</strong></div>
              <div className="breakdown-row"><span>Lịch hẹn</span><strong>{stats.appointments.total}</strong></div>
            </section>

            <section className="dashboard-panel">
              <h2>Truy cập nhanh</h2>
              <div className="quick-links">
                <Link className="quick-link" to="/employers">
                  <span>Duyệt nhà tuyển dụng</span><strong>{stats.employers.pendingVerifications}</strong>
                </Link>
                <Link className="quick-link" to="/jobs">
                  <span>Kiểm duyệt tin tuyển dụng</span><span>→</span>
                </Link>
                <Link className="quick-link" to="/users">
                  <span>Quản lý người dùng</span><span>→</span>
                </Link>
              </div>
            </section>
          </div>
        </>
      )}
    </section>
  );
};
