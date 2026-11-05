import React, { useEffect, useState } from 'react';
import api from '../../services/api';
import { userService } from '../../services/userService';
import { User } from '../../types/user';

export const UserListPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await api.get('/admin/users'); 
      setUsers(response.data.items || response.data);
    } catch (err: any) {
      setError('Không thể tải danh sách người dùng.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleToggleLock = async (user: User) => {
    const isLocked = user.status === 'LOCKED';
    const actionName = isLocked ? 'mở khóa' : 'khóa';

    if (!window.confirm(`Bạn có chắc chắn muốn ${actionName} tài khoản ${user.email}?`)) {
      return;
    }

    try {
      if (isLocked) {
        await userService.unlockUser(user.id);
      } else {
        await userService.lockUser(user.id);
      }
      fetchUsers(); 
    } catch (err: any) {
      alert(err.response?.data?.message || `Không thể ${actionName} tài khoản này.`);
    }
  };

  if (loading) {
    return <div style={{ padding: '24px', textAlign: 'center' }}>Đang tải danh sách người dùng...</div>;
  }

  if (error) {
    return <div style={{ padding: '24px', color: 'red', textAlign: 'center' }}>{error}</div>;
  }

  return (
    <div style={{ padding: '24px', backgroundColor: '#F5F7FB', minHeight: '100vh' }}>
      <h2 style={{ marginBottom: '24px', color: '#1E293B', fontWeight: 800 }}>Quản lý Người dùng</h2>

      <div style={{ background: 'white', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#64748B', fontSize: '14px' }}>
              <th style={{ padding: '16px' }}>Email</th>
              <th style={{ padding: '16px' }}>Vai trò (Role)</th>
              <th style={{ padding: '16px' }}>Trạng thái</th>
              <th style={{ padding: '16px' }}>Ngày tạo</th>
              <th style={{ padding: '16px', textAlign: 'center' }}>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => {
              const isLocked = user.status === 'LOCKED';
              return (
                <tr key={user.id} style={{ borderBottom: '1px solid #F1F5F9', fontSize: '14px', color: '#334155' }}>
                  <td style={{ padding: '16px', fontWeight: 600 }}>{user.email}</td>
                  <td style={{ padding: '16px' }}>{user.role}</td>
                  <td style={{ padding: '16px' }}>
                    <span style={{
                      padding: '4px 10px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: 600,
                      background: isLocked ? '#FEE2E2' : '#DCFCE7',
                      color: isLocked ? '#DC2626' : '#16A34A',
                    }}>
                      {user.status}
                    </span>
                  </td>
                  <td style={{ padding: '16px' }}>{new Date(user.createdAt).toLocaleDateString()}</td>
                  <td style={{ padding: '16px', textAlign: 'center' }}>
                    {user.role !== 'ADMIN' && (
                      <button
                        onClick={() => handleToggleLock(user)}
                        style={{
                          padding: '6px 12px',
                          background: isLocked ? '#16A34A' : '#DC2626',
                          color: 'white',
                          border: 'none',
                          borderRadius: '6px',
                          fontWeight: 600,
                          cursor: 'pointer',
                        }}
                      >
                        {isLocked ? 'Mở khóa' : 'Khóa'}
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};