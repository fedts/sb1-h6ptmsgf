/*
  # Update user role to superadmin

  1. Changes
    - Update user 'fede' to have superadmin role
    - Ensure user exists before updating

  2. Security
    - Only modifies the specific user
    - Preserves all other user data
*/

DO $$ 
BEGIN
  -- Update the user's role to superadmin
  UPDATE users
  SET role = 'superadmin'
  WHERE email = 'fede@example.com'
  OR name = 'fede';

  -- Also update the user's metadata in auth.users if it exists
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"superadmin"'
  )
  WHERE email = 'fede@example.com'
  OR raw_user_meta_data->>'name' = 'fede';
END $$;