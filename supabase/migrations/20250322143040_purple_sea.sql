/*
  # Fix RLS policies recursion

  1. Changes
    - Drop existing policies
    - Create simplified policies without helper functions
    - Fix user registration and authentication flow

  2. Security
    - Maintain proper role-based access
    - Keep existing security model
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

CREATE POLICY "Authenticated user access"
  ON users
  FOR ALL
  TO authenticated
  USING (
    -- Direct access to own data
    auth.uid() = uid
    OR
    -- Superadmin access (using EXISTS with LIMIT)
    EXISTS (
      SELECT 1
      FROM users u
      WHERE u.uid = auth.uid()
      AND u.role = 'superadmin'
      LIMIT 1
    )
    OR
    -- Admin access to company users (using EXISTS with LIMIT)
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
    -- Same conditions for write operations
    auth.uid() = uid
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
    ON CONFLICT (id) DO UPDATE
    SET
      email = EXCLUDED.email,
      name = EXCLUDED.name,
      role = CASE 
        WHEN users.role = 'client' THEN EXCLUDED.role
        ELSE users.role
      END,
      updated_at = NOW();
    
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

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_change ON auth.users;
CREATE TRIGGER on_auth_user_change
  AFTER INSERT OR UPDATE OR DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_auth_user_change();