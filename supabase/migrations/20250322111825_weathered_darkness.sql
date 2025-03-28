/*
  # Add RLS policies for companies table (with existence check)

  1. Security Changes
    - Enable RLS on companies table if not already enabled
    - Add policies if they don't exist:
      - Superadmin: full access to all companies
      - Admin: can manage their own company
      - Client: can view their own company
*/

DO $$ 
BEGIN
    -- Enable RLS if not already enabled
    IF NOT EXISTS (
        SELECT 1
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'companies'
        AND rowsecurity = true
    ) THEN
        ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
    END IF;

    -- Create Superadmin policy if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'companies' 
        AND policyname = 'Superadmin full access to companies'
    ) THEN
        CREATE POLICY "Superadmin full access to companies"
        ON companies
        FOR ALL
        TO authenticated
        USING (get_user_role() = 'superadmin'::user_role)
        WITH CHECK (get_user_role() = 'superadmin'::user_role);
    END IF;

    -- Create Admin policy if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'companies' 
        AND policyname = 'Admin can manage company'
    ) THEN
        CREATE POLICY "Admin can manage company"
        ON companies
        FOR ALL
        TO authenticated
        USING ((get_user_role() = 'admin'::user_role) AND (id = get_user_company()))
        WITH CHECK ((get_user_role() = 'admin'::user_role) AND (id = get_user_company()));
    END IF;

    -- Create User view policy if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'companies' 
        AND policyname = 'Users can view own company'
    ) THEN
        CREATE POLICY "Users can view own company"
        ON companies
        FOR SELECT
        TO authenticated
        USING (id = get_user_company());
    END IF;
END $$;