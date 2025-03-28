import { supabase } from './supabase';
import toast from 'react-hot-toast';

export async function testSupabaseConnection() {
  try {
    console.log('Testing Supabase connection...');

    // Test basic connection first
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('Auth system error:', sessionError);
      throw new Error('Cannot access Supabase auth system');
    }

    console.log('Auth system check passed');

    // Test database access
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('count')
      .limit(1);

    if (usersError) {
      console.error('Database error:', usersError);
      throw new Error('Cannot connect to Supabase database');
    }

    console.log('Database check passed');

    // Test RLS policies
    if (session?.user) {
      const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('*')
        .eq('uid', session.user.id)
        .single();

      if (profileError) {
        console.error('RLS policy error:', profileError);
        throw new Error('RLS policies may be misconfigured');
      }

      console.log('RLS check passed');
      console.log('Current user:', profile?.email);
    }

    toast.success('Supabase connection successful');
    return true;
  } catch (error) {
    console.error('Supabase connection test failed:', error);
    if (error instanceof Error) {
      toast.error(`Connection error: ${error.message}`);
    } else {
      toast.error('Failed to connect to Supabase');
    }
    return false;
  }
}