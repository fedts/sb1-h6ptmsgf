/*
  # Fix RLS policies for users table

  1. Changes
    - Drop existing policies
    - Create new simplified policies without recursion
    - Use auth metadata for role checks
    - Use direct joins for company access

  2. Security
    - Maintain same access control rules
    - Prevent infinite recursion
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated access" ON users;
DROP POLICY IF EXISTS "Allow select access" ON users;
DROP POLICY IF EXISTS "Allow update access" ON users;

-- Create new simplified policies
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (role = 'client');

CREATE POLICY "Allow authenticated access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Direct access to own data
    auth.uid() = uid
    OR
    -- Superadmin access (using auth metadata)
    (
      SELECT (raw_user_meta_data->>'role')::text = 'superadmin'
      FROM auth.users
      WHERE id = auth.uid()
      LIMIT 1
    )
    OR
    -- Admin access to company users (using direct join)
    EXISTS (
      SELECT 1
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
      SELECT (raw_user_meta_data->>'role')::text = 'superadmin'
      FROM auth.users
      WHERE id = auth.uid()
      LIMIT 1
    )
    OR
    EXISTS (
      SELECT 1
      FROM auth.users au
      JOIN users admin ON admin.uid = au.id
      WHERE au.id = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  );