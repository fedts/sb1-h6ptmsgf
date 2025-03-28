/*
  # Add Row Level Security policies for alerts table

  1. Changes
    - Enable RLS on alerts table
    - Add policies for different user roles
    - Allow users to create their own alerts
    - Allow admins to view company alerts
    - Allow superadmins full access

  2. Security
    - Ensure users can only create alerts for themselves
    - Admins can view alerts for their company
    - Superadmins have full access
*/

-- Enable RLS on alerts table if not already enabled
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can create own alerts" ON alerts;
DROP POLICY IF EXISTS "Users can view own alerts" ON alerts;
DROP POLICY IF EXISTS "Admin can view company alerts" ON alerts;
DROP POLICY IF EXISTS "Superadmin full access to alerts" ON alerts;

-- Create policy for users to create their own alerts
CREATE POLICY "Users can create own alerts"
ON alerts
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- Create policy for users to view their own alerts
CREATE POLICY "Users can view own alerts"
ON alerts
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- Create policy for admins to view company alerts
CREATE POLICY "Admin can view company alerts"
ON alerts
FOR ALL
TO authenticated
USING (
  (SELECT role FROM users WHERE uid = auth.uid()) = 'admin'
  AND company_id = (SELECT company_id FROM users WHERE uid = auth.uid())
)
WITH CHECK (
  (SELECT role FROM users WHERE uid = auth.uid()) = 'admin'
  AND company_id = (SELECT company_id FROM users WHERE uid = auth.uid())
);

-- Create policy for superadmins to have full access
CREATE POLICY "Superadmin full access to alerts"
ON alerts
FOR ALL
TO authenticated
USING (
  (SELECT role FROM users WHERE uid = auth.uid()) = 'superadmin'
)
WITH CHECK (
  (SELECT role FROM users WHERE uid = auth.uid()) = 'superadmin'
);