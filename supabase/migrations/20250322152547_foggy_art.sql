/*
  # Create Test Data

  1. Test Users
    - Creates superadmin, admin, and client users
    - Associates users with companies
  
  2. Test Companies
    - Creates sample companies
  
  3. Test Virtual Gates
    - Creates virtual gates for companies
  
  4. Test Hazardous Areas
    - Creates hazardous areas for companies
  
  5. Test Alerts History
    - Creates sample emergency alerts
*/

-- Create test companies
INSERT INTO public.companies (id, name, phone, description)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'TechCorp SpA', '+39 02 1234567', 'Technology company specializing in software development'),
  ('22222222-2222-2222-2222-222222222222', 'BuildCo Srl', '+39 02 7654321', 'Construction and engineering company'),
  ('33333333-3333-3333-3333-333333333333', 'SafetyFirst Ltd', '+39 02 9876543', 'Industrial safety equipment manufacturer')
ON CONFLICT (id) DO NOTHING;

-- Create test users with different roles
-- Note: Passwords are 'password123' for all users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
VALUES
  -- Superadmin
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'superadmin@example.com', 
   crypt('password123', gen_salt('bf')), NOW(),
   '{"role": "superadmin", "name": "Super Admin"}'::jsonb),
  
  -- Admin for TechCorp
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'admin.tech@example.com',
   crypt('password123', gen_salt('bf')), NOW(),
   '{"role": "admin", "name": "Tech Admin", "company_id": "11111111-1111-1111-1111-111111111111"}'::jsonb),
  
  -- Admin for BuildCo
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'admin.build@example.com',
   crypt('password123', gen_salt('bf')), NOW(),
   '{"role": "admin", "name": "Build Admin", "company_id": "22222222-2222-2222-2222-222222222222"}'::jsonb),
  
  -- Client for TechCorp
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'client.tech@example.com',
   crypt('password123', gen_salt('bf')), NOW(),
   '{"role": "client", "name": "Tech Client", "company_id": "11111111-1111-1111-1111-111111111111"}'::jsonb),
  
  -- Client for BuildCo
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'client.build@example.com',
   crypt('password123', gen_salt('bf')), NOW(),
   '{"role": "client", "name": "Build Client", "company_id": "22222222-2222-2222-2222-222222222222"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Create corresponding user profiles
INSERT INTO public.users (id, uid, name, email, role, company_id, location_sharing, address)
VALUES
  -- Superadmin
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'Super Admin', 'superadmin@example.com', 'superadmin', NULL, false, 'Milan, Italy'),
  
  -- Admin for TechCorp
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   'Tech Admin', 'admin.tech@example.com', 'admin', '11111111-1111-1111-1111-111111111111',
   true, 'Via Roma 1, Milan'),
  
  -- Admin for BuildCo
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
   'Build Admin', 'admin.build@example.com', 'admin', '22222222-2222-2222-2222-222222222222',
   true, 'Via Venezia 2, Milan'),
  
  -- Client for TechCorp
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
   'Tech Client', 'client.tech@example.com', 'client', '11111111-1111-1111-1111-111111111111',
   true, 'Via Torino 3, Milan'),
  
  -- Client for BuildCo
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
   'Build Client', 'client.build@example.com', 'client', '22222222-2222-2222-2222-222222222222',
   true, 'Via Firenze 4, Milan')
ON CONFLICT (id) DO NOTHING;

-- Create test virtual gates
INSERT INTO public.virtual_gates (name, company_id, geo_point)
VALUES
  -- TechCorp gates
  ('Main Entrance', '11111111-1111-1111-1111-111111111111', 'POINT(9.1900 45.4642)'),
  ('Side Gate', '11111111-1111-1111-1111-111111111111', 'POINT(9.1920 45.4652)'),
  
  -- BuildCo gates
  ('Construction Site A', '22222222-2222-2222-2222-222222222222', 'POINT(9.1850 45.4632)'),
  ('Construction Site B', '22222222-2222-2222-2222-222222222222', 'POINT(9.1870 45.4622)'),
  
  -- SafetyFirst gates
  ('Factory Entrance', '33333333-3333-3333-3333-333333333333', 'POINT(9.1890 45.4612)')
ON CONFLICT DO NOTHING;

-- Create test hazardous areas
INSERT INTO public.hazardous_areas (name, company_id, geo_point, radius)
VALUES
  -- TechCorp areas
  ('Server Room', '11111111-1111-1111-1111-111111111111', 'POINT(9.1905 45.4647)', 100),
  ('Chemical Storage', '11111111-1111-1111-1111-111111111111', 'POINT(9.1915 45.4657)', 150),
  
  -- BuildCo areas
  ('Crane Operation Zone', '22222222-2222-2222-2222-222222222222', 'POINT(9.1855 45.4637)', 200),
  ('Excavation Site', '22222222-2222-2222-2222-222222222222', 'POINT(9.1875 45.4627)', 180),
  
  -- SafetyFirst areas
  ('Testing Facility', '33333333-3333-3333-3333-333333333333', 'POINT(9.1895 45.4617)', 120)
ON CONFLICT DO NOTHING;

-- Create test alerts history
INSERT INTO public.alerts (
  user_id, user_name, email, company_id, current_location, address,
  received, timestamp
)
VALUES
  -- TechCorp alerts
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Tech Client', 'client.tech@example.com',
    '11111111-1111-1111-1111-111111111111', '9.1902 45.4644', 'Near Server Room',
    true, NOW() - INTERVAL '2 days'
  ),
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Tech Client', 'client.tech@example.com',
    '11111111-1111-1111-1111-111111111111', '9.1912 45.4654', 'Chemical Storage Area',
    true, NOW() - INTERVAL '1 day'
  ),
  
  -- BuildCo alerts
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Build Client', 'client.build@example.com',
    '22222222-2222-2222-2222-222222222222', '9.1852 45.4634', 'Construction Site A',
    true, NOW() - INTERVAL '3 days'
  ),
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Build Client', 'client.build@example.com',
    '22222222-2222-2222-2222-222222222222', '9.1872 45.4624', 'Construction Site B',
    false, NOW() - INTERVAL '12 hours'
  )
ON CONFLICT DO NOTHING;