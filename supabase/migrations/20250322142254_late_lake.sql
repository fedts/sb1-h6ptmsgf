/*
  # Fix RLS policies and user registration

  1. Changes
    - Drop and recreate RLS policies with proper checks
    - Fix user registration flow
    - Add policies for public access during registration
    - Update trigger function to handle user creation properly

  2. Security
    - Maintain proper role-based access
    - Allow public registration while maintaining security
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Superadmin full access" ON users;
DROP POLICY IF EXISTS "Admin manage company users" ON users;
DROP POLICY IF EXISTS "Users view own data" ON users;
DROP POLICY IF EXISTS "Allow registration" ON users;

-- Create new policies for users table
CREATE POLICY "Allow public registration"
  ON users
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Users can view and update own data"
  ON users
  FOR ALL
  TO authenticated
  USING (
    auth.uid() = uid
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'superadmin'
    )
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'admin'
      AND u.company_id = users.company_id
    )
  )
  WITH CHECK (
    auth.uid() = uid
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'superadmin'
    )
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'admin'
      AND u.company_id = users.company_id
    )
  );

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
    ON CONFLICT (id) DO UPDATE
    SET
      email = EXCLUDED.email,
      name = EXCLUDED.name,
      role = CASE 
        WHEN users.role = 'client' THEN EXCLUDED.role
        ELSE users.role
      END,
      updated_at = NOW()
    WHERE users.role = 'client';
    
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
      role = CASE 
        WHEN users.role = 'client' THEN default_role
        ELSE users.role
      END,
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

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_change ON auth.users;
CREATE TRIGGER on_auth_user_change
  AFTER INSERT OR UPDATE OR DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_auth_user_change();

-- Add helper function to check user role
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

-- Add helper function to check user company
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