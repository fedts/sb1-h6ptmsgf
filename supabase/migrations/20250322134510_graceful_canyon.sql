/*
  # Add test data with proper table creation

  1. New Tables
    - `hazardous_areas`: Store dangerous zones with PostGIS geometry
    - `virtual_gates`: Store virtual gate locations
  
  2. Test Data
    - Companies: 3 sample companies
    - Users: Multiple admins and clients
    - Hazardous Areas: Multiple areas per company
    - Virtual Gates: Multiple gates per company
    - Emergency Alerts: Sample alerts with different statuses

  3. Security
    - Maintains existing RLS policies
    - Ensures proper relationships between entities
*/

-- Create hazardous areas table if it doesn't exist
CREATE TABLE IF NOT EXISTS hazardous_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  geo_point geometry(Point,4326) NOT NULL,
  radius integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create virtual gates table if it doesn't exist
CREATE TABLE IF NOT EXISTS virtual_gates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  geo_point geometry(Point,4326) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE hazardous_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_gates ENABLE ROW LEVEL SECURITY;

-- Create test companies
INSERT INTO companies (id, name, phone, description)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'TechCorp SpA', '+39 02 1234567', 'Leading technology company'),
  ('22222222-2222-2222-2222-222222222222', 'BuildCo Srl', '+39 02 8901234', 'Construction and engineering firm'),
  ('33333333-3333-3333-3333-333333333333', 'SafetyFirst Ltd', '+39 02 5678901', 'Industrial safety solutions')
ON CONFLICT (id) DO NOTHING;

-- Create test users
INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
VALUES
  -- Company Admins
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Marco Rossi', 'marco@techcorp.com', 'admin', '11111111-1111-1111-1111-111111111111', true, 'Via Roma 1, Milan'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Laura Bianchi', 'laura@buildco.com', 'admin', '22222222-2222-2222-2222-222222222222', true, 'Via Dante 15, Milan'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Giuseppe Verdi', 'giuseppe@safetyfirst.com', 'admin', '33333333-3333-3333-3333-333333333333', true, 'Via Montenapoleone 8, Milan'),
  
  -- TechCorp Clients
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Alice Ferrari', 'alice@techcorp.com', 'client', '11111111-1111-1111-1111-111111111111', true, 'Via Torino 25, Milan'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Roberto Mari', 'roberto@techcorp.com', 'client', '11111111-1111-1111-1111-111111111111', true, 'Via Venezia 12, Milan'),
  
  -- BuildCo Clients
  ('11111111-2222-3333-4444-555555555555', 'Sofia Romano', 'sofia@buildco.com', 'client', '22222222-2222-2222-2222-222222222222', true, 'Corso Buenos Aires 45, Milan'),
  ('22222222-3333-4444-5555-666666666666', 'Luca Conti', 'luca@buildco.com', 'client', '22222222-2222-2222-2222-222222222222', true, 'Via Vittorio Emanuele 78, Milan'),
  
  -- SafetyFirst Clients
  ('33333333-4444-5555-6666-777777777777', 'Elena Ricci', 'elena@safetyfirst.com', 'client', '33333333-3333-3333-3333-333333333333', true, 'Corso Sempione 89, Milan'),
  ('44444444-5555-6666-7777-888888888888', 'Paolo Moretti', 'paolo@safetyfirst.com', 'client', '33333333-3333-3333-3333-333333333333', true, 'Via Washington 56, Milan')
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

-- Add emergency alerts
INSERT INTO alerts (
  user_id,
  user_name,
  email,
  company_id,
  current_location,
  address,
  received,
  timestamp
)
VALUES
  -- TechCorp Alerts
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'Alice Ferrari',
    'alice@techcorp.com',
    '11111111-1111-1111-1111-111111111111',
    'POINT(9.1900 45.4642)',
    'Server Room A, TechCorp Building',
    true,
    NOW() - INTERVAL '2 hours'
  ),
  (
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'Roberto Mari',
    'roberto@techcorp.com',
    '11111111-1111-1111-1111-111111111111',
    'POINT(9.1850 45.4639)',
    'Chemical Storage, TechCorp Building',
    false,
    NOW() - INTERVAL '30 minutes'
  ),
  
  -- BuildCo Alerts
  (
    '11111111-2222-3333-4444-555555555555',
    'Sofia Romano',
    'sofia@buildco.com',
    '22222222-2222-2222-2222-222222222222',
    'POINT(9.1800 45.4700)',
    'Construction Site A, BuildCo Area',
    true,
    NOW() - INTERVAL '1 day'
  ),
  
  -- SafetyFirst Alerts
  (
    '33333333-4444-5555-6666-777777777777',
    'Elena Ricci',
    'elena@safetyfirst.com',
    '33333333-3333-3333-3333-333333333333',
    'POINT(9.1700 45.4600)',
    'Testing Lab, SafetyFirst Facility',
    true,
    NOW() - INTERVAL '3 hours'
  )
ON CONFLICT DO NOTHING;