import { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface AuthContextType {
  user: User | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initAuth = async () => {
      try {
        // Check active session
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError) {
          console.error('Session error:', sessionError);
          throw sessionError;
        }

        if (session?.user) {
          // Get user profile to ensure it exists
          const { data: profile, error: profileError } = await supabase
            .from('users')
            .select('*')
            .eq('uid', session.user.id)
            .single();

          if (profileError && profileError.code === 'PGRST116') {
            // Profile doesn't exist, create it
            const { error: insertError } = await supabase
              .from('users')
              .insert([{
                id: session.user.id,
                uid: session.user.id,
                email: session.user.email,
                name: session.user.user_metadata.name || session.user.email?.split('@')[0] || 'User',
                role: session.user.user_metadata.role || 'client'
              }]);

            if (insertError) {
              console.error('Error creating user profile:', insertError);
              throw insertError;
            }
          } else if (profileError) {
            console.error('Error fetching user profile:', profileError);
            throw profileError;
          }
        }

        setUser(session?.user ?? null);
        setLoading(false);

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
          setUser(session?.user ?? null);
          setLoading(false);
        });

        return () => {
          subscription.unsubscribe();
        };
      } catch (error) {
        console.error('Auth initialization error:', error);
        toast.error('Errore di autenticazione. Effettua nuovamente il login.');
        await supabase.auth.signOut();
        setUser(null);
        setLoading(false);
      }
    };

    initAuth();
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  return useContext(AuthContext);
};