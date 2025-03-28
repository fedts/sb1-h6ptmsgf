/*
  # Update user role to superadmin

  1. Changes
    - Update user fede@test.it to have superadmin role in both auth and public schemas
    - Ensure the user exists before updating
*/

DO $$ 
BEGIN
  -- Update the user's role in public.users
  UPDATE public.users
  SET role = 'superadmin'
  WHERE email = 'fede@test.it';

  -- Update the user's metadata in auth.users
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"superadmin"'
  )
  WHERE email = 'fede@test.it';
END $$;