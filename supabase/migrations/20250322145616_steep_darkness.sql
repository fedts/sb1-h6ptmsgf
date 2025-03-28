-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Allow authenticated access" ON users;

-- Create a simplified public registration policy
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (
    role = 'client'
    AND id = uid
  );

-- Create a non-recursive authenticated access policy
CREATE POLICY "Allow authenticated access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Simple direct checks without recursion
    auth.uid() = uid
    OR
    -- Superadmin check using auth metadata directly
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'superadmin'
      LIMIT 1
    )
    OR
    -- Admin check using auth metadata and direct company comparison
    EXISTS (
      SELECT 1
      FROM auth.users au
      JOIN users admin ON admin.uid = au.id
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  )
  WITH CHECK (
    -- Same conditions for write operations
    auth.uid() = uid
    OR
    EXISTS (
      SELECT 1
      FROM auth.users au
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'superadmin'
      LIMIT 1
    )
    OR
    EXISTS (
      SELECT 1
      FROM auth.users au
      JOIN users admin ON admin.uid = au.id
      WHERE au.id = auth.uid()
      AND au.raw_user_meta_data->>'role' = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  );

-- Update the auth trigger function to be more robust
CREATE OR REPLACE FUNCTION handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Create new user profile without recursive checks
    INSERT INTO public.users (
      id,
      uid,
      email,
      name,
      role,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.id,
      NEW.email,
      COALESCE(
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
      ),
      COALESCE(
        (NEW.raw_user_meta_data->>'role')::user_role,
        'client'::user_role
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Simple update without role changes
    UPDATE public.users
    SET
      email = NEW.email,
      name = COALESCE(
        NEW.raw_user_meta_data->>'name',
        users.name
      ),
      updated_at = NOW()
    WHERE id = NEW.id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
  END IF;
END;
$$;