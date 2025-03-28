/*
  # Fix user creation order and dependencies

  1. Changes
    - Create auth.users entries first
    - Then create corresponding public.users entries
    - Add proper error handling and checks
    - Avoid foreign key violations

  2. Security
    - Maintain existing RLS policies
    - Keep user permissions intact
*/

-- First create users in auth.users
DO $$ 
BEGIN
  -- Create test users in auth.users if they don't exist
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test.superadmin@example.com') THEN
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
      'test.superadmin@example.com',
      crypt('Test123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Test Superadmin", "role": "superadmin"}',
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;

  -- Create test admin
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test.admin@techcorp.com') THEN
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
    (
      'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d',
      '00000000-0000-0000-0000-000000000000',
      'test.admin@techcorp.com',
      crypt('Admin123!', gen_salt('bf')),
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

  -- Create test client
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test.client@techcorp.com') THEN
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
    (
      'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f',
      '00000000-0000-0000-0000-000000000000',
      'test.client@techcorp.com',
      crypt('Client123!', gen_salt('bf')),
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

-- Create test company
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM companies WHERE id = '11111111-1111-1111-1111-111111111111') THEN
    INSERT INTO companies (id, name, phone, description)
    VALUES (
      '11111111-1111-1111-1111-111111111111',
      'TechCorp SpA',
      '+39 02 1234567',
      'Leading technology company'
    );
  END IF;
END $$;

-- Now create corresponding users in public.users
DO $$
BEGIN
  -- Create superadmin user
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = 'e9b93b23-c729-4f78-8c2c-ec9680e77b2c'
    AND NOT EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = 'e9b93b23-c729-4f78-8c2c-ec9680e77b2c'
    )
  ) THEN
    INSERT INTO public.users (
      id,
      uid,
      name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      'Test Superadmin',
      'test.superadmin@example.com',
      'superadmin',
      now(),
      now()
    );
  END IF;

  -- Create admin user
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d'
    AND NOT EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d'
    )
  ) THEN
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
      'test.admin@techcorp.com',
      'admin',
      '11111111-1111-1111-1111-111111111111',
      now(),
      now()
    );
  END IF;

  -- Create client user
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = 'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f'
    AND NOT EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = 'f7e6d5c4-b3a2-4f1e-9d8c-7b6a5c4d3e2f'
    )
  ) THEN
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
      'test.client@techcorp.com',
      'client',
      '11111111-1111-1111-1111-111111111111',
      now(),
      now()
    );
  END IF;
END $$;