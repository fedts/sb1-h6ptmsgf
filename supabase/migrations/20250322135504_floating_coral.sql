/*
  # Fix RLS policies for virtual gates

  1. Changes
    - Drop existing policies
    - Create new policies for:
      - Superadmin: full access
      - Admin: manage company gates
      - Users: view company gates

  2. Security
    - Enable RLS
    - Ensure proper role-based access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Superadmin full access to virtual gates" ON virtual_gates;
DROP POLICY IF EXISTS "Admin can manage company virtual gates" ON virtual_gates;
DROP POLICY IF EXISTS "Users can view company virtual gates" ON virtual_gates;

-- Enable RLS
ALTER TABLE virtual_gates ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "Superadmin full access to virtual gates"
  ON virtual_gates
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

CREATE POLICY "Admin can manage company virtual gates"
  ON virtual_gates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = virtual_gates.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = virtual_gates.company_id
    )
  );

CREATE POLICY "Users can view company virtual gates"
  ON virtual_gates
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.company_id = virtual_gates.company_id
    )
  );