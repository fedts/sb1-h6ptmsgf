/*
  # Initial Schema for Workplace Safety Dashboard

  1. New Tables
    - `companies`: Store company information
    - `hazardous_areas`: Store dangerous zones with PostGIS geometry
    - `alerts`: Store emergency alerts
    - `locations`: Store real-time user locations with PostGIS geometry
    - `requests`: Store location requests
    - `users`: Store user information
    - `fcm_tokens`: Store FCM tokens for push notifications

  2. Security
    - Enable RLS on all tables
    - Add policies for different user roles
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Create enum for user roles
CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'client');

-- Companies table
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text,
  description text,
  hazardous_areas jsonb DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Users table (created before functions that depend on it)
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  uid uuid REFERENCES auth.users(id),
  name text NOT NULL,
  role user_role NOT NULL DEFAULT 'client',
  email text UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id),
  location_sharing boolean DEFAULT false,
  fcm_token text,
  last_location text,
  address text,
  activated_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Helper function to get current user's role (after users table exists)
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT (role)::user_role
  FROM users
  WHERE uid = auth.uid();
$$;

-- Helper function to get current user's company
CREATE OR REPLACE FUNCTION get_user_company()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT company_id::uuid
  FROM users
  WHERE uid = auth.uid();
$$;

-- Hazardous areas table
CREATE TABLE hazardous_areas (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  geo_point geometry(Point, 4326) NOT NULL,
  radius integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Alerts table
CREATE TABLE alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  user_name text NOT NULL,
  email text NOT NULL,
  company_id uuid REFERENCES companies(id),
  fcm_token text,
  received boolean DEFAULT false,
  timestamp timestamptz DEFAULT now(),
  current_location text,
  address text,
  activated_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now()
);

-- Locations table
CREATE TABLE locations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  activated_by uuid REFERENCES users(id),
  fcm_token text,
  geo_point geometry(Point, 4326) NOT NULL,
  last_location text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Requests table
CREATE TABLE requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  location_id uuid REFERENCES locations(id),
  title text NOT NULL,
  body text,
  user_name text NOT NULL,
  user_email text NOT NULL,
  user_address text,
  user_last_location text,
  company_id uuid REFERENCES companies(id),
  admin_role user_role NOT NULL,
  admin_name text NOT NULL,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- FCM tokens table
CREATE TABLE fcm_tokens (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  fcm_token text NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  user_email text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE hazardous_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Companies policies
CREATE POLICY "Superadmin full access to companies"
  ON companies
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Users can view their own company"
  ON companies
  FOR SELECT
  TO authenticated
  USING (id = get_user_company());

-- Hazardous areas policies
CREATE POLICY "Superadmin full access to hazardous areas"
  ON hazardous_areas
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Admin can manage company hazardous areas"
  ON hazardous_areas
  TO authenticated
  USING (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  )
  WITH CHECK (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  );

-- Users policies
CREATE POLICY "Superadmin full access to users"
  ON users
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Admin can manage company users"
  ON users
  TO authenticated
  USING (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  )
  WITH CHECK (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  );

CREATE POLICY "Users can view own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Alerts policies
CREATE POLICY "Superadmin full access to alerts"
  ON alerts
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Admin can view company alerts"
  ON alerts
  FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  );

CREATE POLICY "Users can view own alerts"
  ON alerts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Locations policies
CREATE POLICY "Superadmin full access to locations"
  ON locations
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Admin can view company locations"
  ON locations
  FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'admin' 
    AND user_id IN (
      SELECT id 
      FROM users 
      WHERE company_id = get_user_company()
    )
  );

CREATE POLICY "Users can manage own location"
  ON locations
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Requests policies
CREATE POLICY "Superadmin full access to requests"
  ON requests
  TO authenticated
  USING (get_user_role() = 'superadmin')
  WITH CHECK (get_user_role() = 'superadmin');

CREATE POLICY "Admin can manage company requests"
  ON requests
  TO authenticated
  USING (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  )
  WITH CHECK (
    get_user_role() = 'admin' 
    AND company_id = get_user_company()
  );

-- FCM tokens policies
CREATE POLICY "Users can manage own FCM tokens"
  ON fcm_tokens
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create test superadmin user
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'superadmin@test.com',
  crypt('superadmin123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now()
);

INSERT INTO users (
  uid,
  name,
  role,
  email
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'Super Admin',
  'superadmin',
  'superadmin@test.com'
);