import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Shield } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

export function LoginPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'email' ? value.toLowerCase().trim() : value
    }));
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Sign in with Supabase Auth
      const { data: authData, error: signInError } = await supabase.auth.signInWithPassword({
        email: formData.email,
        password: formData.password
      });

      if (signInError) {
        console.error('Sign in error:', signInError);
        if (signInError.message.includes('Invalid login credentials')) {
          toast.error('Email o password non validi');
        } else {
          toast.error('Errore durante il login');
        }
        return;
      }

      if (!authData.user) {
        toast.error('Utente non trovato');
        return;
      }

      // Get user profile
      const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('*, company:companies(*)')
        .eq('uid', authData.user.id)
        .single();

      if (profileError) {
        console.error('Profile fetch error:', profileError);
        if (profileError.code === 'PGRST116') {
          // Profile doesn't exist, create it
          const { error: insertError } = await supabase
            .from('users')
            .insert([{
              id: authData.user.id,
              uid: authData.user.id,
              email: authData.user.email,
              name: authData.user.user_metadata.name || authData.user.email?.split('@')[0] || 'User',
              role: authData.user.user_metadata.role || 'client'
            }]);

          if (insertError) {
            console.error('Error creating user profile:', insertError);
            toast.error('Errore durante la creazione del profilo utente');
            return;
          }
        } else {
          toast.error('Errore durante il recupero del profilo utente');
          return;
        }
      }

      toast.success('Login effettuato con successo');
      navigate('/', { replace: true });
    } catch (error) {
      console.error('Login error:', error);
      toast.error('Errore durante il login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100 p-4">
      <div className="w-full max-w-md">
        <div className="rounded-lg bg-white p-8 shadow-lg">
          <div className="mb-8 text-center">
            <Shield className="mx-auto h-12 w-12 text-blue-600" />
            <h2 className="mt-4 text-2xl font-bold text-gray-900">
              Vigilant Dashboard
            </h2>
            <p className="mt-2 text-sm text-gray-600">
              Sicurezza sul lavoro con Wear OS
            </p>
          </div>
          
          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label
                htmlFor="email"
                className="block text-sm font-medium text-gray-700"
              >
                Email
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={formData.email}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500"
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-700"
              >
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                minLength={6}
                value={formData.password}
                onChange={handleChange}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
            >
              {loading ? 'Accesso in corso...' : 'Accedi'}
            </button>
          </form>

          <p className="mt-4 text-center text-sm text-gray-600">
            Non hai un account?{' '}
            <Link to="/register" className="font-medium text-blue-600 hover:text-blue-500">
              Registrati
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}