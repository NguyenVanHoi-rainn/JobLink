import React from 'react';
import { Link } from 'react-router-dom';

export const NotFoundPage: React.FC = () => {
  return (
    <div style={{ textAlign: 'center', padding: '80px 20px', background: '#F5F7FB', minHeight: '100vh' }}>
      <h1 style={{ fontSize: '64px', color: '#1E293B', marginBottom: '16px' }}>404</h1>
      <p style={{ fontSize: '18px', color: '#64748B', marginBottom: '24px' }}>Trang bạn tìm kiếm không tồn tại.</p>
      <Link to="/dashboard" style={{ padding: '10px 20px', background: '#2563EB', color: 'white', borderRadius: '8px', textDecoration: 'none', fontWeight: 600 }}>
        Quay lại Dashboard
      </Link>
    </div>
  );
};