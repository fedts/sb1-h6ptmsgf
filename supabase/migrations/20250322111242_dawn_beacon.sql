/*
  # Fix RLS policies for companies table

  1. Security
    - Add policies if they don't exist:
      - Superadmin: full access to all companies
      - Admin: can view their own company
      - Client: can view their own company
*/

-- Enable RLS if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'companies' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Superadmin full access
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companies' 
    AND policyname = 'Superadmin full access to companies'
  ) THEN
    CREATE POLICY "Superadmin full access to companies"
      ON companies
      FOR ALL
      TO authenticated
      USING (get_user_role() = 'superadmin'::user_role)
      WITH CHECK (get_user_role() = 'superadmin'::user_role);
  END IF;
END $$;

-- Users can view their own company
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companies' 
    AND policyname = 'Users can view own company'
  ) THEN
    CREATE POLICY "Users can view own company"
      ON companies
      FOR SELECT
      TO authenticated
      USING (id = get_user_company());
  END IF;
END $$;

-- Admin can view their own company
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companies' 
    AND policyname = 'Admin can view own company'
  ) THEN
    CREATE POLICY "Admin can view own company"
      ON companies
      FOR SELECT
      TO authenticated
      USING (id = get_user_company() AND get_user_role() = 'admin'::user_role);
  END IF;
END $$;