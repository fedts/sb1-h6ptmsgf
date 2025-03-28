import { supabase } from './supabase';

export async function signIn(email: string, password: string) {
  try {
    // First, check if the user exists
    const { data: existingUser, error: userError } = await supabase
      .from('users')
      .select('id, email, role')
      .eq('email', email.toLowerCase())
      .single();

    if (userError && userError.code === 'PGRST116') {
      throw new Error('User not found');
    }

    if (userError) {
      console.error('Error checking user:', userError);
      throw new Error('Error during authentication');
    }

    // Attempt to sign in
    const { data: authData, error: signInError } = await supabase.auth.signInWithPassword({
      email: email.toLowerCase(),
      password
    });

    if (signInError) {
      console.error('Sign in error:', signInError);
      throw signInError;
    }

    if (!authData.user) {
      throw new Error('No user data returned');
    }

    // Get complete user profile
    const { data: profile, error: profileError } = await supabase
      .from('users')
      .select('*, company:companies(*)')
      .eq('uid', authData.user.id)
      .single();

    if (profileError) {
      console.error('Profile fetch error:', profileError);
      throw new Error('Error fetching user profile');
    }

    // Update session with user metadata
    await supabase.auth.updateUser({
      data: {
        role: profile.role,
        name: profile.name,
        company_id: profile.company_id
      }
    });

    return { user: authData.user, profile };
  } catch (error) {
    console.error('Authentication error:', error);
    throw error;
  }
}