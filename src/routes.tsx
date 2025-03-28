import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './contexts/auth';
import { LoginPage } from './pages/login';
import { RegisterPage } from './pages/register';
import { DashboardLayout } from './layouts/dashboard';
import { Dashboard } from './pages/dashboard';
import { Users } from './pages/users';
import { Companies } from './pages/companies';
import { HazardousAreas } from './pages/hazardous-areas';
import { VirtualGates } from './pages/virtual-gates';
import { EmergencyLogs } from './pages/emergency-logs';

export function AppRoutes() {
  const { user, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!user) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <Routes>
      <Route path="/" element={<DashboardLayout />}>
        <Route index element={<Dashboard />} />
        <Route path="users" element={<Users />} />
        <Route path="companies" element={<Companies />} />
        <Route path="hazardous-areas" element={<HazardousAreas />} />
        <Route path="virtual-gates" element={<VirtualGates />} />
        <Route path="emergency-logs" element={<EmergencyLogs />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}