/*
  # Enable Federico's Location Sharing

  1. Changes
    - Set location_sharing to true for Federico's user profile
    - Add a trigger to ensure it stays enabled
*/

-- Update Federico's user profile
UPDATE public.users
SET location_sharing = true
WHERE email = 'fedts@hotmail.it';

-- Create trigger function to maintain location sharing enabled
CREATE OR REPLACE FUNCTION maintain_location_sharing()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email = 'fedts@hotmail.it' AND NEW.location_sharing = false THEN
    NEW.location_sharing := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS ensure_federico_location_sharing ON public.users;
CREATE TRIGGER ensure_federico_location_sharing
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION maintain_location_sharing();