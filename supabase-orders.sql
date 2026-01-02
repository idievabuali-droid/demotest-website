-- ========================================
-- SUPABASE ORDERS SETUP (OPTIONAL)
-- Run this in your Supabase SQL Editor if you want the Owner dashboard
-- to track orders (Order pipeline + Recent orders).
--
-- Notes:
-- - The Netlify Function uses the Service Role key (bypasses RLS), but we still
--   set strict owner-only read/update policies for safety.
-- ========================================

-- 1) Orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  customer_email text,
  customer_name text,
  status text NOT NULL DEFAULT 'open',
  total_cents integer NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'GBP',
  note text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- 2) Order items
CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id text,
  sku text,
  name text,
  quantity integer NOT NULL DEFAULT 0,
  unit_price_cents integer NOT NULL DEFAULT 0,
  subtotal_cents integer NOT NULL DEFAULT 0,
  variants jsonb NOT NULL DEFAULT '{}'::jsonb,
  inventory_key text NOT NULL DEFAULT '__base__'
);

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);

-- 3) Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 4) Policies: owner-only read & update
DROP POLICY IF EXISTS "orders_owner_read" ON public.orders;
DROP POLICY IF EXISTS "orders_owner_update" ON public.orders;
DROP POLICY IF EXISTS "order_items_owner_read" ON public.order_items;

CREATE POLICY "orders_owner_read"
ON public.orders
FOR SELECT
TO authenticated
USING (public.is_owner());

CREATE POLICY "orders_owner_update"
ON public.orders
FOR UPDATE
TO authenticated
USING (public.is_owner())
WITH CHECK (public.is_owner());

CREATE POLICY "order_items_owner_read"
ON public.order_items
FOR SELECT
TO authenticated
USING (public.is_owner());

-- 5) Grants (safe defaults)
REVOKE ALL ON public.orders FROM anon;
REVOKE ALL ON public.orders FROM authenticated;
REVOKE ALL ON public.order_items FROM anon;
REVOKE ALL ON public.order_items FROM authenticated;

GRANT SELECT ON public.orders TO authenticated;
GRANT UPDATE ON public.orders TO authenticated;
GRANT SELECT ON public.order_items TO authenticated;

-- 6) Verify
SELECT 'orders table' AS check_type,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='orders'
  ) THEN '✅ SUCCESS' ELSE '❌ FAILED' END AS result
UNION ALL
SELECT 'order_items table' AS check_type,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='order_items'
  ) THEN '✅ SUCCESS' ELSE '❌ FAILED' END AS result;
