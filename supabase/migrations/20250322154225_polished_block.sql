/*
  # Auto-confirm all users

  This migration confirms all existing users in the auth.users table by:
  1. Setting email_confirmed_at to current timestamp if null
  2. Setting last_sign_in_at to current timestamp if null
  3. Setting confirmation_sent_at to current timestamp if null

  This ensures all users can login without email confirmation.
*/

-- Auto-confirm all existing users
UPDATE auth.users
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  last_sign_in_at = COALESCE(last_sign_in_at, NOW()),
  confirmation_sent_at = COALESCE(confirmation_sent_at, NOW())
WHERE 
  email_confirmed_at IS NULL;