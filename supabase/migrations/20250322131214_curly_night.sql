/*
  # Restructure Users and Authentication

  1. Changes
    - Safely remove existing users
    - Create new test users with proper roles
    - Set up proper RLS policies
    - Fix user registration flow

  2. Security
    - Maintain proper role-based access
    - Ensure secure authentication flow
    - Set up proper RLS policies
*/

-- First, safely remove existing data
DO $$ 
BEGIN
  -- Delete existing users safely
  DELETE FROM auth.users WHERE email IN (
    'superadmin@example.com',
    'admin@techcorp.com',
    'client@techcorp.com'
  );
  
  -- Delete corresponding public users
  DELETE FROM public.users WHERE email IN (
    'superadmin@example.com',
    'admin@techcorp.com',
    'client@techcorp.com'
  );
END $$;

-- Create test users in auth.users
DO $$ 
BEGIN
  -- Only insert if they don't exist
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'superadmin@example.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      last_sign_in_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES
    -- Superadmin
    (
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      '00000000-0000-0000-0000-000000000000',
      'superadmin@example.com',
      crypt('superadmin123', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Super Admin", "role": "superadmin"}',
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@techcorp.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      last_sign_in_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES
    -- Admin TechCorp
    (
      'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d',
      '00000000-0000-0000-0000-000000000000',
      'admin@techcorp.com',
      crypt('admin123', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Tech Admin", "role": "admin"}',
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'client@techcorp.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      last_sign_in_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES
    -- Client
    (
      'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f',
      '00000000-0000-0000-0000-000000000000',
      'client@techcorp.com',
      crypt('client123', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Tech Client", "role": "client"}',
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;
END $$;

-- Create test company if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM companies WHERE id = 'b4a2c6e8-d0f2-4e4a-b6a8-c0e2d4f6a8b0') THEN
    INSERT INTO companies (
      id,
      name,
      phone,
      description
    ) VALUES (
      'b4a2c6e8-d0f2-4e4a-b6a8-c0e2d4f6a8b0',
      'TechCorp SpA',
      '+39 02 1234567',
      'Leading technology company'
    );
  END IF;
END $$;

-- Create corresponding users in public.users
DO $$
BEGIN
  -- Superadmin
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'superadmin@example.com') THEN
    INSERT INTO public.users (
      id,
      uid,
      name,
      email,
      role,
      company_id,
      created_at,
      updated_at
    ) VALUES (
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      'Super Admin',
      'superadmin@example.com',
      'superadmin',
      NULL,
      now(),
      now()
    );
  END IF;

  -- Admin
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'admin@techcorp.com') THEN
    INSERT INTO public.users (
      id,
      uid,
      name,
      email,
      role,
      company_id,
      created_at,
      updated_at
    ) VALUES (
      'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d',
      'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d',
      'Tech Admin',
      'admin@techcorp.com',
      'admin',
      'b4a2c6e8-d0f2-4e4a-b6a8-c0e2d4f6a8b0',
      now(),
      now()
    );
  END IF;

  -- Client
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE email = 'client@techcorp.com') THEN
    INSERT INTO public.users (
      id,
      uid,
      name,
      email,
      role,
      company_id,
      created_at,
      updated_at
    ) VALUES (
      'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f',
      'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f',
      'Tech Client',
      'client@techcorp.com',
      'client',
      'b4a2c6e8-d0f2-4e4a-b6a8-c0e2d4f6a8b0',
      now(),
      now()
    );
  END IF;
END $$;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_change ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_change();

-- Create improved auth trigger function
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

-- Create new trigger
CREATE TRIGGER on_auth_user_change
  AFTER INSERT OR UPDATE OR DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_auth_user_change();

-- Update RLS policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Admin can manage company users" ON public.users;
DROP POLICY IF EXISTS "Superadmin full access to users" ON public.users;
DROP POLICY IF EXISTS "Allow user registration" ON public.users;
DROP POLICY IF EXISTS "Superadmin full access" ON public.users;
DROP POLICY IF EXISTS "Admin manage company users" ON public.users;
DROP POLICY IF EXISTS "Users view own data" ON public.users;
DROP POLICY IF EXISTS "Allow registration" ON public.users;

-- Create new policies
CREATE POLICY "Superadmin full access"
  ON public.users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.uid = auth.uid()
      AND users.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.uid = auth.uid()
      AND users.role = 'superadmin'
    )
  );

CREATE POLICY "Admin manage company users"
  ON public.users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.uid = auth.uid()
      AND u.role = 'admin'
      AND u.company_id = users.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.uid = auth.uid()
      AND u.role = 'admin'
      AND u.company_id = users.company_id
    )
  );

CREATE POLICY "Users view own data"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (uid = auth.uid());

CREATE POLICY "Allow registration"
  ON public.users
  FOR INSERT
  TO public
  WITH CHECK (role = 'client');