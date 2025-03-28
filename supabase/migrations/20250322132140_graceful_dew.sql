/*
  # Fix RLS policies for alerts table

  1. Changes
    - Drop existing policies
    - Create new policies that properly handle superadmin access
    - Allow superadmin to manage all alerts
    - Maintain existing policies for other roles

  2. Security
    - Ensure proper access control
    - Keep existing security model intact
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create own alerts" ON alerts;
DROP POLICY IF EXISTS "Users can view own alerts" ON alerts;
DROP POLICY IF EXISTS "Admin can view company alerts" ON alerts;
DROP POLICY IF EXISTS "Superadmin full access to alerts" ON alerts;

-- Create new policies
CREATE POLICY "Superadmin full access to alerts"
  ON alerts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
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
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = alerts.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = alerts.company_id
    )
  );

CREATE POLICY "Users can create own alerts"
  ON alerts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'superadmin'
    )
  );

CREATE POLICY "Users can view own alerts"
  ON alerts
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'superadmin'
    )
  );