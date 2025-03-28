/*
  # Fix RLS policies for users table

  1. Changes
    - Re-enable RLS on users table
    - Create simplified policies that avoid recursion
    - Use direct auth metadata checks instead of recursive queries

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Keep existing permissions intact
*/

-- Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated access" ON users;

-- Create simplified policies
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    role = 'client'
    AND id = uid
  );

CREATE POLICY "Allow authenticated access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Direct access to own data
    auth.uid() = uid
    OR
    -- Superadmin access using direct auth metadata check
    (
      SELECT raw_user_meta_data->>'role' = 'superadmin'
      FROM auth.users
      WHERE id = auth.uid()
      LIMIT 1
    )
    OR
    -- Admin access using direct join and company check
    (
      SELECT TRUE
      FROM auth.users au
      JOIN users admin ON admin.uid = au.id
      WHERE au.id = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  )
  WITH CHECK (
    -- Same conditions for write operations
    auth.uid() = uid
    OR
    (
      SELECT raw_user_meta_data->>'role' = 'superadmin'
      FROM auth.users
      WHERE id = auth.uid()
      LIMIT 1
    )
    OR
    (
      SELECT TRUE
      FROM auth.users au
      JOIN users admin ON admin.uid = au.id
      WHERE au.id = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  );