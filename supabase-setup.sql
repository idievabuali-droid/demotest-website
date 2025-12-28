-- ========================================
-- SUPABASE DATABASE SETUP SCRIPT
-- Run this in your Supabase SQL Editor
-- Copy and paste the entire script and click "Run"
-- ========================================

-- 1. Drop existing table if needed (CAUTION: This will delete all data!)
-- DROP TABLE IF EXISTS public.products;

-- 2. Create the products table with correct structure
CREATE TABLE IF NOT EXISTS public.products (
  id text PRIMARY KEY,
  name text NOT NULL,
  sku text NOT NULL,
  category text NOT NULL,
  price decimal NOT NULL,
  description text DEFAULT '',
  images jsonb DEFAULT '[]'::jsonb,
  specs jsonb DEFAULT '[]'::jsonb,
  variants jsonb DEFAULT '{}'::jsonb,
  sourceid text,  -- Note: lowercase to match your app mapping
  hidden boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Enable Row Level Security
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 4. Drop any existing policies that might conflict
DROP POLICY IF EXISTS "Enable all operations for products" ON public.products;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.products;
DROP POLICY IF EXISTS "Public read" ON public.products;
DROP POLICY IF EXISTS "Public insert" ON public.products;
DROP POLICY IF EXISTS "Public update" ON public.products;
DROP POLICY IF EXISTS "Public delete" ON public.products;
DROP POLICY IF EXISTS "public all" ON public.products;
DROP POLICY IF EXISTS "public_all_access" ON public.products;

-- 5. IMPORTANT SECURITY NOTE
-- This script historically created a demo policy that allowed anonymous write access.
-- For production (even "semi-private" catalogue links), use `supabase-owner-rls.sql`
-- to make the catalogue read-only for customers and owner-only for edits.
--
-- If you still want the old demo behavior, uncomment the policy below:
--
-- CREATE POLICY "demo_all_access" ON public.products
-- FOR ALL
-- TO anon, authenticated
-- USING (true)
-- WITH CHECK (true);

-- 6. Enable realtime for the products table
-- First, make sure the table is in the realtime publication
DO $$
BEGIN
  -- Add table to realtime publication if not already there
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'products'
  ) THEN
    ALTER publication supabase_realtime ADD TABLE public.products;
  END IF;
END $$;

-- 7. Permissions (safe defaults: read for anon, write for authenticated)
REVOKE ALL ON public.products FROM anon;
REVOKE ALL ON public.products FROM authenticated;
GRANT SELECT ON public.products TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 8. Create some test data (optional - remove if you don't want sample data)
INSERT INTO public.products (id, name, sku, category, price, description, specs, images, variants, hidden)
VALUES 
  ('test-1', 'Sample Phone Screen', 'SCR-001', 'Phone Screens', 25.99, 'High-quality replacement screen', '["Compatible with iPhone 12", "Includes tools"]'::jsonb, '[]'::jsonb, '{}'::jsonb, false),
  ('test-2', 'Sample Power Bank', 'PWR-001', 'Power Banks', 15.50, 'Portable charger 10000mAh', '["10000mAh capacity", "Fast charging", "USB-C"]'::jsonb, '[]'::jsonb, '{}'::jsonb, false)
ON CONFLICT (id) DO NOTHING;

-- 9. Verify setup (this will show you if everything worked)
SELECT 
  'Table exists' as check_type,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products' AND table_schema = 'public') 
    THEN '✅ SUCCESS' 
    ELSE '❌ FAILED' 
  END as result
UNION ALL
SELECT 
  'RLS enabled' as check_type,
  CASE WHEN (SELECT row_security FROM information_schema.tables WHERE table_name = 'products' AND table_schema = 'public') = 'YES'
    THEN '✅ SUCCESS' 
    ELSE '❌ FAILED' 
  END as result
UNION ALL
SELECT 
  'Policies exist' as check_type,
  CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'products')
    THEN '✅ SUCCESS'
    ELSE '❌ FAILED'
  END as result
UNION ALL
SELECT 
  'Realtime enabled' as check_type,
  CASE WHEN EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'products')
    THEN '✅ SUCCESS'
    ELSE '❌ FAILED'
  END as result;

-- Success message
SELECT '🎉 Setup complete! Your app should now sync across devices.' as message;
