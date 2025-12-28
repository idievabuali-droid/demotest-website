-- ========================================
-- OWNER-ONLY WRITES (PRODUCTION-SAFE DEFAULT)
-- Run this in your Supabase SQL Editor.
--
-- Goal:
-- - Customers (anon) can only READ products.
-- - Logged-in users can write ONLY if they are marked as an owner.
--
-- After running:
-- 1) Create a Supabase Auth user for yourself (email+password).
-- 2) Copy that user's UUID (Auth -> Users).
-- 3) Insert it into public.owner_users.
-- ========================================

-- 1) Owner allowlist
CREATE TABLE IF NOT EXISTS public.owner_users (
  user_id uuid PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2) Security-definer helper to check owner status safely
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.owner_users ou
    WHERE ou.user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_owner() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_owner() TO anon, authenticated;

-- 3) Products table must exist (created by your existing setup script)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Remove the old demo "anyone can edit" policy if present
DROP POLICY IF EXISTS "demo_all_access" ON public.products;
DROP POLICY IF EXISTS "Enable all operations for products" ON public.products;
DROP POLICY IF EXISTS "Public read" ON public.products;
DROP POLICY IF EXISTS "Public insert" ON public.products;
DROP POLICY IF EXISTS "Public update" ON public.products;
DROP POLICY IF EXISTS "Public delete" ON public.products;
DROP POLICY IF EXISTS "public all" ON public.products;
DROP POLICY IF EXISTS "public_all_access" ON public.products;

-- 4) Read for everyone
CREATE POLICY "products_public_read"
ON public.products
FOR SELECT
TO anon, authenticated
USING (true);

-- 5) Write ONLY for owners (logged in)
CREATE POLICY "products_owner_insert"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (public.is_owner());

CREATE POLICY "products_owner_update"
ON public.products
FOR UPDATE
TO authenticated
USING (public.is_owner())
WITH CHECK (public.is_owner());

CREATE POLICY "products_owner_delete"
ON public.products
FOR DELETE
TO authenticated
USING (public.is_owner());

-- 6) Tighten grants: anon can read; only authenticated can write
REVOKE ALL ON public.products FROM anon;
REVOKE ALL ON public.products FROM authenticated;
GRANT SELECT ON public.products TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.products TO authenticated;

-- (Optional) Keep realtime publication enabled if you use it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'products'
  ) THEN
    ALTER publication supabase_realtime ADD TABLE public.products;
  END IF;
END $$;

-- 7) Sanity checks
SELECT
  auth.uid() AS current_uid,
  public.is_owner() AS is_owner_now;

