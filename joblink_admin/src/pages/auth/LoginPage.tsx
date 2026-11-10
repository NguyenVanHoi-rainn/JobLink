import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../../services/authService';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    localStorage.removeItem('admin_token');

    try {
      const data = await authService.login({ email, password });
      
      const token = data.accessToken || data.access_token || data.token;
      if (token) {
        const user = await authService.getCurrentAdmin(token);
        if (user.role !== 'ADMIN') {
          setError('Tài khoản không có quyền truy cập trang quản trị.');
          return;
        }

        localStorage.setItem('admin_token', token);
        navigate('/dashboard'); 
      } else {
        setError('Không nhận được token xác thực từ hệ thống.');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', backgroundColor: '#F5F7FB' }}>
      <form onSubmit={handleLogin} style={{ background: 'white', padding: '32px', borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', width: '360px' }}>
        <h2 style={{ marginBottom: '24px', textAlign: 'center', color: '#1E293B' }}>JobLink Admin</h2>

        {error && <div style={{ color: 'red', marginBottom: '16px', fontSize: '14px' }}>{error}</div>}

        <div style={{ marginBottom: '16px' }}>
          <label style={{ display: 'block', marginBottom: '6px', fontSize: '14px', fontWeight: 600 }}>Email quản trị</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1' }}
            placeholder="admin@joblink.com"
          />
        </div>

        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', marginBottom: '6px', fontSize: '14px', fontWeight: 600 }}>Mật khẩu</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1' }}
            placeholder="••••••••"
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{ width: '100%', padding: '12px', background: '#2563EB', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}
        >
          {loading ? 'Đang đăng nhập...' : 'Đăng nhập'}
        </button>
      </form>
    </div>
  );
};

export default LoginPage;