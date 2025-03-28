/*
  # Update superadmin password

  This migration updates the password for the superadmin@example.com user to '123456'.
*/

-- Update password for superadmin user
UPDATE auth.users
SET encrypted_password = crypt('123456', gen_salt('bf'))
WHERE email = 'superadmin@example.com';