/*
  # Fix authentication flow and user creation

  1. Updates
    - Improve user creation trigger
    - Add better error handling
    - Ensure proper user profile creation

  2. Security
    - Maintain existing RLS policies
    - Keep user permissions intact
*/

-- Update the handle_auth_user_change function to be more robust
CREATE OR REPLACE FUNCTION public.handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Create the user record if it doesn't exist
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
      email = EXCLUDED.email,
      name = EXCLUDED.name,
      role = EXCLUDED.role
    WHERE users.role = 'client'; -- Only update if current role is client
    
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update existing user record
    UPDATE public.users
    SET
      email = NEW.email,
      name = COALESCE(NEW.raw_user_meta_data->>'name', users.name),
      role = CASE 
        WHEN users.role = 'client' THEN COALESCE((NEW.raw_user_meta_data->>'role')::user_role, users.role)
        ELSE users.role -- Keep existing role for non-client users
      END
    WHERE id = NEW.id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Delete user record
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
  END IF;
END;
$$;