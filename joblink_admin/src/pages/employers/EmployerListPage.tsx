import React, { useEffect, useState } from 'react';
import { employerService } from '../../services/employerService';
import { EmployerVerification } from '../../types/employer';

export const EmployerListPage: React.FC = () => {
  const [employers, setEmployers] = useState<EmployerVerification[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  
  const [selectedEmployerId, setSelectedEmployerId] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState<string>('');

  const fetchPendingEmployers = async () => {
    try {
      setLoading(true);
      const data = await employerService.getPendingVerifications();
      setEmployers(data);
    } catch (err: any) {
      setError('Không thể tải danh sách hồ sơ xác minh nhà tuyển dụng.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingEmployers();
  }, []);

  const handleApprove = async (id: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn duyệt nhà tuyển dụng này?')) return;
    try {
      await employerService.approveEmployer(id);
      fetchPendingEmployers(); 
    } catch (err: any) {
      alert(err.response?.data?.message || 'Không thể duyệt hồ sơ này.');
    }
  };

  const handleReject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedEmployerId || !rejectReason.trim()) return;

    try {
      await employerService.rejectEmployer(selectedEmployerId, rejectReason);
      setSelectedEmployerId(null);
      setRejectReason('');
      fetchPendingEmployers();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Không thể từ chối hồ sơ này.');
    }
  };

  if (loading) {
    return <div style={{ padding: '24px', textAlign: 'center' }}>Đang tải danh sách chờ xác minh...</div>;
  }

  if (error) {
    return <div style={{ padding: '24px', color: 'red', textAlign: 'center' }}>{error}</div>;
  }

  return (
    <div style={{ padding: '24px', backgroundColor: '#F5F7FB', minHeight: '100vh' }}>
      <h2 style={{ marginBottom: '24px', color: '#1E293B', fontWeight: 800 }}>Xác minh Nhà tuyển dụng</h2>

      {employers.length === 0 ? (
        <div style={{ background: 'white', padding: '32px', textAlign: 'center', borderRadius: '12px', color: '#64748B' }}>
          Hiện không có hồ sơ nhà tuyển dụng nào cần xác minh.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {employers.map((emp) => (
            <div key={emp.id} style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ fontSize: '18px', color: '#1E293B', marginBottom: '6px' }}>{emp.companyName}</h3>
                <p style={{ fontSize: '14px', color: '#64748B', marginBottom: '4px' }}>Email liên hệ: <strong>{emp.user.email}</strong></p>
                <p style={{ fontSize: '14px', color: '#64748B', marginBottom: '4px' }}>Mã số thuế: {emp.taxCode || 'Chưa cập nhật'}</p>
                <p style={{ fontSize: '14px', color: '#64748B' }}>Địa chỉ: {emp.address || 'Chưa cập nhật'}</p>
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  onClick={() => handleApprove(emp.id)}
                  style={{ padding: '10px 16px', background: '#16A34A', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}
                >
                  Duyệt
                </button>
                <button
                  onClick={() => setSelectedEmployerId(emp.id)}
                  style={{ padding: '10px 16px', background: '#DC2626', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}
                >
                  Từ chối
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal nhập lý do từ chối */}
      {selectedEmployerId && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <form onSubmit={handleReject} style={{ background: 'white', padding: '24px', borderRadius: '12px', width: '400px' }}>
            <h3 style={{ marginBottom: '16px' }}>Lý do từ chối hồ sơ</h3>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Nhập lý do từ chối để gửi cho nhà tuyển dụng..."
              required
              style={{ width: '100%', height: '100px', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', marginBottom: '16px' }}
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setSelectedEmployerId(null)}
                style={{ padding: '8px 14px', background: '#CBD5E1', border: 'none', borderRadius: '6px', cursor: 'pointer' }}
              >
                Hủy
              </button>
              <button
                type="submit"
                style={{ padding: '8px 14px', background: '#DC2626', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer' }}
              >
                Xác nhận từ chối
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};