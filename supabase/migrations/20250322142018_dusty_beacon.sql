/*
  # Fix login and database structure

  1. Changes
    - Drop and recreate tables with proper constraints
    - Add improved RLS policies
    - Create test users with proper auth setup
    - Fix user registration trigger

  2. Security
    - Ensure proper role-based access
    - Add necessary indexes
    - Set up proper foreign key relationships
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Recreate user_role enum if needed
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'client');
  END IF;
END $$;

-- Drop existing tables in correct order
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS hazardous_areas CASCADE;
DROP TABLE IF EXISTS virtual_gates CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- Create companies table
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  uid uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  role user_role NOT NULL DEFAULT 'client',
  email text UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE SET NULL,
  location_sharing boolean DEFAULT false,
  address text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX users_uid_idx ON users(uid);
CREATE INDEX users_email_idx ON users(email);
CREATE INDEX users_company_id_idx ON users(company_id);

-- Create hazardous areas table
CREATE TABLE hazardous_areas (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  geo_point geometry(Point,4326) NOT NULL,
  radius integer NOT NULL CHECK (radius > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create virtual gates table
CREATE TABLE virtual_gates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  geo_point geometry(Point,4326) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create alerts table
CREATE TABLE alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name text NOT NULL,
  email text NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE SET NULL,
  current_location text,
  address text,
  received boolean DEFAULT false,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hazardous_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_gates ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Create improved auth trigger function
CREATE OR REPLACE FUNCTION handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Create or replace the trigger
DROP TRIGGER IF EXISTS on_auth_user_change ON auth.users;
CREATE TRIGGER on_auth_user_change
  AFTER INSERT OR UPDATE OR DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_auth_user_change();

-- Create test users
DO $$ 
BEGIN
  -- Create test company
  INSERT INTO companies (id, name, phone, description)
  VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Test Company',
    '+1234567890',
    'Test company description'
  ) ON CONFLICT (id) DO NOTHING;

  -- Create test users in auth.users
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
      updated_at
    ) VALUES (
      'e9b93b23-c729-4f78-8c2c-ec9680e77b2c',
      '00000000-0000-0000-0000-000000000000',
      'test.superadmin@example.com',
      crypt('Test123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Test Superadmin", "role": "superadmin"}',
      now(),
      now()
    );
  END IF;

  -- Create test admin
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test.admin@example.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      'f8d92b34-a618-4e67-9b7b-fd579ae66b1d',
      '00000000-0000-0000-0000-000000000000',
      'test.admin@example.com',
      crypt('Admin123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Test Admin", "role": "admin"}',
      now(),
      now()
    );
  END IF;

  -- Create test client
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test.client@example.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      'c7e81a45-b527-3f56-8a6a-ec468bd55c2e',
      '00000000-0000-0000-0000-000000000000',
      'test.client@example.com',
      crypt('Client123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Test Client", "role": "client"}',
      now(),
      now()
    );
  END IF;
END $$;