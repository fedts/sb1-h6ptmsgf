/*
  # Create virtual gates table

  1. New Tables
    - `virtual_gates`
      - `id` (uuid, primary key)
      - `name` (text)
      - `company_id` (uuid, foreign key to companies)
      - `geo_point` (geometry(Point,4326))
      - `created_at` (timestamp with time zone)
      - `updated_at` (timestamp with time zone)
  
  2. Security
    - Enable RLS on `virtual_gates` table
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS virtual_gates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  geo_point geometry(Point,4326) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE virtual_gates ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Superadmin full access to virtual gates"
  ON virtual_gates
  FOR ALL
  TO authenticated
  USING (get_user_role() = 'superadmin'::user_role)
  WITH CHECK (get_user_role() = 'superadmin'::user_role);

CREATE POLICY "Admin can manage company virtual gates"
  ON virtual_gates
  FOR ALL
  TO authenticated
  USING ((get_user_role() = 'admin'::user_role) AND (company_id = get_user_company()))
  WITH CHECK ((get_user_role() = 'admin'::user_role) AND (company_id = get_user_company()));