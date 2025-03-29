import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/sidebar';
import { GlobalAlertMonitorProvider, useGlobalAlertMonitor } from '../contexts/global-alert-context';

export function DashboardLayout() {

  useGlobalAlertMonitor();

  return (
    <GlobalAlertMonitorProvider>
      <div className="flex h-screen bg-gray-100">
        <Sidebar />
        <main className="flex-1 overflow-auto p-8">
          <Outlet />
        </main>
      </div>
    </GlobalAlertMonitorProvider>
  );
}
