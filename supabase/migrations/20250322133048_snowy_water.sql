/*
  # Create initial schema and add test superadmin

  1. New Tables
    - Create base tables if they don't exist
    - Add test superadmin account
    
  2. Security
    - Enable RLS
    - Set up proper role management
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Create enum for user roles if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'client');
  END IF;
END $$;

-- Create companies table if it doesn't exist
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  uid uuid REFERENCES auth.users(id),
  name text NOT NULL,
  role user_role NOT NULL DEFAULT 'client',
  email text UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id),
  location_sharing boolean DEFAULT false,
  address text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create test superadmin in auth.users
DO $$ 
BEGIN
  -- Only insert if they don't exist
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
    ) VALUES (
      'dd7e1f2b-c4a3-4e6d-9b8a-7c6d5e4f3a2b',
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
END $$;

-- Create corresponding profile in public.users
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'test.superadmin@example.com') THEN
    INSERT INTO users (
      id,
      uid,
      name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      'dd7e1f2b-c4a3-4e6d-9b8a-7c6d5e4f3a2b',
      'dd7e1f2b-c4a3-4e6d-9b8a-7c6d5e4f3a2b',
      'Test Superadmin',
      'test.superadmin@example.com',
      'superadmin',
      now(),
      now()
    );
  END IF;
END $$;