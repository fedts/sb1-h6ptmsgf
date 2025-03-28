/*
  # Make user superadmin

  1. Changes
    - Update user role to superadmin in auth.users metadata
    - Update user role to superadmin in public.users profile
*/

-- Update auth.users metadata
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"superadmin"'
)
WHERE email = 'davide@davide.it';

-- Update public.users role
UPDATE public.users
SET role = 'superadmin'
WHERE email = 'davide@davide.it';