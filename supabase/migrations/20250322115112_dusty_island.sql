-- Update the handle_auth_user_change function to be more robust
CREATE OR REPLACE FUNCTION public.handle_auth_user_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Ensure we don't create duplicate users
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
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
      );
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.users
    SET
      email = NEW.email,
      name = COALESCE(NEW.raw_user_meta_data->>'name', users.name),
      role = COALESCE((NEW.raw_user_meta_data->>'role')::user_role, users.role)
    WHERE id = NEW.id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
  END IF;
END;
$$;