/*
  # Add test data for virtual gates and hazardous areas

  1. New Test Data
    - Additional virtual gates for each company
    - Additional hazardous areas with realistic scenarios
    - All locations are within Milan's industrial areas

  2. Data Structure
    - Virtual gates: entry/exit points with coordinates
    - Hazardous areas: zones with radius and risk level
*/

-- Add more virtual gates in Milan's industrial areas
INSERT INTO public.virtual_gates (name, company_id, geo_point)
VALUES
  -- TechCorp additional gates
  ('R&D Lab Entrance', '11111111-1111-1111-1111-111111111111', 'POINT(9.1930 45.4662)'),
  ('Emergency Exit North', '11111111-1111-1111-1111-111111111111', 'POINT(9.1925 45.4657)'),
  ('Parking Gate', '11111111-1111-1111-1111-111111111111', 'POINT(9.1915 45.4647)'),
  
  -- BuildCo additional gates
  ('Site C Access', '22222222-2222-2222-2222-222222222222', 'POINT(9.1860 45.4642)'),
  ('Materials Delivery Gate', '22222222-2222-2222-2222-222222222222', 'POINT(9.1865 45.4632)'),
  ('Heavy Equipment Access', '22222222-2222-2222-2222-222222222222', 'POINT(9.1875 45.4627)'),
  
  -- SafetyFirst additional gates
  ('Production Area Gate', '33333333-3333-3333-3333-333333333333', 'POINT(9.1885 45.4622)'),
  ('Warehouse Access', '33333333-3333-3333-3333-333333333333', 'POINT(9.1895 45.4617)'),
  ('Staff Entrance', '33333333-3333-3333-3333-333333333333', 'POINT(9.1890 45.4612)')
ON CONFLICT DO NOTHING;

-- Add more hazardous areas with realistic scenarios
INSERT INTO public.hazardous_areas (name, company_id, geo_point, radius)
VALUES
  -- TechCorp additional hazardous areas
  ('High Voltage Testing Lab', '11111111-1111-1111-1111-111111111111', 'POINT(9.1935 45.4667)', 150),
  ('Battery Storage Facility', '11111111-1111-1111-1111-111111111111', 'POINT(9.1940 45.4672)', 200),
  ('EMF Testing Chamber', '11111111-1111-1111-1111-111111111111', 'POINT(9.1945 45.4677)', 100),
  
  -- BuildCo additional hazardous areas
  ('Heavy Machinery Zone', '22222222-2222-2222-2222-222222222222', 'POINT(9.1865 45.4647)', 250),
  ('Demolition Area', '22222222-2222-2222-2222-222222222222', 'POINT(9.1870 45.4652)', 300),
  ('Material Storage Zone', '22222222-2222-2222-2222-222222222222', 'POINT(9.1875 45.4657)', 180),
  
  -- SafetyFirst additional hazardous areas
  ('Chemical Processing Unit', '33333333-3333-3333-3333-333333333333', 'POINT(9.1880 45.4627)', 200),
  ('High Temperature Zone', '33333333-3333-3333-3333-333333333333', 'POINT(9.1885 45.4632)', 150),
  ('Pressure Testing Area', '33333333-3333-3333-3333-333333333333', 'POINT(9.1890 45.4637)', 175)
ON CONFLICT DO NOTHING;

-- Add test alerts for the new hazardous areas
INSERT INTO public.alerts (
  user_id, user_name, email, company_id, current_location, address,
  received, timestamp
)
VALUES
  -- Recent alerts for TechCorp
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Tech Client', 'client.tech@example.com',
    '11111111-1111-1111-1111-111111111111', '9.1937 45.4669', 'Near High Voltage Lab',
    false, NOW() - INTERVAL '2 hours'
  ),
  
  -- Recent alerts for BuildCo
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Build Client', 'client.build@example.com',
    '22222222-2222-2222-2222-222222222222', '9.1867 45.4649', 'Heavy Machinery Zone',
    false, NOW() - INTERVAL '1 hour'
  ),
  
  -- Recent alerts for SafetyFirst
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Tech Client', 'client.tech@example.com',
    '11111111-1111-1111-1111-111111111111', '9.1882 45.4629', 'Chemical Processing Unit',
    true, NOW() - INTERVAL '30 minutes'
  )
ON CONFLICT DO NOTHING;