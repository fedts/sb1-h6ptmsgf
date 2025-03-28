/*
  # Fix companies table RLS policies

  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new policies with proper access rules:
      - Superadmin: full access to all companies
      - Admin: can view and manage their own company
      - Users: can view their own company
      - Public: no access

  2. Security
    - Maintain RLS enabled
    - Ensure proper role-based access control
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Superadmin full access to companies" ON companies;
DROP POLICY IF EXISTS "Users can view own company" ON companies;
DROP POLICY IF EXISTS "Admin can view own company" ON companies;
DROP POLICY IF EXISTS "Admin can manage company" ON companies;

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Superadmin full access to all companies
CREATE POLICY "Superadmin full access to companies"
  ON companies
  FOR ALL
  TO authenticated
  USING (get_user_role() = 'superadmin'::user_role)
  WITH CHECK (get_user_role() = 'superadmin'::user_role);

-- Admin can manage their own company
CREATE POLICY "Admin can manage company"
  ON companies
  FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'admin'::user_role AND 
    id = get_user_company()
  )
  WITH CHECK (
    get_user_role() = 'admin'::user_role AND 
    id = get_user_company()
  );

-- All authenticated users can view their own company
CREATE POLICY "Users can view own company"
  ON companies
  FOR SELECT
  TO authenticated
  USING (id = get_user_company());