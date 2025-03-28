/*
  # Fix user registration RLS policy

  1. Changes
    - Add new RLS policy to allow user registration
    - Modify existing policies to handle registration flow

  2. Security
    - Allow unauthenticated users to insert into users table during registration
    - Maintain existing security policies for other operations
*/

-- Add policy to allow user registration
CREATE POLICY "Allow user registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    -- Only allow setting role to 'client' during registration
    role = 'client'::user_role
  );

-- Update existing policies to be more specific about their operations
DROP POLICY IF EXISTS "Superadmin full access to users" ON users;
DROP POLICY IF EXISTS "Admin can manage company users" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;

CREATE POLICY "Superadmin full access to users"
  ON users
  FOR ALL
  TO authenticated
  USING (get_user_role() = 'superadmin'::user_role)
  WITH CHECK (get_user_role() = 'superadmin'::user_role);

CREATE POLICY "Admin can manage company users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'admin'::user_role 
    AND company_id = get_user_company()
  )
  WITH CHECK (
    get_user_role() = 'admin'::user_role 
    AND company_id = get_user_company()
  );

CREATE POLICY "Users can view own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());