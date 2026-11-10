import React from 'react';

export const Header: React.FC = () => {
  return (
    <header className="admin-header">
      <h2>Hệ thống quản trị JobLink</h2>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <span>Quản trị viên</span>
      </div>
    </header>
  );
};