/*
  # Fix RLS policies for companies table

  1. Security Changes
    - Drop existing policies to ensure clean state
    - Re-create policies with correct permissions:
      - Superadmin: full access to all companies
      - Admin: can manage their own company
      - Users: can view their own company
*/

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Superadmin full access to companies" ON companies;
DROP POLICY IF EXISTS "Admin can manage company" ON companies;
DROP POLICY IF EXISTS "Users can view own company" ON companies;
DROP POLICY IF EXISTS "Users can view their own company" ON companies;

-- Re-create policies with correct permissions
CREATE POLICY "Superadmin full access to companies"
ON companies
FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'superadmin')
WITH CHECK (auth.jwt() ->> 'role' = 'superadmin');

CREATE POLICY "Admin can manage company"
ON companies
FOR ALL
TO authenticated
USING (
  auth.jwt() ->> 'role' = 'admin' 
  AND id = (
    SELECT company_id 
    FROM users 
    WHERE uid = auth.uid()
  )
)
WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
  AND id = (
    SELECT company_id 
    FROM users 
    WHERE uid = auth.uid()
  )
);

CREATE POLICY "Users can view own company"
ON companies
FOR SELECT
TO authenticated
USING (
  id = (
    SELECT company_id 
    FROM users 
    WHERE uid = auth.uid()
  )
);