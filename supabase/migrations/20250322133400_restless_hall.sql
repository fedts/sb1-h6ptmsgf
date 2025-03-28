/*
  # Fix alerts table and policies

  1. Changes
    - Create alerts table if it doesn't exist
    - Update RLS policies for alerts
    - Fix column types and constraints

  2. Security
    - Enable RLS
    - Add proper policies for all user roles
*/

-- Create alerts table if it doesn't exist
CREATE TABLE IF NOT EXISTS alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  user_name text NOT NULL,
  email text NOT NULL,
  company_id uuid REFERENCES companies(id),
  current_location text,
  address text,
  received boolean DEFAULT false,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create own alerts" ON alerts;
DROP POLICY IF EXISTS "Users can view own alerts" ON alerts;
DROP POLICY IF EXISTS "Admin can view company alerts" ON alerts;
DROP POLICY IF EXISTS "Superadmin full access to alerts" ON alerts;
DROP POLICY IF EXISTS "Users can manage own alerts" ON alerts;

-- Create new policies
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
  WITH CHECK (true);

CREATE POLICY "Admin can manage company alerts"
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
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.id = alerts.user_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.id = alerts.user_id
    )
  );