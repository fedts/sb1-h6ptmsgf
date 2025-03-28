/*
  # Fix authentication and RLS policies

  1. Changes
    - Update auth trigger function to properly handle user creation
    - Fix RLS policies for alerts table
    - Ensure proper role handling during registration

  2. Security
    - Maintain existing security model
    - Fix permission issues for alert creation
*/

-- Update the auth trigger function to be more robust
CREATE OR REPLACE FUNCTION handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  default_role user_role;
BEGIN
  -- Set default role for new users
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
      role = EXCLUDED.role,
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
      role = CASE 
        WHEN users.role = 'client' THEN default_role
        ELSE users.role -- Keep existing role for non-client users
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

-- Drop existing alerts policies
DROP POLICY IF EXISTS "Users can create own alerts" ON alerts;
DROP POLICY IF EXISTS "Users can view own alerts" ON alerts;
DROP POLICY IF EXISTS "Admin can view company alerts" ON alerts;
DROP POLICY IF EXISTS "Superadmin full access to alerts" ON alerts;

-- Create new alerts policies
CREATE POLICY "Superadmin full access to alerts"
  ON alerts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'superadmin'
    )
  );

CREATE POLICY "Admin can view company alerts"
  ON alerts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = alerts.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = alerts.company_id
    )
  );

CREATE POLICY "Users can manage own alerts"
  ON alerts
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE id = alerts.user_id
    )
  )
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users WHERE id = alerts.user_id
    )
  );

-- Ensure RLS is enabled
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;