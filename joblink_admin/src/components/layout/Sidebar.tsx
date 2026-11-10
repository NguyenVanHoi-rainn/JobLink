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
    <aside className="admin-sidebar">
      <div className="sidebar-brand">
        JobLink Admin
      </div>

      <nav className="sidebar-nav">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={`sidebar-link${isActive ? ' sidebar-link-active' : ''}`}
              title={item.label.replace(/^[^ ]+ /, '')}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <button
          className="button button-danger"
          title="Đăng xuất"
          onClick={() => {
            localStorage.removeItem('admin_token');
            window.location.href = '/login';
          }}
        >
          Đăng xuất
        </button>
      </div>
    </aside>
  );
};