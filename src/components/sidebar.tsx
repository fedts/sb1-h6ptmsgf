import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, Building2, AlertTriangle, Heater as Gate, AlertOctagon, LogOut } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/auth';
import toast from 'react-hot-toast';

const navigation = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Utenti', href: '/users', icon: Users },
  { name: 'Aziende', href: '/companies', icon: Building2, adminOnly: true },
  { name: 'Aree Pericolose', href: '/hazardous-areas', icon: AlertTriangle },
  { name: 'Virtual Gates', href: '/virtual-gates', icon: Gate },
  { name: 'Log Emergenze', href: '/emergency-logs', icon: AlertOctagon }
];

export function Sidebar() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      // Clear any local state/storage if needed
      localStorage.removeItem('supabase.auth.token');
      
      // Show success message
      toast.success('Logout effettuato con successo');
      
      // Redirect to login page
      navigate('/login', { replace: true });
    } catch (error) {
      console.error('Logout error:', error);
      toast.error('Errore durante il logout');
    }
  };

  return (
    <div className="w-64 bg-white shadow-lg">
      <div className="flex h-16 items-center justify-center border-b">
        <h1 className="text-xl font-bold text-gray-900">Vigilant Dashboard</h1>
      </div>
      <nav className="flex flex-1 flex-col">
        <ul className="space-y-1 p-4">
          {navigation.map((item) => (
            <li key={item.name}>
              <NavLink
                to={item.href}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors
                  ${isActive 
                    ? 'bg-blue-50 text-blue-600' 
                    : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                  }`
                }
              >
                <item.icon className="h-5 w-5" />
                {item.name}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
      <div className="border-t p-4">
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:text-gray-900"
        >
          <LogOut className="h-5 w-5" />
          Logout
        </button>
      </div>
    </div>
  );
}