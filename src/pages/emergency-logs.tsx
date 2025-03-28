import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { AlertTriangle, Download, MapPin } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

interface EmergencyLog {
  id: string;
  user_name: string;
  email: string;
  company: {
    name: string;
  } | null;
  current_location: string;
  address: string;
  timestamp: string;
  received: boolean;
}

export function EmergencyLogs() {
  const navigate = useNavigate();
  const [timeRange, setTimeRange] = useState('24h');

  // Fetch emergency logs
  const { data: logs, isLoading } = useQuery({
    queryKey: ['emergency-logs', timeRange],
    queryFn: async () => {
      let query = supabase
        .from('alerts')
        .select('*, company:companies(name)')
        .order('timestamp', { ascending: false });

      // Add time range filter
      const now = new Date();
      switch (timeRange) {
        case '24h':
          query = query.gte('timestamp', new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString());
          break;
        case '7d':
          query = query.gte('timestamp', new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString());
          break;
        case '30d':
          query = query.gte('timestamp', new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString());
          break;
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as EmergencyLog[];
    }
  });

  const handleViewLocation = (log: EmergencyLog) => {
    // Parse coordinates from the current_location string
    const [longitude, latitude] = log.current_location.split(' ').map(Number);
    
    if (isNaN(latitude) || isNaN(longitude)) {
      toast.error('Coordinate non valide');
      return;
    }

    // Navigate to dashboard with location data
    navigate('/', {
      state: {
        emergency: {
          id: log.id,
          userName: log.user_name,
          timestamp: log.timestamp,
          latitude,
          longitude
        }
      }
    });
  };

  if (isLoading) {
    return <div className="flex items-center justify-center">Caricamento...</div>;
  }

  // Separate active (not received) and past alerts
  const activeAlerts = logs?.filter(log => !log.received) || [];
  const pastAlerts = logs?.filter(log => log.received) || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Log Emergenze</h1>
        <div className="flex items-center gap-4">
          <label htmlFor="timeRange" className="text-sm font-medium text-gray-700">
            Periodo:
          </label>
          <select
            id="timeRange"
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500"
          >
            <option value="24h">Ultime 24 ore</option>
            <option value="7d">Ultimi 7 giorni</option>
            <option value="30d">Ultimi 30 giorni</option>
          </select>
        </div>
      </div>

      {/* Active Alerts Section */}
      {activeAlerts.length > 0 && (
        <div className="rounded-lg bg-red-50 p-4">
          <div className="mb-4 flex items-center">
            <AlertTriangle className="h-6 w-6 text-red-600" />
            <h2 className="ml-2 text-lg font-semibold text-red-900">
              Emergenze Attive ({activeAlerts.length})
            </h2>
          </div>
          <div className="overflow-hidden rounded-lg border border-red-200 bg-white">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-red-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-red-900">
                    Data e Ora
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-red-900">
                    Utente
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-red-900">
                    Azienda
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-red-900">
                    Posizione
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-red-900">
                    Azioni
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {activeAlerts.map((log) => (
                  <tr key={log.id} className="bg-red-50 bg-opacity-50">
                    <td className="whitespace-nowrap px-6 py-4 text-sm font-medium text-red-900">
                      {format(new Date(log.timestamp), 'dd/MM/yyyy HH:mm')}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-red-900">{log.user_name}</div>
                      <div className="text-sm text-red-700">{log.email}</div>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <div className="text-sm text-red-900">{log.company?.name || 'N/A'}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-red-900">{log.address}</div>
                      <div className="text-sm text-red-700">{log.current_location}</div>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right">
                      <button
                        onClick={() => handleViewLocation(log)}
                        className="inline-flex items-center rounded-md bg-red-100 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-200"
                      >
                        <MapPin className="mr-2 h-4 w-4" />
                        Vedi sulla mappa
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Past Alerts Section */}
      <div className="rounded-lg bg-white shadow">
        <div className="border-b border-gray-200 p-4">
          <h2 className="text-lg font-semibold text-gray-900">
            Storico Emergenze
          </h2>
        </div>
        <div className="overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                  Data e Ora
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                  Utente
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                  Azienda
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                  Posizione
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                  Azioni
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {pastAlerts.map((log) => (
                <tr key={log.id}>
                  <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                    {format(new Date(log.timestamp), 'dd/MM/yyyy HH:mm')}
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm font-medium text-gray-900">{log.user_name}</div>
                    <div className="text-sm text-gray-500">{log.email}</div>
                  </td>
                  <td className="whitespace-nowrap px-6 py-4">
                    <div className="text-sm text-gray-900">{log.company?.name || 'N/A'}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900">{log.address}</div>
                    <div className="text-sm text-gray-500">{log.current_location}</div>
                  </td>
                  <td className="whitespace-nowrap px-6 py-4 text-right">
                    <button
                      onClick={() => handleViewLocation(log)}
                      className="inline-flex items-center rounded-md bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200"
                    >
                      <MapPin className="mr-2 h-4 w-4" />
                      Vedi sulla mappa
                    </button>
                  </td>
                </tr>
              ))}
              {pastAlerts.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-4 text-center text-sm text-gray-500">
                    Nessuna emergenza registrata nel periodo selezionato
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}