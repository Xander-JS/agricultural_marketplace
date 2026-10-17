-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261016180000_comercial_cycle_rls_correction.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Corrección controlada del ciclo comercial, seguridad RLS y concurrencia.
-- ESTADO: PROPUESTA TÉCNICA CORREGIDA (FASE 2) — AUDITADA CONTRA HALLAZGOS C-01, C-02, A-01..03, M-01..03, B-01.
-- ============================================================================

-- INSTRUCCIONES DE USO:
-- 1. Revisar este archivo antes de su aplicación en el SQL Editor de Supabase o CLI local.
-- 2. No altera ni elimina datos comerciales existentes (crops, negotiations, profiles, inventory_movements).
-- 3. Implementa función transaccional RPC, sanea políticas RLS y restringe privilegios al mínimo necesario.

BEGIN;

-- ============================================================================
-- 1. SANEAMIENTO Y CORRECCIÓN DE POLÍTICAS RLS EN public.negotiations
-- ============================================================================

-- Asegurar RLS activo
ALTER TABLE public.negotiations ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas duplicadas o permisivas previas
DROP POLICY IF EXISTS "negotiations_insert_buyer" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_select_participants" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_update_participants" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_delete_rollback" ON public.negotiations;
DROP POLICY IF EXISTS "Allow buyer insert" ON public.negotiations;
DROP POLICY IF EXISTS "Users can insert negotiations" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_insert_policy" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_select_policy" ON public.negotiations;

-- 1.1. Lectura estricta: Solo participantes legítimos (comprador o agricultor dueño del cultivo)
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

-- 1.2. Inserción directa revocada para clientes (Cierre del Hallazgo A-02):
-- No se crea política de INSERT para authenticated ni anon. La creación de negociaciones se
-- canaliza EXCLUSIVAMENTE a través de la función transaccional RPC create_negotiation_with_offer
-- ejecutada bajo SECURITY DEFINER (owner postgres), garantizando la validación previa de perfil aprobado.

-- 1.3. Actualización de turnos y estados comerciales por participantes (Cierre del Hallazgo C-02):
-- Solo permite transiciones activas de negociación: contraofertada, rechazada o cancelada.
-- Se PROHÍBE terminantemente forzar los estados 'acordada' o 'completada' vía REST directo,
-- ya que dichos estados requieren reserva/mutación atómica de inventario contable.
CREATE POLICY "negotiations_update_participants"
ON public.negotiations
FOR UPDATE
TO authenticated
USING (
  (
    buyer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.crops c
      WHERE c.id = negotiations.crop_id
        AND c.farmer_id = auth.uid()
    )
  )
  AND status IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status)
)
WITH CHECK (
  status IN (
    'contraofertada'::public.negotiation_status,
    'rechazada'::public.negotiation_status,
    'cancelada'::public.negotiation_status
  )
);

-- 1.4. Eliminación restringida: Solo rollback de propuestas huérfanas sin ofertas
CREATE POLICY "negotiations_delete_rollback"
ON public.negotiations
FOR DELETE
TO authenticated
USING (
  buyer_id = auth.uid()
  AND status = 'propuesta'::public.negotiation_status
  AND NOT EXISTS (
    SELECT 1 FROM public.negotiation_offers o
    WHERE o.negotiation_id = negotiations.id
  )
);

-- 1.5. Trigger de protección contra mutación de campos inmutables en negotiations:
CREATE OR REPLACE FUNCTION public.protect_negotiations_immutable_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'El identificador de la negociación es inmutable' USING ERRCODE = '42501';
  END IF;
  IF NEW.crop_id IS DISTINCT FROM OLD.crop_id THEN
    RAISE EXCEPTION 'El cultivo asociado a la negociación es inmutable' USING ERRCODE = '42501';
  END IF;
  IF NEW.buyer_id IS DISTINCT FROM OLD.buyer_id THEN
    RAISE EXCEPTION 'El comprador de la negociación es inmutable' USING ERRCODE = '42501';
  END IF;
  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'La fecha de creación de la negociación es inmutable' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_negotiations_immutable_fields ON public.negotiations;
CREATE TRIGGER trg_protect_negotiations_immutable_fields
BEFORE UPDATE ON public.negotiations
FOR EACH ROW
EXECUTE FUNCTION public.protect_negotiations_immutable_fields();


-- ============================================================================
-- 2. SANEAMIENTO Y CORRECCIÓN DE POLÍTICAS RLS EN public.negotiation_offers
-- ============================================================================

ALTER TABLE public.negotiation_offers ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas duplicadas previas
DROP POLICY IF EXISTS "negotiation_offers_select_participants" ON public.negotiation_offers;
DROP POLICY IF EXISTS "negotiation_offers_insert_sender" ON public.negotiation_offers;
DROP POLICY IF EXISTS "Allow participant insert" ON public.negotiation_offers;
DROP POLICY IF EXISTS "Users can insert offers" ON public.negotiation_offers;
DROP POLICY IF EXISTS "negotiation_offers_insert_policy" ON public.negotiation_offers;
DROP POLICY IF EXISTS "negotiation_offers_select_policy" ON public.negotiation_offers;

-- 2.1. Lectura: Participantes del trato
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

-- 2.2. Inserción: Emisor participante en negociación activa (para contraofertas legítimas)
CREATE POLICY "negotiation_offers_insert_sender"
ON public.negotiation_offers
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND quantity_kg > 0
  AND proposed_price_per_kg > 0
  AND EXISTS (
    SELECT 1 FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = negotiation_id
      AND (n.buyer_id = auth.uid() OR c.farmer_id = auth.uid())
      AND n.status IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status)
  )
);

-- INMUTABILIDAD ESTRICTA: No existen políticas FOR UPDATE ni FOR DELETE en negotiation_offers.


-- ============================================================================
-- 3. SANEAMIENTO CRÍTICO EN public.inventory_movements
-- ============================================================================

ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas abiertas permisivas
DROP POLICY IF EXISTS "inventory_movements_all_open" ON public.inventory_movements;
DROP POLICY IF EXISTS "inventory_movements_allow_all" ON public.inventory_movements;
DROP POLICY IF EXISTS "inventory_movements_select_participants" ON public.inventory_movements;
DROP POLICY IF EXISTS "Enable all access for all users" ON public.inventory_movements;
DROP POLICY IF EXISTS "Public inventory movements" ON public.inventory_movements;

-- 3.1. Solo lectura para participantes legítimos del cultivo o negociación asociada
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

-- REGLA DE SEGURIDAD:
-- Ningún rol cliente (anon ni authenticated) tiene permiso de INSERT, UPDATE o DELETE directo.
-- Todo movimiento de stock debe originarse exclusivamente desde funciones con SECURITY DEFINER.


-- ============================================================================
-- 4. POLÍTICAS RLS Y PROTECCIÓN DE INVENTARIO EN public.crops (Cierre M-01)
-- ============================================================================

ALTER TABLE public.crops ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "crops_select_catalog_and_owner" ON public.crops;
DROP POLICY IF EXISTS "crops_insert_owner" ON public.crops;
DROP POLICY IF EXISTS "crops_update_owner_only" ON public.crops;
DROP POLICY IF EXISTS "crops_delete_owner_only" ON public.crops;

-- 4.1. Catálogo activo visible para authenticated y anon; cultivos propios visibles para el dueño
CREATE POLICY "crops_select_catalog_and_owner"
ON public.crops
FOR SELECT
TO authenticated, anon
USING (
  status = 'activa'::public.crop_status
  OR farmer_id = auth.uid()
);

-- 4.2. Inserción exclusiva del agricultor dueño
CREATE POLICY "crops_insert_owner"
ON public.crops
FOR INSERT
TO authenticated
WITH CHECK (
  farmer_id = auth.uid()
  AND price_per_kg > 0
  AND stock_total >= 0
  AND min_order_kg > 0
);

-- 4.3. Modificación directa exclusiva del agricultor dueño
CREATE POLICY "crops_update_owner_only"
ON public.crops
FOR UPDATE
TO authenticated
USING (farmer_id = auth.uid())
WITH CHECK (farmer_id = auth.uid());

-- 4.4. Trigger de protección contra manipulación directa de stock comprometido y vendido:
CREATE OR REPLACE FUNCTION public.protect_crops_inventory_columns()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Si la mutación se realiza bajo rol cliente (authenticated o anon), prohibir
  -- terminantemente alterar stock_committed o stock_sold vía REST directo.
  -- Estas columnas solo pueden mutar mediante funciones transaccionales SECURITY DEFINER.
  IF current_user IN ('authenticated', 'anon') THEN
    IF NEW.stock_committed IS DISTINCT FROM OLD.stock_committed THEN
      RAISE EXCEPTION 'No está permitido modificar directamente la columna stock_committed' USING ERRCODE = '42501';
    END IF;
    IF NEW.stock_sold IS DISTINCT FROM OLD.stock_sold THEN
      RAISE EXCEPTION 'No está permitido modificar directamente la columna stock_sold' USING ERRCODE = '42501';
    END IF;
    IF NEW.farmer_id IS DISTINCT FROM OLD.farmer_id THEN
      RAISE EXCEPTION 'No está permitido transferir la propiedad del cultivo' USING ERRCODE = '42501';
    END IF;
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'El identificador del cultivo es inmutable' USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_crops_inventory_columns ON public.crops;
CREATE TRIGGER trg_protect_crops_inventory_columns
BEFORE UPDATE ON public.crops
FOR EACH ROW
EXECUTE FUNCTION public.protect_crops_inventory_columns();


-- ============================================================================
-- 5. POLÍTICAS RLS COMERCIALES EN public.profiles (Cierre del Hallazgo A-03)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_commercial_participants" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;

-- 5.1. Lectura comercial acotada a necesidades legítimas:
-- Permite al usuario consultar su propio perfil, o perfiles de agricultores con cosechas activas
-- en el catálogo, o perfiles de contrapartes comerciales en negociaciones vinculadas.
CREATE POLICY "profiles_select_commercial_participants"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  -- Perfil propio
  auth.uid() = id
  -- O agricultor de un cultivo activo en el catálogo
  OR EXISTS (
    SELECT 1 FROM public.crops c
    WHERE c.farmer_id = profiles.id
      AND c.status = 'activa'::public.crop_status
  )
  -- O contraparte comercial de una negociación en curso
  OR EXISTS (
    SELECT 1 FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE (n.buyer_id = profiles.id AND c.farmer_id = auth.uid())
       OR (c.farmer_id = profiles.id AND n.buyer_id = auth.uid())
  )
);

-- 5.2. Inserción de perfil propio
CREATE POLICY "profiles_insert_own"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 5.3. Actualización de perfil propio
CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);


-- ============================================================================
-- 6. RESTRICCIÓN DE PRIVILEGIOS SQL (PRINCIPIO DE MÍNIMO PRIVILEGIO)
-- ============================================================================

-- 6.1. Restringir rol anon
REVOKE ALL ON public.negotiations FROM anon;
REVOKE ALL ON public.negotiation_offers FROM anon;
REVOKE ALL ON public.inventory_movements FROM anon;
REVOKE ALL ON public.profiles FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.crops FROM anon;
GRANT SELECT ON public.crops TO anon;

-- 6.2. Restringir rol authenticated
-- Bloquear mutación directa de inventario desde clientes móviles
REVOKE ALL ON public.inventory_movements FROM authenticated;
GRANT SELECT ON public.inventory_movements TO authenticated;

-- Bloquear mutación de ofertas registradas (historial inmutable)
REVOKE ALL ON public.negotiation_offers FROM authenticated;
GRANT SELECT, INSERT ON public.negotiation_offers TO authenticated;

-- negotiations: revocamos INSERT directo a authenticated (cierre de bypass A-02).
-- Solo se concede SELECT, UPDATE (filtrado por RLS) y DELETE (rollback de huérfanas).
REVOKE ALL ON public.negotiations FROM authenticated;
GRANT SELECT, UPDATE, DELETE ON public.negotiations TO authenticated;

-- crops: SELECT, INSERT y UPDATE restringido a columnas comerciales legítimas
-- (sin otorgar UPDATE a stock_committed ni stock_sold)
REVOKE ALL ON public.crops FROM authenticated;
GRANT SELECT, INSERT ON public.crops TO authenticated;
GRANT UPDATE (
  title,
  description,
  crop_type,
  price_per_kg,
  stock_total,
  min_order_kg,
  department,
  municipality,

  status,
  updated_at
) ON public.crops TO authenticated;


-- crop_images: acceso de lectura solo a cultivos activos o propios.
ALTER TABLE public.crop_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "crop_images_select_visible_crops"
ON public.crop_images
FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND (
        c.status = 'activa'
        OR c.farmer_id = (SELECT auth.uid())
      )
  )
);

CREATE POLICY "crop_images_insert_crop_owner"
ON public.crop_images
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND c.farmer_id = (SELECT auth.uid())
  )
);

CREATE POLICY "crop_images_delete_crop_owner"
ON public.crop_images
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND c.farmer_id = (SELECT auth.uid())
  )
);

REVOKE ALL ON public.crop_images FROM anon;
GRANT SELECT ON public.crop_images TO anon;
REVOKE ALL ON public.crop_images FROM authenticated;
GRANT SELECT, INSERT, DELETE ON public.crop_images TO authenticated;

-- profiles: conceder SELECT, INSERT y UPDATE
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- 6.3. Privilegios predeterminados acotados (Cierre del Hallazgo B-01)
-- Revocar privilegios por omisión a anon para evitar exposición automática de futuras tablas internas.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;


-- ============================================================================
-- 7. PROTECCIÓN DE CONCURRENCIA: ÍNDICE ÚNICO PARCIAL (Aclaración A-01)
-- ============================================================================

-- NOTA TÉCNICA DE CONCURRENCIA:
-- 1. La creación de propuestas no reserva inventario (no incrementa stock_committed),
--    permitiendo el libre descubrimiento de precios sin retenciones prematuras de stock.
-- 2. Este índice único parcial garantiza que un MISMO comprador no pueda duplicar negociaciones
--    activas concurrentes sobre la misma cosecha (prevención de carreras por doble click).
-- 3. La prevención de sobreventas entre COMPRADORES DISTINTOS se delega a la transacción
--    de aceptación ('acordada'), donde se ejecutará un SELECT ... FOR UPDATE sobre crops
--    y se incrementará stock_committed dentro del mismo bloque transaccional.
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_active_negotiation_per_buyer
ON public.negotiations (crop_id, buyer_id)
WHERE status IN (
    'propuesta'::public.negotiation_status,
    'contraofertada'::public.negotiation_status,
    'acordada'::public.negotiation_status
);


-- ============================================================================
-- 8. FUNCIÓN TRANSACCIONAL RPC: create_negotiation_with_offer
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_negotiation_with_offer(
    p_crop_id uuid,
    p_quantity_kg numeric,
    p_proposed_price_per_kg numeric,
    p_delivery_method public.delivery_method,
    p_message text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id uuid;
    v_buyer_profile record;
    v_crop record;
    v_available_stock numeric;
    v_negotiation_id uuid;
    v_offer_id uuid;
    v_now timestamptz := clock_timestamp();
    v_result jsonb;
BEGIN
    -- 1. Validar autenticación obligatoria
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Validar que el comprador exista, esté verificado/aprobado y tenga rol comprador
    SELECT id, role, verification_status
    INTO v_buyer_profile
    FROM public.profiles
    WHERE id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El perfil del usuario no existe en la base de datos' USING ERRCODE = 'P0002';
    END IF;

    IF v_buyer_profile.verification_status IS DISTINCT FROM 'aprobado'::public.user_verification_status THEN
        RAISE EXCEPTION 'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales' USING ERRCODE = '42501';
    END IF;

    IF v_buyer_profile.role IS DISTINCT FROM 'comprador'::public.user_role THEN
        RAISE EXCEPTION 'Solo los usuarios con rol de comprador pueden iniciar negociaciones' USING ERRCODE = '42501';
    END IF;

    -- 3. Validar consistencia de parámetros numéricos
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    IF p_proposed_price_per_kg IS NULL OR p_proposed_price_per_kg <= 0 THEN
        RAISE EXCEPTION 'El precio propuesto debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    -- 4. Validación del cultivo y lectura consistente de stock
    -- Bloqueo compartido (FOR SHARE) para garantizar lectura no alterada durante la validación
    SELECT 
        id, farmer_id, stock_total, stock_committed, stock_sold, min_order_kg, status
    INTO 
        v_crop
    FROM public.crops
    WHERE id = p_crop_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo especificado no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Comprador distinto del agricultor (evita auto-negociación)
    IF v_crop.farmer_id = v_user_id THEN
        RAISE EXCEPTION 'No puedes iniciar una negociación sobre tu propio cultivo' USING ERRCODE = '42501';
    END IF;

    -- 6. Cultivo en estado activo
    IF v_crop.status IS DISTINCT FROM 'activa'::public.crop_status THEN
        RAISE EXCEPTION 'El cultivo no se encuentra activo para recibir ofertas (estado actual: %)', v_crop.status USING ERRCODE = '22000';
    END IF;

    -- 7. Validación de pedido mínimo y stock disponible
    -- stock_disponible = stock_total - stock_committed - stock_sold
    v_available_stock := GREATEST(0, (v_crop.stock_total - COALESCE(v_crop.stock_committed, 0) - COALESCE(v_crop.stock_sold, 0)));

    IF p_quantity_kg < COALESCE(v_crop.min_order_kg, 1) THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) no cumple con el pedido mínimo permitido (% kg)', 
            p_quantity_kg, v_crop.min_order_kg USING ERRCODE = '22000';
    END IF;

    IF p_quantity_kg > v_available_stock THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) supera el stock disponible (% kg)', 
            p_quantity_kg, v_available_stock USING ERRCODE = '22000';
    END IF;

    -- 8. Validación de negociación activa previa
    IF EXISTS (
        SELECT 1 FROM public.negotiations
        WHERE crop_id = p_crop_id
          AND buyer_id = v_user_id
          AND status IN (
              'propuesta'::public.negotiation_status,
              'contraofertada'::public.negotiation_status,
              'acordada'::public.negotiation_status
          )
    ) THEN
        RAISE EXCEPTION 'Ya tienes una negociación activa para este cultivo' USING ERRCODE = '23505';
    END IF;

    -- 9. Inserción atómica en negotiations (permitida por ser función SECURITY DEFINER)
    INSERT INTO public.negotiations (
        crop_id,
        buyer_id,
        status,
        current_responder,
        created_at,
        updated_at
    ) VALUES (
        p_crop_id,
        v_user_id,
        'propuesta'::public.negotiation_status,
        'agricultor'::public.user_role,
        v_now,
        v_now
    ) RETURNING id INTO v_negotiation_id;

    -- 10. Inserción atómica en negotiation_offers
    INSERT INTO public.negotiation_offers (
        negotiation_id,
        sender_id,
        quantity_kg,
        proposed_price_per_kg,
        delivery_method,
        message,
        created_at
    ) VALUES (
        v_negotiation_id,
        v_user_id,
        p_quantity_kg,
        p_proposed_price_per_kg,
        p_delivery_method,
        NULLIF(TRIM(p_message), ''),
        v_now
    ) RETURNING id INTO v_offer_id;

    -- 11. Retorno estructurado
    v_result := jsonb_build_object(
        'success', true,
        'id', v_negotiation_id,
        'crop_id', p_crop_id,
        'buyer_id', v_user_id,
        'status', 'propuesta',
        'current_responder', 'agricultor',
        'created_at', v_now,
        'updated_at', v_now,
        'initial_offer_id', v_offer_id
    );

    RETURN v_result;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya tienes una negociación activa para este cultivo' USING ERRCODE = '23505';
END;
$$;

-- Propietario y permisos mínimos de ejecución
ALTER FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) TO authenticated;

COMMIT;
