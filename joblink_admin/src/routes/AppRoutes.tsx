import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { LoginPage } from '../pages/auth/LoginPage';
import { DashboardPage } from '../pages/dashboard/DashboardPage';
import { EmployerListPage } from '../pages/employers/EmployerListPage';
import { ProtectedRoute } from './ProtectedRoute';
import { AdminLayout } from '../components/layout/AdminLayout';
import { UserListPage } from '../pages/users/UserListPage';
import { JobListPage } from '../pages/jobs/JobListPage';
import { NotFoundPage } from '../pages/not-found/NotFoundPage';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route path="/" element={<Navigate to="/dashboard" replace />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/employers" element={<EmployerListPage />} />
          <Route path="/users" element={<UserListPage />} />
          <Route path="/jobs" element={<JobListPage />} />
        </Route>
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};