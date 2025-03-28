/*
  # Add RLS policies for hazardous areas

  1. Security Changes
    - Enable RLS on hazardous_areas table
    - Add policies for:
      - Viewing hazardous areas (authenticated users can see their company's areas or all areas if superadmin)
      - Managing hazardous areas (only superadmin and company admins can manage)

  2. Notes
    - Uses get_user_role() and get_user_company() helper functions
    - Ensures proper access control based on user role and company
*/

-- Enable RLS
ALTER TABLE public.hazardous_areas ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow view hazardous areas" ON public.hazardous_areas;
DROP POLICY IF EXISTS "Allow manage hazardous areas" ON public.hazardous_areas;

-- Policy for viewing hazardous areas
CREATE POLICY "Allow view hazardous areas"
ON public.hazardous_areas
FOR SELECT
TO authenticated
USING (
  -- Superadmin can see all areas
  get_user_role() = 'superadmin'
  OR
  -- Admin and client can see their company's areas
  company_id = get_user_company()
);

-- Policy for managing hazardous areas (create, update, delete)
CREATE POLICY "Allow manage hazardous areas"
ON public.hazardous_areas
FOR ALL
TO authenticated
USING (
  -- Superadmin can manage all areas
  get_user_role() = 'superadmin'
  OR
  -- Admin can manage their company's areas
  (get_user_role() = 'admin' AND company_id = get_user_company())
)
WITH CHECK (
  get_user_role() = 'superadmin'
  OR
  (get_user_role() = 'admin' AND company_id = get_user_company())
);