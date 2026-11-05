import React from 'react';
import { Link, useLocation } from 'react-router-dom';

export const Sidebar: React.FC = () => {
  const location = useLocation();

  const menuItems = [
    { path: '/dashboard', label: '📊 Dashboard' },
    { path: '/employers', label: '🏢 Xác minh NTD' },
    { path: '/users', label: '👥 Quản lý User' },
    { path: '/jobs', label: '📝 Quản lý Tin tuyển dụng' },
  ];

  return (
    <div style={{ width: '260px', background: '#1E293B', color: 'white', display: 'flex', flexDirection: 'column', height: '100vh', position: 'fixed', left: 0, top: 0 }}>
      <div style={{ padding: '24px', fontSize: '20px', fontWeight: 800, borderBottom: '1px solid #334155' }}>
        JobLink Admin
      </div>

      <nav style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 }}>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              style={{
                padding: '12px 16px',
                borderRadius: '8px',
                color: isActive ? 'white' : '#94A3B8',
                background: isActive ? '#2563EB' : 'transparent',
                textDecoration: 'none',
                fontWeight: 600,
                transition: 'all 0.2s',
              }}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div style={{ padding: '16px', borderTop: '1px solid #334155' }}>
        <button
          onClick={() => {
            localStorage.removeItem('admin_token');
            window.location.href = '/login';
          }}
          style={{ width: '100%', padding: '10px', background: '#DC2626', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}
        >
          Đăng xuất
        </button>
      </div>
    </div>
  );
};