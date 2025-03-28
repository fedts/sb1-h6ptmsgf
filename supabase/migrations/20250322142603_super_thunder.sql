/*
  # Fix RLS policies recursion

  1. Changes
    - Drop existing policies that cause recursion
    - Create simplified policies with direct checks
    - Update helper functions to avoid recursion
    - Fix user registration flow

  2. Security
    - Maintain proper role-based access
    - Keep existing security model
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Superadmin access" ON users;
DROP POLICY IF EXISTS "Admin access" ON users;
DROP POLICY IF EXISTS "Self access" ON users;

-- Create simplified policies without recursion
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (role = 'client');

CREATE POLICY "Authenticated user access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Direct access to own data
    uid = auth.uid()
    OR
    -- Superadmin access
    (
      SELECT role = 'superadmin'
      FROM users
      WHERE uid = auth.uid()
      LIMIT 1
    )
    OR
    -- Admin access to company users
    (
      SELECT TRUE
      FROM users admin
      WHERE admin.uid = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  )
  WITH CHECK (
    -- Can only modify own data unless superadmin/admin
    uid = auth.uid()
    OR
    (
      SELECT role = 'superadmin'
      FROM users
      WHERE uid = auth.uid()
      LIMIT 1
    )
    OR
    (
      SELECT TRUE
      FROM users admin
      WHERE admin.uid = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  );

-- Update helper functions to avoid recursion
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
  LIMIT 1;
$$;

-- Update auth trigger function
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