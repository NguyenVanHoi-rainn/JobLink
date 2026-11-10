import React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export const AdminLayout: React.FC = () => {
  return (
    <div className="admin-shell">
      <Sidebar />

      <div className="admin-main">
        <Header />
        <main style={{ flex: 1 }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
};