import React from 'react';

export const Header: React.FC = () => {
  return (
    <header style={{ height: '70px', background: 'white', borderBottom: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 24px', position: 'sticky', top: 0, zIndex: 10 }}>
      <h3 style={{ fontSize: '18px', color: '#1E293B', fontWeight: 700 }}>Hệ thống quản trị JobLink</h3>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <span style={{ fontSize: '14px', color: '#64748B', fontWeight: 600 }}>Xin chào, Quản trị viên (Admin)</span>
      </div>
    </header>
  );
};