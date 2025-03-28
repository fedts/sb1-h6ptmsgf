-- Add test data for hazardous areas and virtual gates

-- Create test companies if they don't exist
INSERT INTO companies (id, name, phone, description)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'TechCorp SpA', '+39 02 1234567', 'Leading technology company'),
  ('22222222-2222-2222-2222-222222222222', 'BuildCo Srl', '+39 02 8901234', 'Construction and engineering firm'),
  ('33333333-3333-3333-3333-333333333333', 'SafetyFirst Ltd', '+39 02 5678901', 'Industrial safety solutions')
ON CONFLICT (id) DO NOTHING;

-- Add hazardous areas
INSERT INTO hazardous_areas (name, company_id, geo_point, radius)
VALUES
  -- TechCorp Areas
  ('Server Room A', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1900, 45.4642), 4326), 100),
  ('Chemical Storage', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1850, 45.4639), 4326), 150),
  ('High Voltage Zone', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1920, 45.4645), 4326), 200),
  
  -- BuildCo Areas
  ('Construction Site A', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1800, 45.4700), 4326), 300),
  ('Heavy Machinery Zone', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1810, 45.4695), 4326), 250),
  
  -- SafetyFirst Areas
  ('Testing Lab', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1700, 45.4600), 4326), 150),
  ('Radiation Zone', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1710, 45.4605), 4326), 200)
ON CONFLICT DO NOTHING;

-- Add virtual gates
INSERT INTO virtual_gates (name, company_id, geo_point)
VALUES
  -- TechCorp Gates
  ('Main Entrance', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1895, 45.4640), 4326)),
  ('Emergency Exit A', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1905, 45.4643), 4326)),
  
  -- BuildCo Gates
  ('Site Entry', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1795, 45.4698), 4326)),
  ('Vehicle Gate', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1805, 45.4693), 4326)),
  
  -- SafetyFirst Gates
  ('Lab Access', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1695, 45.4598), 4326)),
  ('Staff Entrance', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1705, 45.4603), 4326))
ON CONFLICT DO NOTHING;