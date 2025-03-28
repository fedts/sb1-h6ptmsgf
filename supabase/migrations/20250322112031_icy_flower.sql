/*
  # Fix RLS policies and add helper functions

  1. Changes
    - Add function to check user role from JWT
    - Drop existing policies
    - Re-create policies with correct JWT role checking
    - Ensure proper access for superadmin, admin, and regular users

  2. Security
    - Properly validate roles using JWT claims
    - Ensure correct company access based on user role
*/

-- Create a function to check user role
CREATE OR REPLACE FUNCTION public.get_jwt_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    (SELECT role::text FROM users WHERE uid = auth.uid()),
    'client'
  );
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "Superadmin full access to companies" ON companies;
DROP POLICY IF EXISTS "Admin can manage company" ON companies;
DROP POLICY IF EXISTS "Users can view own company" ON companies;
DROP POLICY IF EXISTS "Users can view their own company" ON companies;

-- Re-create policies with correct role checking
CREATE POLICY "Superadmin full access to companies"
ON companies
FOR ALL
TO authenticated
USING (get_jwt_role() = 'superadmin')
WITH CHECK (get_jwt_role() = 'superadmin');

CREATE POLICY "Admin can manage company"
ON companies
FOR ALL
TO authenticated
USING (
  get_jwt_role() = 'admin'
  AND id = (
    SELECT company_id 
    FROM users 
    WHERE uid = auth.uid()
  )
)
WITH CHECK (
  get_jwt_role() = 'admin'
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