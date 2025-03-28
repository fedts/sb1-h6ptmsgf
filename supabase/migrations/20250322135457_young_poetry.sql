/*
  # Fix RLS policies for hazardous areas

  1. Changes
    - Drop existing policies
    - Create new policies for:
      - Superadmin: full access
      - Admin: manage company areas
      - Users: view company areas

  2. Security
    - Enable RLS
    - Ensure proper role-based access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Superadmin full access to hazardous areas" ON hazardous_areas;
DROP POLICY IF EXISTS "Admin can manage company hazardous areas" ON hazardous_areas;
DROP POLICY IF EXISTS "Users can view company hazardous areas" ON hazardous_areas;

-- Enable RLS
ALTER TABLE hazardous_areas ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "Superadmin full access to hazardous areas"
  ON hazardous_areas
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

CREATE POLICY "Admin can manage company hazardous areas"
  ON hazardous_areas
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = hazardous_areas.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
      AND users.company_id = hazardous_areas.company_id
    )
  );

CREATE POLICY "Users can view company hazardous areas"
  ON hazardous_areas
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.company_id = hazardous_areas.company_id
    )
  );