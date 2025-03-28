/*
  # Fix RLS policies with helper functions
  
  1. Changes
    - Re-enable RLS on users table
    - Create helper functions for role and company_id
    - Create clean RLS policy without self-referencing
    
  2. Security
    - Use JWT claims directly for role checks
    - Avoid querying users table in policies
    - Maintain proper access control
*/

-- ✅ STEP 1: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ✅ STEP 2: Drop old policy if needed
DROP POLICY IF EXISTS "Allow authenticated access" ON public.users;

-- ✅ STEP 3: Create helper function to extract role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text
LANGUAGE sql STABLE
AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'role',
    'client'
  )
$$;

-- ✅ STEP 4: Create helper to extract company_id
CREATE OR REPLACE FUNCTION get_user_company()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
  SELECT (
    current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'company_id'
  )::uuid
$$;

-- ✅ STEP 5: Create clean RLS policy (NO reference to users table inside!)
CREATE POLICY "Allow authenticated access"
ON public.users
FOR ALL
TO authenticated
USING (
  -- Access own data
  auth.uid() = uid
  OR
  -- Superadmin can access all
  get_user_role() = 'superadmin'
  OR
  -- Admin can access users from same company
  get_user_role() = 'admin' AND company_id = get_user_company()
)
WITH CHECK (
  auth.uid() = uid
  OR
  get_user_role() = 'superadmin'
  OR
  (get_user_role() = 'admin' AND company_id = get_user_company())
);