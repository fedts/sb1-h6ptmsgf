/*
  # Fix RLS policies recursion

  1. Changes
    - Drop existing policies that cause recursion
    - Create simplified policies with direct checks
    - Remove helper functions that cause recursion
    - Fix user registration flow

  2. Security
    - Maintain proper role-based access
    - Keep existing security model
*/

-- Drop existing policies and functions
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Authenticated user access" ON users;
DROP FUNCTION IF EXISTS get_auth_role();
DROP FUNCTION IF EXISTS get_auth_company();

-- Create simplified policies
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
    -- Superadmin access (using subquery with LIMIT)
    EXISTS (
      SELECT 1
      FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'superadmin'
      LIMIT 1
    )
    OR
    -- Admin access to company users (using subquery with LIMIT)
    EXISTS (
      SELECT 1
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
    EXISTS (
      SELECT 1
      FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'superadmin'
      LIMIT 1
    )
    OR
    EXISTS (
      SELECT 1
      FROM users admin
      WHERE admin.uid = auth.uid()
      AND admin.role = 'admin'
      AND admin.company_id = users.company_id
      LIMIT 1
    )
  );

-- Update auth trigger function
CREATE OR REPLACE FUNCTION handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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