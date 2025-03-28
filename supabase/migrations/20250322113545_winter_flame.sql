/*
  # Fix user authentication synchronization

  1. Changes
    - Create temporary table for existing users
    - Update users table structure
    - Migrate existing data
    - Set up trigger for auth synchronization

  2. Security
    - Maintain existing RLS policies
    - Ensure data consistency between auth and public schemas
*/

-- Create a temporary table to store existing user data
CREATE TEMP TABLE temp_users AS
SELECT * FROM users;

-- Drop existing constraints and triggers
DROP TRIGGER IF EXISTS on_auth_user_change ON auth.users;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_uid_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_uid_key;

-- Update users table structure
ALTER TABLE users 
ALTER COLUMN uid DROP NOT NULL;

-- Create function to handle user creation/updates
CREATE OR REPLACE FUNCTION public.handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.users (
      id,
      uid,
      email,
      name,
      role
    )
    VALUES (
      NEW.id,
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
      COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client'::user_role)
    )
    ON CONFLICT (id) DO UPDATE
    SET
      uid = EXCLUDED.uid,
      email = EXCLUDED.email,
      name = EXCLUDED.name,
      role = EXCLUDED.role;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.users
    SET
      email = NEW.email,
      name = COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
      role = COALESCE((NEW.raw_user_meta_data->>'role')::user_role, users.role)
    WHERE id = NEW.id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
  END IF;
END;
$$;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_change
  AFTER INSERT OR UPDATE OR DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_auth_user_change();

-- Update existing users with auth data
UPDATE users u
SET
  uid = a.id
FROM auth.users a
WHERE u.email = a.email
  AND u.uid IS NULL;

-- Now we can safely add the constraints
ALTER TABLE users
ADD CONSTRAINT users_uid_key UNIQUE (uid);

ALTER TABLE users
ADD CONSTRAINT users_uid_fkey 
FOREIGN KEY (uid) 
REFERENCES auth.users(id)
ON DELETE CASCADE;