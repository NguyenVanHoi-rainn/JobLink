import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import axios from 'axios';
import { authService } from '../services/authService';

export const ProtectedRoute: React.FC = () => {
  const token = localStorage.getItem('admin_token');
  const [authorized, setAuthorized] = React.useState(false);
  const [checking, setChecking] = React.useState(true);
  const [verificationFailed, setVerificationFailed] = React.useState(false);

  React.useEffect(() => {
    if (!token) {
      setChecking(false);
      return;
    }

    let active = true;

    authService
      .getCurrentAdmin()
      .then((user) => {
        if (!active) {
          return;
        }

        if (user.role !== 'ADMIN') {
          localStorage.removeItem('admin_token');
          return;
        }

        setAuthorized(true);
      })
      .catch((error: unknown) => {
        if (!active) {
          return;
        }

        if (
          axios.isAxiosError(error) &&
          (error.response?.status === 401 || error.response?.status === 403)
        ) {
          localStorage.removeItem('admin_token');
          return;
        }

        setVerificationFailed(true);
      })
      .finally(() => {
        if (active) {
          setChecking(false);
        }
      });

    return () => {
      active = false;
    };
  }, [token]);

  if (!token || (!checking && !authorized && !verificationFailed)) {
    return <Navigate to="/login" replace />;
  }

  if (checking) {
    return <p>Đang xác minh quyền truy cập...</p>;
  }

  if (verificationFailed) {
    return (
      <div role="alert">
        <p>Không thể xác minh quyền truy cập. Vui lòng thử lại.</p>
        <button onClick={() => window.location.reload()}>Thử lại</button>
      </div>
    );
  }

  return authorized ? <Outlet /> : <Navigate to="/login" replace />;
};