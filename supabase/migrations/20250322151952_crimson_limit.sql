/*
  # Add RLS policies for alerts table
  
  1. Changes
    - Enable RLS on alerts table
    - Create policies for CRUD operations on alerts
    
  2. Security
    - Allow users to create their own alerts
    - Allow admins and superadmins to view alerts for their company
    - Maintain proper access control based on user roles
*/

-- Enable RLS
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow insert own alerts" ON public.alerts;
DROP POLICY IF EXISTS "Allow view alerts" ON public.alerts;
DROP POLICY IF EXISTS "Allow update alerts" ON public.alerts;

-- Policy for inserting alerts (users can create their own alerts)
CREATE POLICY "Allow insert own alerts"
ON public.alerts
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- Policy for viewing alerts (users can see their own, admins see company's, superadmin sees all)
CREATE POLICY "Allow view alerts"
ON public.alerts
FOR SELECT
TO authenticated
USING (
  -- Users can see their own alerts
  auth.uid() = user_id
  OR
  -- Superadmin can see all alerts
  get_user_role() = 'superadmin'
  OR
  -- Admins can see alerts from their company
  (get_user_role() = 'admin' AND company_id = get_user_company())
);

-- Policy for updating alerts (same rules as viewing)
CREATE POLICY "Allow update alerts"
ON public.alerts
FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id
  OR
  get_user_role() = 'superadmin'
  OR
  (get_user_role() = 'admin' AND company_id = get_user_company())
)
WITH CHECK (
  auth.uid() = user_id
  OR
  get_user_role() = 'superadmin'
  OR
  (get_user_role() = 'admin' AND company_id = get_user_company())
);