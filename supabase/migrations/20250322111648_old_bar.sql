/*
  # Add test data with existence checks

  1. New Data
    - Companies: 3 sample companies
    - Users: 1 superadmin, 3 admins (one per company), 6 clients
    - Hazardous Areas: 2-3 areas per company
    - Virtual Gates: 2-3 gates per company
    - Emergency Alerts: Sample alerts with different statuses
    
  2. Security
    - Maintains existing RLS policies
    - Data respects company relationships
    - Checks for existing records before insertion
*/

DO $$
BEGIN
    -- Add test companies if they don't exist
    IF NOT EXISTS (SELECT 1 FROM companies WHERE id = '11111111-1111-1111-1111-111111111111') THEN
        INSERT INTO companies (id, name, phone, description)
        VALUES ('11111111-1111-1111-1111-111111111111', 'TechCorp SpA', '+39 02 1234567', 'Leading technology company');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM companies WHERE id = '22222222-2222-2222-2222-222222222222') THEN
        INSERT INTO companies (id, name, phone, description)
        VALUES ('22222222-2222-2222-2222-222222222222', 'BuildCo Srl', '+39 02 8901234', 'Construction and engineering firm');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM companies WHERE id = '33333333-3333-3333-3333-333333333333') THEN
        INSERT INTO companies (id, name, phone, description)
        VALUES ('33333333-3333-3333-3333-333333333333', 'SafetyFirst Ltd', '+39 02 5678901', 'Industrial safety solutions');
    END IF;

    -- Add test users if they don't exist
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Admin System', 'admin@vigilant.com', 'superadmin', NULL, false, 'Milan, Italy');
    END IF;

    -- Company Admins
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Marco Rossi', 'marco@techcorp.com', 'admin', '11111111-1111-1111-1111-111111111111', true, 'Via Roma 1, Milan');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Laura Bianchi', 'laura@buildco.com', 'admin', '22222222-2222-2222-2222-222222222222', true, 'Via Dante 15, Milan');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Giuseppe Verdi', 'giuseppe@safetyfirst.com', 'admin', '33333333-3333-3333-3333-333333333333', true, 'Via Montenapoleone 8, Milan');
    END IF;

    -- TechCorp Clients
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Alice Ferrari', 'alice@techcorp.com', 'client', '11111111-1111-1111-1111-111111111111', true, 'Via Torino 25, Milan');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'ffffffff-ffff-ffff-ffff-ffffffffffff') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Roberto Mari', 'roberto@techcorp.com', 'client', '11111111-1111-1111-1111-111111111111', true, 'Via Venezia 12, Milan');
    END IF;

    -- BuildCo Clients
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '11111111-2222-3333-4444-555555555555') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('11111111-2222-3333-4444-555555555555', 'Sofia Romano', 'sofia@buildco.com', 'client', '22222222-2222-2222-2222-222222222222', true, 'Corso Buenos Aires 45, Milan');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '22222222-3333-4444-5555-666666666666') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('22222222-3333-4444-5555-666666666666', 'Luca Conti', 'luca@buildco.com', 'client', '22222222-2222-2222-2222-222222222222', true, 'Via Vittorio Emanuele 78, Milan');
    END IF;

    -- SafetyFirst Clients
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '33333333-4444-5555-6666-777777777777') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('33333333-4444-5555-6666-777777777777', 'Elena Ricci', 'elena@safetyfirst.com', 'client', '33333333-3333-3333-3333-333333333333', true, 'Corso Sempione 89, Milan');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '44444444-5555-6666-7777-888888888888') THEN
        INSERT INTO users (id, name, email, role, company_id, location_sharing, address)
        VALUES ('44444444-5555-6666-7777-888888888888', 'Paolo Moretti', 'paolo@safetyfirst.com', 'client', '33333333-3333-3333-3333-333333333333', true, 'Via Washington 56, Milan');
    END IF;

    -- Add hazardous areas if they don't exist
    IF NOT EXISTS (SELECT 1 FROM hazardous_areas WHERE company_id = '11111111-1111-1111-1111-111111111111' AND name = 'Server Room A') THEN
        INSERT INTO hazardous_areas (name, company_id, geo_point, radius)
        VALUES
            ('Server Room A', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1900, 45.4642), 4326), 100),
            ('Chemical Storage', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1850, 45.4639), 4326), 150),
            ('High Voltage Zone', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1920, 45.4645), 4326), 200);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM hazardous_areas WHERE company_id = '22222222-2222-2222-2222-222222222222' AND name = 'Construction Site A') THEN
        INSERT INTO hazardous_areas (name, company_id, geo_point, radius)
        VALUES
            ('Construction Site A', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1800, 45.4700), 4326), 300),
            ('Heavy Machinery Zone', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1810, 45.4695), 4326), 250);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM hazardous_areas WHERE company_id = '33333333-3333-3333-3333-333333333333' AND name = 'Testing Lab') THEN
        INSERT INTO hazardous_areas (name, company_id, geo_point, radius)
        VALUES
            ('Testing Lab', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1700, 45.4600), 4326), 150),
            ('Radiation Zone', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1710, 45.4605), 4326), 200);
    END IF;

    -- Add virtual gates if they don't exist
    IF NOT EXISTS (SELECT 1 FROM virtual_gates WHERE company_id = '11111111-1111-1111-1111-111111111111' AND name = 'Main Entrance') THEN
        INSERT INTO virtual_gates (name, company_id, geo_point)
        VALUES
            ('Main Entrance', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1895, 45.4640), 4326)),
            ('Emergency Exit A', '11111111-1111-1111-1111-111111111111', ST_SetSRID(ST_MakePoint(9.1905, 45.4643), 4326));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM virtual_gates WHERE company_id = '22222222-2222-2222-2222-222222222222' AND name = 'Site Entry') THEN
        INSERT INTO virtual_gates (name, company_id, geo_point)
        VALUES
            ('Site Entry', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1795, 45.4698), 4326)),
            ('Vehicle Gate', '22222222-2222-2222-2222-222222222222', ST_SetSRID(ST_MakePoint(9.1805, 45.4693), 4326));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM virtual_gates WHERE company_id = '33333333-3333-3333-3333-333333333333' AND name = 'Lab Access') THEN
        INSERT INTO virtual_gates (name, company_id, geo_point)
        VALUES
            ('Lab Access', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1695, 45.4598), 4326)),
            ('Staff Entrance', '33333333-3333-3333-3333-333333333333', ST_SetSRID(ST_MakePoint(9.1705, 45.4603), 4326));
    END IF;

    -- Add emergency alerts if they don't exist
    IF NOT EXISTS (SELECT 1 FROM alerts WHERE user_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' AND timestamp = NOW() - INTERVAL '2 hours') THEN
        INSERT INTO alerts (user_id, user_name, email, company_id, current_location, address, received, timestamp)
        VALUES
            (
                'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
                'Alice Ferrari',
                'alice@techcorp.com',
                '11111111-1111-1111-1111-111111111111',
                'POINT(9.1900 45.4642)',
                'Server Room A, TechCorp Building',
                true,
                NOW() - INTERVAL '2 hours'
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM alerts WHERE user_id = 'ffffffff-ffff-ffff-ffff-ffffffffffff' AND timestamp = NOW() - INTERVAL '30 minutes') THEN
        INSERT INTO alerts (user_id, user_name, email, company_id, current_location, address, received, timestamp)
        VALUES
            (
                'ffffffff-ffff-ffff-ffff-ffffffffffff',
                'Roberto Mari',
                'roberto@techcorp.com',
                '11111111-1111-1111-1111-111111111111',
                'POINT(9.1850 45.4639)',
                'Chemical Storage, TechCorp Building',
                false,
                NOW() - INTERVAL '30 minutes'
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM alerts WHERE user_id = '11111111-2222-3333-4444-555555555555' AND timestamp = NOW() - INTERVAL '1 day') THEN
        INSERT INTO alerts (user_id, user_name, email, company_id, current_location, address, received, timestamp)
        VALUES
            (
                '11111111-2222-3333-4444-555555555555',
                'Sofia Romano',
                'sofia@buildco.com',
                '22222222-2222-2222-2222-222222222222',
                'POINT(9.1800 45.4700)',
                'Construction Site A, BuildCo Area',
                true,
                NOW() - INTERVAL '1 day'
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM alerts WHERE user_id = '33333333-4444-5555-6666-777777777777' AND timestamp = NOW() - INTERVAL '3 hours') THEN
        INSERT INTO alerts (user_id, user_name, email, company_id, current_location, address, received, timestamp)
        VALUES
            (
                '33333333-4444-5555-6666-777777777777',
                'Elena Ricci',
                'elena@safetyfirst.com',
                '33333333-3333-3333-3333-333333333333',
                'POINT(9.1700 45.4600)',
                'Testing Lab, SafetyFirst Facility',
                true,
                NOW() - INTERVAL '3 hours'
            );
    END IF;
END $$;