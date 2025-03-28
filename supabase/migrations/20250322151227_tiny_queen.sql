/*
  # Disable RLS on users table

  1. Changes
    - Disable Row Level Security on users table
    - Keep existing data and structure intact
    - Maintain all other security measures

  2. Security
    - Authentication is still required through Supabase Auth
    - Database-level permissions still apply
    - Other tables maintain their RLS policies
*/

-- Disable RLS on users table
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;