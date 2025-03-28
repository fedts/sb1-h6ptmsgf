/*
  # Update Marco's role to superadmin

  1. Changes
    - Update Marco's role in public.users table
    - Update Marco's metadata in auth.users table
    - Add safety checks to ensure the update succeeds

  2. Security
    - Maintains existing RLS policies
    - Updates both auth and public tables for consistency
*/

DO $$ 
BEGIN
  -- Update Marco's role in public.users
  UPDATE public.users
  SET 
    role = 'superadmin',
    updated_at = NOW()
  WHERE email = 'marco@techcorp.com';

  -- Update Marco's metadata in auth.users
  UPDATE auth.users
  SET 
    raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb),
      '{role}',
      '"superadmin"'
    ),
    updated_at = NOW()
  WHERE email = 'marco@techcorp.com';

  -- Verify the update was successful
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE email = 'marco@techcorp.com' 
    AND role = 'superadmin'
  ) THEN
    RAISE EXCEPTION 'Failed to update Marco''s role to superadmin';
  END IF;

  -- Log the change
  RAISE NOTICE 'Successfully updated Marco''s role to superadmin';
END $$;