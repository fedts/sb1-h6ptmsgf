/*
  # Create test user account

  Creates a test user with email "your-test@example.com" and password "TestPassword123"
*/

-- Create test user in auth.users
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data
)
VALUES (
  '99999999-9999-9999-9999-999999999999',
  'your-test@example.com',
  crypt('TestPassword123', gen_salt('bf')),
  NOW(),
  '{"role": "client", "name": "Test User"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- Create corresponding user profile
INSERT INTO public.users (
  id,
  uid,
  name,
  email,
  role,
  location_sharing,
  address
)
VALUES (
  '99999999-9999-9999-9999-999999999999',
  '99999999-9999-9999-9999-999999999999',
  'Test User',
  'your-test@example.com',
  'client',
  true,
  'Test Address, Milan'
)
ON CONFLICT (id) DO NOTHING;