/*
  # Fix RLS policies to prevent infinite recursion

  1. Changes
    - Simplify RLS policies for users table
    - Remove circular dependencies in policy checks
    - Add direct role checks without recursion
    
  2. Security
    - Maintain proper access control
    - Ensure data integrity
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Authenticated user access" ON users;

-- Create simplified policies
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    role = 'client'
    AND id = uid -- Ensure id matches uid for new registrations
  );

CREATE POLICY "Allow select access"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    -- Direct access to own data
    uid = auth.uid()
    OR
    -- Superadmin access (using direct subquery)
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'superadmin'
    )
    OR
    -- Admin access to company users (using direct subquery)
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
    )
  );

CREATE POLICY "Allow update access"
  ON users
  FOR UPDATE
  TO authenticated
  USING (
    -- Can update own data
    uid = auth.uid()
    OR
    -- Superadmin can update any user
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'superadmin'
    )
    OR
    -- Admin can update company users
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
    )
  )
  WITH CHECK (
    -- Same conditions for write operations
    uid = auth.uid()
    OR
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'superadmin'
    )
    OR
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
    )
  );

CREATE POLICY "Allow delete access"
  ON users
  FOR DELETE
  TO authenticated
  USING (
    -- Can delete own data
    uid = auth.uid()
    OR
    -- Superadmin can delete any user
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'superadmin'
    )
    OR
    -- Admin can delete company users
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND (au.raw_user_meta_data->>'role')::text = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
    )
  );