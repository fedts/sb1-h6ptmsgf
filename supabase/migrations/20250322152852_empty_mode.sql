/*
  # Update user role to superadmin

  1. Changes
    - Updates the role of fedts@hotmail.it to superadmin in both auth.users and public.users tables
*/

-- Update auth.users metadata
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"superadmin"'
)
WHERE email = 'fedts@hotmail.it';

-- Update public.users role
UPDATE public.users
SET role = 'superadmin'
WHERE email = 'fedts@hotmail.it';