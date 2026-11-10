import React, { useEffect, useMemo, useState } from 'react';
import { employerService } from '../../services/employerService';
import { EmployerVerification } from '../../types/employer';

const verificationLabels: Record<EmployerVerification['verificationStatus'], string> = {
  UNVERIFIED: 'Chưa gửi xác minh',
  PENDING: 'Chờ xác minh',
  VERIFIED: 'Đã xác minh',
  REJECTED: 'Bị từ chối',
};

export const EmployerListPage: React.FC = () => {
  const [employers, setEmployers] = useState<EmployerVerification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [saving, setSaving] = useState(false);

  const fetchEmployers = async () => {
    try {
      setLoading(true);
      setError(null);
      setEmployers(await employerService.getPendingVerifications());
    } catch {
      setError('Không thể tải danh sách nhà tuyển dụng. Hãy thử tải lại.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchEmployers();
  }, []);

  const filteredEmployers = useMemo(() => {
    const term = search.trim().toLocaleLowerCase();
    return employers.filter((employer) => {
      const matchesSearch =
        !term ||
        employer.companyName.toLocaleLowerCase().includes(term) ||
        employer.user.email.toLocaleLowerCase().includes(term) ||
        (employer.taxCode ?? '').toLocaleLowerCase().includes(term);
      return matchesSearch &&
        (statusFilter === 'ALL' || employer.verificationStatus === statusFilter);
    });
  }, [employers, search, statusFilter]);

  const handleApprove = async (id: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn duyệt nhà tuyển dụng này?')) return;
    try {
      setSaving(true);
      await employerService.approveEmployer(id);
      await fetchEmployers();
    } catch {
      setError('Không thể duyệt hồ sơ này.');
    } finally {
      setSaving(false);
    }
  };

  const handleReject = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!selectedEmployerId || !rejectReason.trim()) return;

    try {
      setSaving(true);
      await employerService.rejectEmployer(selectedEmployerId, rejectReason.trim());
      setSelectedEmployerId(null);
      setRejectReason('');
      await fetchEmployers();
    } catch {
      setError('Không thể từ chối hồ sơ này.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className="admin-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">ĐỐI TÁC</p>
          <h1>Nhà tuyển dụng</h1>
          <p className="page-description">Xem hồ sơ theo trạng thái và xử lý yêu cầu xác minh.</p>
        </div>
        <button className="button button-secondary" onClick={() => void fetchEmployers()} disabled={loading}>
          {loading ? 'Đang tải...' : 'Làm mới'}
        </button>
      </div>

      <div className="filter-bar">
        <input
          aria-label="Tìm nhà tuyển dụng"
          placeholder="Tìm tên công ty, email hoặc mã số thuế..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <select aria-label="Lọc xác minh" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="ALL">Tất cả trạng thái xác minh</option>
          {Object.entries(verificationLabels).map(([status, label]) => (
            <option key={status} value={status}>{label}</option>
          ))}
        </select>
        <span className="result-count">
          {loading && employers.length === 0 ? 'Đang tải...' : `${filteredEmployers.length} nhà tuyển dụng`}
        </span>
      </div>

      {error && <div className="state-message state-error" role="alert">{error}</div>}
      {loading && employers.length === 0 && <div className="state-message">Đang tải nhà tuyển dụng...</div>}

      {!loading && !error && filteredEmployers.length === 0 && (
        <div className="state-message">
          {employers.length === 0 ? 'Chưa có hồ sơ nhà tuyển dụng.' : 'Không tìm thấy hồ sơ phù hợp.'}
        </div>
      )}

      <div className="employer-grid">
        {filteredEmployers.map((employer) => (
          <article className="employer-card" key={employer.id}>
            <div className="employer-card-heading">
              <div>
                <h2>{employer.companyName}</h2>
                <p>{employer.user.email}</p>
              </div>
              <span className={`status-badge status-${employer.verificationStatus.toLowerCase()}`}>
                {verificationLabels[employer.verificationStatus]}
              </span>
            </div>
            <dl className="employer-details">
              <div><dt>Mã số thuế</dt><dd>{employer.taxCode || 'Chưa cập nhật'}</dd></div>
              <div><dt>Địa chỉ</dt><dd>{employer.address || 'Chưa cập nhật'}</dd></div>
              <div><dt>Ngày tạo</dt><dd>{new Date(employer.user.createdAt).toLocaleDateString('vi-VN')}</dd></div>
            </dl>
            {employer.rejectionReason && (
              <p className="rejection-reason"><strong>Lý do từ chối:</strong> {employer.rejectionReason}</p>
            )}
            {employer.verificationStatus === 'PENDING' && (
              <div className="card-actions">
                <button className="button button-success" disabled={saving} onClick={() => void handleApprove(employer.id)}>
                  Duyệt hồ sơ
                </button>
                <button className="button button-danger" disabled={saving} onClick={() => setSelectedEmployerId(employer.id)}>
                  Từ chối
                </button>
              </div>
            )}
          </article>
        ))}
      </div>

      {selectedEmployerId && (
        <div className="modal-backdrop" role="presentation">
          <form className="reject-modal" onSubmit={handleReject} role="dialog" aria-modal="true" aria-labelledby="reject-title">
            <h2 id="reject-title">Từ chối hồ sơ</h2>
            <p>Nhập lý do để nhà tuyển dụng biết cần bổ sung thông tin gì.</p>
            <textarea
              value={rejectReason}
              onChange={(event) => setRejectReason(event.target.value)}
              placeholder="Lý do từ chối..."
              required
              minLength={3}
              rows={4}
            />
            <div className="card-actions">
              <button type="button" className="button button-secondary" disabled={saving} onClick={() => setSelectedEmployerId(null)}>
                Hủy
              </button>
              <button type="submit" className="button button-danger" disabled={saving || !rejectReason.trim()}>
                {saving ? 'Đang lưu...' : 'Xác nhận từ chối'}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
};
