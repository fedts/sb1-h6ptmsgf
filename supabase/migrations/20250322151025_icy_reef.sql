-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated access" ON users;
DROP POLICY IF EXISTS "Allow select access" ON users;
DROP POLICY IF EXISTS "Allow update access" ON users;

-- Create simplified policies without recursion
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    role = 'client'
    AND id = uid
  );

-- Create a single policy for authenticated access
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