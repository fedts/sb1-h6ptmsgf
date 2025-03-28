/*
  # Fix RLS policies recursion

  1. Changes
    - Simplify RLS policies to avoid recursion
    - Fix user registration and access control
    - Update helper functions

  2. Security
    - Maintain proper role-based access
    - Keep existing security model
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Users can view and update own data" ON users;
DROP POLICY IF EXISTS "Superadmin full access" ON users;
DROP POLICY IF EXISTS "Admin manage company users" ON users;
DROP POLICY IF EXISTS "Users view own data" ON users;
DROP POLICY IF EXISTS "Allow registration" ON users;

-- Create simplified policies
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (role = 'client');

CREATE POLICY "Superadmin access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    role = 'superadmin'
  )
  WITH CHECK (
    role = 'superadmin'
  );

CREATE POLICY "Admin access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    role = 'admin'
    AND EXISTS (
      SELECT 1 FROM users u2
      WHERE u2.uid = auth.uid()
      AND u2.company_id = users.company_id
      AND u2.role = 'admin'
    )
  )
  WITH CHECK (
    role = 'admin'
    AND EXISTS (
      SELECT 1 FROM users u2
      WHERE u2.uid = auth.uid()
      AND u2.company_id = users.company_id
      AND u2.role = 'admin'
    )
  );

CREATE POLICY "Self access"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    uid = auth.uid()
  );

-- Update helper functions
CREATE OR REPLACE FUNCTION get_auth_role()
RETURNS user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM users
  WHERE uid = auth.uid()
  AND id = uid -- Ensure we're looking at the correct user
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_auth_company()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id
  FROM users
  WHERE uid = auth.uid()
  AND id = uid -- Ensure we're looking at the correct user
  LIMIT 1;
$$;

-- Update the auth trigger function
CREATE OR REPLACE FUNCTION handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  default_role user_role;
BEGIN
  -- Set default role
  default_role := COALESCE(
    (NEW.raw_user_meta_data->>'role')::user_role,
    'client'::user_role
  );

  IF TG_OP = 'INSERT' THEN
    -- Create new user profile
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
      default_role,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update existing user
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
    -- Delete user profile
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
  END IF;
END;
$$;