/*
  # Add RLS policies for virtual gates

  1. Security Changes
    - Enable RLS on virtual_gates table
    - Add policies for:
      - Viewing virtual gates (authenticated users can see their company's gates or all gates if superadmin)
      - Managing virtual gates (only superadmin and company admins can manage)

  2. Notes
    - Uses get_user_role() and get_user_company() helper functions
    - Ensures proper access control based on user role and company
*/

-- Enable RLS
ALTER TABLE public.virtual_gates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow view virtual gates" ON public.virtual_gates;
DROP POLICY IF EXISTS "Allow manage virtual gates" ON public.virtual_gates;

-- Policy for viewing virtual gates
CREATE POLICY "Allow view virtual gates"
ON public.virtual_gates
FOR SELECT
TO authenticated
USING (
  -- Superadmin can see all gates
  get_user_role() = 'superadmin'
  OR
  -- Admin and client can see their company's gates
  company_id = get_user_company()
);

-- Policy for managing virtual gates (create, update, delete)
CREATE POLICY "Allow manage virtual gates"
ON public.virtual_gates
FOR ALL
TO authenticated
USING (
  -- Superadmin can manage all gates
  get_user_role() = 'superadmin'
  OR
  -- Admin can manage their company's gates
  (get_user_role() = 'admin' AND company_id = get_user_company())
)
WITH CHECK (
  get_user_role() = 'superadmin'
  OR
  (get_user_role() = 'admin' AND company_id = get_user_company())
);