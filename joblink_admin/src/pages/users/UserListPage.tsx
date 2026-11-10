import React, { useEffect, useMemo, useState } from 'react';
import { userService } from '../../services/userService';
import { User } from '../../types/user';

export const UserListPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [updatingUserId, setUpdatingUserId] = useState<string | null>(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      setUsers(await userService.getUsers());
    } catch {
      setError('Không thể tải danh sách người dùng. Hãy thử tải lại.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchUsers();
  }, []);

  const filteredUsers = useMemo(() => {
    const term = search.trim().toLocaleLowerCase();
    return users.filter((user) => {
      return (
        (!term || user.email.toLocaleLowerCase().includes(term)) &&
        (roleFilter === 'ALL' || user.role === roleFilter) &&
        (statusFilter === 'ALL' || user.status === statusFilter)
      );
    });
  }, [users, search, roleFilter, statusFilter]);

  const handleToggleLock = async (user: User) => {
    const isLocked = user.status === 'LOCKED';
    const actionName = isLocked ? 'mở khóa' : 'khóa';
    if (!window.confirm(`Bạn có chắc chắn muốn ${actionName} tài khoản ${user.email}?`)) return;

    try {
      setUpdatingUserId(user.id);
      if (isLocked) {
        await userService.unlockUser(user.id);
      } else {
        await userService.lockUser(user.id);
      }
      await fetchUsers();
    } catch {
      setError(`Không thể ${actionName} tài khoản này.`);
    } finally {
      setUpdatingUserId(null);
    }
  };

  return (
    <section className="admin-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">TÀI KHOẢN</p>
          <h1>Quản lý người dùng</h1>
          <p className="page-description">Tìm kiếm, lọc và quản lý trạng thái tài khoản.</p>
        </div>
        <button className="button button-secondary" onClick={() => void fetchUsers()} disabled={loading}>
          {loading ? 'Đang tải...' : 'Làm mới'}
        </button>
      </div>

      <div className="filter-bar">
        <input
          aria-label="Tìm email"
          placeholder="Tìm theo email..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <select aria-label="Lọc vai trò" value={roleFilter} onChange={(event) => setRoleFilter(event.target.value)}>
          <option value="ALL">Tất cả vai trò</option>
          <option value="WORKER">Worker</option>
          <option value="EMPLOYER">Employer</option>
          <option value="ADMIN">Admin</option>
        </select>
        <select aria-label="Lọc trạng thái" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="ALL">Tất cả trạng thái</option>
          <option value="ACTIVE">Hoạt động</option>
          <option value="LOCKED">Đã khóa</option>
        </select>
        <span className="result-count">
          {loading && users.length === 0 ? 'Đang tải...' : `${filteredUsers.length} tài khoản`}
        </span>
      </div>

      {error && <div className="state-message state-error" role="alert">{error}</div>}
      {loading && users.length === 0 && <div className="state-message">Đang tải danh sách người dùng...</div>}

      {!loading && !error && filteredUsers.length === 0 && (
        <div className="state-message">
          {users.length === 0 ? 'Chưa có tài khoản người dùng.' : 'Không tìm thấy người dùng phù hợp.'}
        </div>
      )}

      {filteredUsers.length > 0 && (
        <div className="table-card">
          <div className="table-scroll">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Email</th>
                  <th>Vai trò</th>
                  <th>Trạng thái</th>
                  <th>Ngày tạo</th>
                  <th>Hành động</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((user) => {
                  const isLocked = user.status === 'LOCKED';
                  return (
                    <tr key={user.id}>
                      <td className="cell-primary">{user.email}</td>
                      <td>{user.role}</td>
                      <td>
                        <span className={`status-badge ${isLocked ? 'status-danger' : 'status-success'}`}>
                          {isLocked ? 'Đã khóa' : 'Hoạt động'}
                        </span>
                      </td>
                      <td>{new Date(user.createdAt).toLocaleDateString('vi-VN')}</td>
                      <td>
                        {user.role !== 'ADMIN' && (
                          <button
                            className={`button ${isLocked ? 'button-success' : 'button-danger'}`}
                            disabled={updatingUserId === user.id}
                            onClick={() => void handleToggleLock(user)}
                          >
                            {updatingUserId === user.id ? 'Đang cập nhật...' : isLocked ? 'Mở khóa' : 'Khóa'}
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
      )}
    </section>
  );
};
