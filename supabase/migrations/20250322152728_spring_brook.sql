/*
  # Fix Companies Table RLS

  1. Security Changes
    - Enable RLS on companies table
    - Add policies for:
      - Superadmin: full access
      - Admin: view own company
      - Client: view own company
*/

-- Enable RLS
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow view companies" ON public.companies;
DROP POLICY IF EXISTS "Allow manage companies" ON public.companies;

-- Policy for viewing companies
CREATE POLICY "Allow view companies"
ON public.companies
FOR SELECT
TO authenticated
USING (
  -- Superadmin can see all companies
  get_user_role() = 'superadmin'
  OR
  -- Users can see their own company
  id = get_user_company()
);

-- Policy for managing companies (superadmin only)
CREATE POLICY "Allow manage companies"
ON public.companies
FOR ALL
TO authenticated
USING (
  get_user_role() = 'superadmin'
)
WITH CHECK (
  get_user_role() = 'superadmin'
);