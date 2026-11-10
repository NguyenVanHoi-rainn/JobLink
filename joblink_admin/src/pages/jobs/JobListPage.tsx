import React, { useEffect, useMemo, useState } from 'react';
import { AdminJobStatus, jobService } from '../../services/jobService';

interface Job {
  id: string;
  title: string;
  salary: string | number | null;
  salaryType: string;
  location: string;
  status: AdminJobStatus;
  createdAt: string;
  employer: {
    companyName: string;
  };
}

const statusLabels: Record<AdminJobStatus, string> = {
  DRAFT: 'Bản nháp',
  PUBLISHED: 'Đang hiển thị',
  CLOSED: 'Đã đóng',
  HIDDEN: 'Đã ẩn',
};

export const JobListPage: React.FC = () => {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [updatingJobId, setUpdatingJobId] = useState<string | null>(null);

  const fetchJobs = async () => {
    try {
      setLoading(true);
      setError(null);
      setJobs(await jobService.getJobs());
    } catch {
      setError('Không thể tải danh sách tin tuyển dụng. Hãy thử tải lại.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchJobs();
  }, []);

  const filteredJobs = useMemo(() => {
    const term = search.trim().toLocaleLowerCase();
    return jobs.filter((job) => {
      const matchesSearch =
        !term ||
        job.title.toLocaleLowerCase().includes(term) ||
        job.employer.companyName.toLocaleLowerCase().includes(term) ||
        job.location.toLocaleLowerCase().includes(term);
      return matchesSearch && (statusFilter === 'ALL' || job.status === statusFilter);
    });
  }, [jobs, search, statusFilter]);

  const handleUpdateStatus = async (job: Job, status: AdminJobStatus) => {
    const action = status === 'PUBLISHED' ? 'hiển thị' : status === 'HIDDEN' ? 'ẩn' : 'đóng';
    if (!window.confirm(`Bạn có chắc chắn muốn ${action} tin "${job.title}"?`)) return;

    try {
      setUpdatingJobId(job.id);
      setError(null);
      await jobService.updateJobStatus(job.id, status);
      await fetchJobs();
    } catch {
      setError(`Không thể ${action} tin tuyển dụng này.`);
    } finally {
      setUpdatingJobId(null);
    }
  };

  return (
    <section className="admin-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">KIỂM DUYỆT</p>
          <h1>Tin tuyển dụng</h1>
          <p className="page-description">Theo dõi và cập nhật trạng thái tin đăng.</p>
        </div>
        <button className="button button-secondary" onClick={() => void fetchJobs()} disabled={loading}>
          {loading ? 'Đang tải...' : 'Làm mới'}
        </button>
      </div>

      <div className="filter-bar">
        <input
          aria-label="Tìm tin tuyển dụng"
          placeholder="Tìm tiêu đề, công ty hoặc địa điểm..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <select aria-label="Lọc trạng thái tin" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="ALL">Tất cả trạng thái</option>
          {Object.entries(statusLabels).map(([status, label]) => (
            <option key={status} value={status}>{label}</option>
          ))}
        </select>
        <span className="result-count">
          {loading && jobs.length === 0 ? 'Đang tải...' : `${filteredJobs.length} tin tuyển dụng`}
        </span>
      </div>

      {error && <div className="state-message state-error" role="alert">{error}</div>}
      {loading && jobs.length === 0 && <div className="state-message">Đang tải danh sách tin tuyển dụng...</div>}

      {!loading && !error && filteredJobs.length === 0 && (
        <div className="state-message">
          {jobs.length === 0 ? 'Chưa có tin tuyển dụng.' : 'Không tìm thấy tin phù hợp.'}
        </div>
      )}

      {filteredJobs.length > 0 && (
        <div className="table-card">
          <div className="table-scroll">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Tin tuyển dụng</th>
                  <th>Nhà tuyển dụng</th>
                  <th>Lương</th>
                  <th>Trạng thái</th>
                  <th>Ngày đăng</th>
                  <th>Hành động</th>
                </tr>
              </thead>
              <tbody>
                {filteredJobs.map((job) => (
                  <tr key={job.id}>
                    <td>
                      <div className="cell-primary">{job.title}</div>
                      <div className="cell-secondary">{job.location}</div>
                    </td>
                    <td>{job.employer.companyName}</td>
                    <td>{job.salary == null ? 'Thỏa thuận' : `${Number(job.salary).toLocaleString('vi-VN')} đ`}</td>
                    <td>
                      <span className={`status-badge status-${job.status.toLowerCase()}`}>
                        {statusLabels[job.status]}
                      </span>
                    </td>
                    <td>{new Date(job.createdAt).toLocaleDateString('vi-VN')}</td>
                    <td className="action-cell">
                      {job.status !== 'PUBLISHED' && (
                        <button
                          className="button button-success"
                          disabled={updatingJobId === job.id}
                          onClick={() => void handleUpdateStatus(job, 'PUBLISHED')}
                        >
                          Duyệt / Hiển thị
                        </button>
                      )}
                      {job.status === 'PUBLISHED' && (
                        <button
                          className="button button-danger"
                          disabled={updatingJobId === job.id}
                          onClick={() => void handleUpdateStatus(job, 'HIDDEN')}
                        >
                          Ẩn tin
                        </button>
                      )}
                      {job.status !== 'CLOSED' && (
                        <button
                          className="button button-secondary"
                          disabled={updatingJobId === job.id}
                          onClick={() => void handleUpdateStatus(job, 'CLOSED')}
                        >
                          Đóng tin
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </section>
  );
};
