-- ============================================================================
-- SCRIPT DE REVERSIÓN (ROLLBACK): 20261016180000_comercial_cycle_rls_correction_rollback.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Reversión segura de políticas, permisos y función RPC sin afectar datos comerciales.
-- ESTADO: CORREGIDO (FASE 2) — Resuelve C-01, M-03 y B-01 restaurando políticas previas y privilegios simétricos.
-- REGLA ESTRICTA: NO ELIMINA TABLAS NI FILAS DE DATOS COMERCIALES (PRESERVE DATA).
-- ============================================================================

BEGIN;

-- 1. Reversión de triggers y funciones de validación creadas
DROP TRIGGER IF EXISTS trg_protect_negotiations_immutable_fields ON public.negotiations;
DROP FUNCTION IF EXISTS public.protect_negotiations_immutable_fields();

DROP TRIGGER IF EXISTS trg_protect_crops_inventory_columns ON public.crops;
DROP FUNCTION IF EXISTS public.protect_crops_inventory_columns();

-- 2. Reversión de la función RPC transaccional
DROP FUNCTION IF EXISTS public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text);

-- 3. Reversión del índice único parcial de concurrencia
DROP INDEX IF EXISTS public.idx_single_active_negotiation_per_buyer;

-- 4. Eliminación de políticas RLS creadas por la migración de saneamiento
DROP POLICY IF EXISTS "negotiations_select_participants" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_update_participants" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_delete_rollback" ON public.negotiations;

DROP POLICY IF EXISTS "negotiation_offers_select_participants" ON public.negotiation_offers;
DROP POLICY IF EXISTS "negotiation_offers_insert_sender" ON public.negotiation_offers;

DROP POLICY IF EXISTS "inventory_movements_select_participants" ON public.inventory_movements;

DROP POLICY IF EXISTS "crops_select_catalog_and_owner" ON public.crops;
DROP POLICY IF EXISTS "crops_insert_owner" ON public.crops;
DROP POLICY IF EXISTS "crops_update_owner_only" ON public.crops;

DROP POLICY IF EXISTS "profiles_select_commercial_participants" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;

-- 5. RESTAURACIÓN DE POLÍTICAS PREVIAS FUNCIONALES (Evita el Default-Deny Outage - C-01)
-- Recrea las políticas básicas operativas para que las tablas con RLS no queden completamente inaccesibles.

-- 5.1. negotiations
CREATE POLICY "negotiations_select_participants"
ON public.negotiations
FOR SELECT
TO authenticated
USING (
  buyer_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.crops c
    WHERE c.id = negotiations.crop_id
      AND c.farmer_id = auth.uid()
  )
);

CREATE POLICY "Allow buyer insert"
ON public.negotiations
FOR INSERT
TO authenticated
WITH CHECK (buyer_id = auth.uid());

CREATE POLICY "negotiations_update_participants"
ON public.negotiations
FOR UPDATE
TO authenticated
USING (
  buyer_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.crops c
    WHERE c.id = negotiations.crop_id
      AND c.farmer_id = auth.uid()
  )
);

-- 5.2. negotiation_offers
CREATE POLICY "negotiation_offers_select_participants"
ON public.negotiation_offers
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = negotiation_offers.negotiation_id
      AND (n.buyer_id = auth.uid() OR c.farmer_id = auth.uid())
  )
);

CREATE POLICY "Allow participant insert"
ON public.negotiation_offers
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = sender_id);

-- 5.3. inventory_movements (solo lectura funcional para el dueño o comprador)
CREATE POLICY "inventory_movements_select_participants"
ON public.inventory_movements
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.crops c
    WHERE c.id = inventory_movements.crop_id
      AND c.farmer_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.negotiations n
    WHERE n.id = inventory_movements.negotiation_id
      AND n.buyer_id = auth.uid()
  )
);

-- 5.4. crops
CREATE POLICY "crops_select_catalog_and_owner"
ON public.crops
FOR SELECT
TO authenticated, anon
USING (status = 'activa'::public.crop_status OR farmer_id = auth.uid());

CREATE POLICY "crops_insert_owner"
ON public.crops
FOR INSERT
TO authenticated
WITH CHECK (farmer_id = auth.uid());

CREATE POLICY "crops_update_owner_only"
ON public.crops
FOR UPDATE
TO authenticated
USING (farmer_id = auth.uid())
WITH CHECK (farmer_id = auth.uid());

-- 5.5. profiles
CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 6. RESTAURACIÓN INTEGRAL DE PRIVILEGIOS DE TABLA (Resuelve M-03)
-- Restaura privilegios simétricos en todas las tablas comerciales, incluyendo inventory_movements y crops
GRANT SELECT, INSERT, UPDATE, DELETE ON public.negotiations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.negotiation_offers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.crops TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_movements TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- Anon
GRANT SELECT ON public.crops TO anon;

-- 7. REVERSIÓN DE PRIVILEGIOS PREDETERMINADOS (Resuelve B-01)
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;

COMMIT;
