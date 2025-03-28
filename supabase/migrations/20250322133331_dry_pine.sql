/*
  # Update user to superadmin role

  1. Changes
    - Update user with email 'fedts@hotmail.it' to superadmin role
    - Update both auth.users metadata and public.users role
*/

DO $$ 
BEGIN
  -- Update the user's role in public.users
  UPDATE public.users
  SET 
    role = 'superadmin',
    updated_at = NOW()
  WHERE email = 'fedts@hotmail.it';

  -- Update the user's metadata in auth.users
  UPDATE auth.users
  SET 
    raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb),
      '{role}',
      '"superadmin"'
    ),
    updated_at = NOW()
  WHERE email = 'fedts@hotmail.it';

  -- Verify the update
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE email = 'fedts@hotmail.it' 
    AND role = 'superadmin'
  ) THEN
    RAISE EXCEPTION 'Failed to update user role to superadmin';
  END IF;
END $$;