import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/sidebar';

export function DashboardLayout() {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <main className="flex-1 overflow-auto p-8">
        <Outlet />
      </main>
    </div>
  );
}