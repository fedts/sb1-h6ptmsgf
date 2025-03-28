-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated access" ON users;

-- Create simplified policies
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (role = 'client');

-- Create a single policy for all authenticated operations
CREATE POLICY "Allow authenticated access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Direct access to own data
    auth.uid() = uid
    OR
    -- Superadmin access (using auth metadata directly)
    (
      SELECT raw_user_meta_data->>'role' = 'superadmin'
      FROM auth.users
      WHERE id = auth.uid()
      LIMIT 1
    )
    OR
    -- Admin access to company users (using simple join)
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
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
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'admin'
      AND EXISTS (
        SELECT 1
        FROM users admin
        WHERE admin.uid = au.id
        AND admin.company_id = users.company_id
      )
      LIMIT 1
    )
  );