-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261016200000_commercial_security_and_integrity_audit_fixes.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Corrección integral de seguridad, RLS, permisos mínimos y restricciones
--           de integridad comercial derivadas de la auditoría de los seis escenarios:
--           1. Protección de profiles contra auto-aprobación y escalada a moderador.
--           2. Cierre de bypasses de turno y stock en negotiation_offers y negotiations.
--           3. Restricciones CHECK en crops e inventory_movements (stock >= 0, etc.).
--           4. Trigger de defensa en profundidad contra auto-negociación en negotiations.
--           5. Conciliación y liberación exacta en reject_or_cancel_negotiation.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. PROTECCIÓN DE PERFILES: PREVENIR AUTO-APROBACIÓN Y ESCALADA DE PRIVILEGIOS
-- ============================================================================

-- 1.1. Trigger de protección en profiles para clientes authenticated / anon
CREATE OR REPLACE FUNCTION public.protect_profiles_security_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF TG_OP = 'INSERT' THEN
      -- Un usuario que se registra no puede auto-aprobarse
      IF NEW.verification_status IS DISTINCT FROM 'pendiente'::public.user_verification_status THEN
        RAISE EXCEPTION 'No está permitido auto-aprobarse o alterar el estado de verificación inicial' USING ERRCODE = '42501';
      END IF;
      -- No permitir auto-asignarse rol moderador
      IF NEW.role = 'moderador'::public.user_role THEN
        RAISE EXCEPTION 'No está permitido auto-asignarse el rol de moderador' USING ERRCODE = '42501';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      -- Prohibir modificar verification_status desde cliente
      IF NEW.verification_status IS DISTINCT FROM OLD.verification_status THEN
        RAISE EXCEPTION 'No está permitido modificar directamente el estado de verificación' USING ERRCODE = '42501';
      END IF;
      -- Prohibir modificar id
      IF NEW.id IS DISTINCT FROM OLD.id THEN
        RAISE EXCEPTION 'El identificador del perfil es inmutable' USING ERRCODE = '42501';
      END IF;
      -- Prohibir escalar a rol moderador
      IF NEW.role IS DISTINCT FROM OLD.role AND NEW.role = 'moderador'::public.user_role THEN
        RAISE EXCEPTION 'No está permitido auto-asignarse el rol de moderador' USING ERRCODE = '42501';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profiles_security_fields ON public.profiles;
CREATE TRIGGER trg_protect_profiles_security_fields
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_profiles_security_fields();

-- 1.2. Restricción estricta de privilegios de columna en profiles para authenticated
REVOKE ALL ON public.profiles FROM authenticated;
GRANT SELECT, INSERT ON public.profiles TO authenticated;
GRANT UPDATE (
  phone,
  full_name,
  email,
  profile_path,
  updated_at
) ON public.profiles TO authenticated;


-- ============================================================================
-- 2. PROTECCIÓN CONTRA MODIFICACIONES DIRECTAS Y SALTO DE TURNO EN NEGOCIACIONES
-- ============================================================================

-- 2.1. negotiation_offers: revocar INSERT directo a authenticated
-- Todas las ofertas deben registrarse EXCLUSIVAMENTE mediante las RPCs:
-- create_negotiation_with_offer (propuesta inicial) y counter_offer (contraofertas).
DROP POLICY IF EXISTS "negotiation_offers_insert_sender" ON public.negotiation_offers;
REVOKE INSERT, UPDATE, DELETE ON public.negotiation_offers FROM authenticated;
GRANT SELECT ON public.negotiation_offers TO authenticated;

-- 2.2. negotiations: revocar UPDATE y DELETE directos a authenticated
-- Todas las transiciones de estado deben realizarse EXCLUSIVAMENTE mediante las RPCs:
-- counter_offer, accept_negotiation, complete_negotiation, reject_negotiation, cancel_negotiation.
DROP POLICY IF EXISTS "negotiations_update_participants" ON public.negotiations;
DROP POLICY IF EXISTS "negotiations_delete_rollback" ON public.negotiations;
REVOKE UPDATE, DELETE ON public.negotiations FROM authenticated;
GRANT SELECT ON public.negotiations TO authenticated;

-- 2.3. Trigger de integridad en negotiations para prevenir auto-negociación (defensa en profundidad)
CREATE OR REPLACE FUNCTION public.validate_negotiation_integrity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_farmer_id uuid;
BEGIN
    SELECT farmer_id INTO v_farmer_id FROM public.crops WHERE id = NEW.crop_id;
    IF v_farmer_id IS NOT NULL AND v_farmer_id = NEW.buyer_id THEN
        RAISE EXCEPTION 'No puedes iniciar una negociación sobre tu propio cultivo' USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_negotiation_integrity ON public.negotiations;
CREATE TRIGGER trg_validate_negotiation_integrity
BEFORE INSERT OR UPDATE ON public.negotiations
FOR EACH ROW
EXECUTE FUNCTION public.validate_negotiation_integrity();


-- ============================================================================
-- 3. RESTRICCIONES DE INTEGRIDAD Y REGLAS DE NEGOCIO EN CROPS E INVENTARIO
-- ============================================================================

-- 3.1. Restricciones CHECK en crops
ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_stock_committed_non_negative,
  ADD CONSTRAINT chk_crops_stock_committed_non_negative CHECK (stock_committed >= 0);

ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_stock_sold_non_negative,
  ADD CONSTRAINT chk_crops_stock_sold_non_negative CHECK (stock_sold >= 0);

ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_stock_total_valid,
  ADD CONSTRAINT chk_crops_stock_total_valid CHECK (stock_total >= (COALESCE(stock_committed, 0) + COALESCE(stock_sold, 0)));

ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_price_positive,
  ADD CONSTRAINT chk_crops_price_positive CHECK (price_per_kg > 0);

ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_min_order_positive,
  ADD CONSTRAINT chk_crops_min_order_positive CHECK (min_order_kg > 0);

-- 3.2. Restricciones CHECK en inventory_movements
ALTER TABLE public.inventory_movements
  DROP CONSTRAINT IF EXISTS chk_inventory_movements_qty_positive,
  ADD CONSTRAINT chk_inventory_movements_qty_positive CHECK (quantity_kg > 0);

-- 3.3. Restricciones CHECK en negotiation_offers
ALTER TABLE public.negotiation_offers
  DROP CONSTRAINT IF EXISTS chk_negotiation_offers_qty_positive,
  ADD CONSTRAINT chk_negotiation_offers_qty_positive CHECK (quantity_kg > 0);

ALTER TABLE public.negotiation_offers
  DROP CONSTRAINT IF EXISTS chk_negotiation_offers_price_positive,
  ADD CONSTRAINT chk_negotiation_offers_price_positive CHECK (proposed_price_per_kg > 0);


-- ============================================================================
-- 4. ROBUSTEZ Y CONCILIACIÓN EXACTA EN reject_or_cancel_negotiation
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reject_or_cancel_negotiation(
    p_negotiation_id uuid,
    p_target_status public.negotiation_status,
    p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id uuid;
    v_profile record;
    v_neg record;
    v_crop record;
    v_caller_role public.user_role;
    v_movement_id uuid := NULL;
    v_released_kg numeric := 0;
    v_net_reserved numeric := 0;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Validar autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Validar perfil verificado y aprobado
    SELECT id, verification_status
    INTO v_profile
    FROM public.profiles
    WHERE id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El perfil del usuario no existe en la base de datos' USING ERRCODE = 'P0002';
    END IF;

    IF v_profile.verification_status IS DISTINCT FROM 'aprobado'::public.user_verification_status THEN
        RAISE EXCEPTION 'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales' USING ERRCODE = '42501';
    END IF;

    -- 3. Bloqueo de fila y lectura de negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Validar participantes
    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 5. Validar estado permitido: no terminal
    IF v_neg.status IN ('completada'::public.negotiation_status, 'rechazada'::public.negotiation_status, 'cancelada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'La negociación ya se encuentra cerrada (estado actual: %)', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 6. Validaciones específicas según acción
    IF p_target_status = 'rechazada'::public.negotiation_status THEN
        IF v_neg.status IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
            IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
                RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
            END IF;
        END IF;
    ELSIF p_target_status = 'cancelada'::public.negotiation_status THEN
        IF v_neg.status = 'propuesta'::public.negotiation_status AND v_caller_role IS DISTINCT FROM 'comprador'::public.user_role THEN
            RAISE EXCEPTION 'Solo el comprador proponente puede cancelar una propuesta inicial' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- 7. Si el trato estaba 'acordada', liberar exactamente el inventario reservado
    IF v_neg.status = 'acordada'::public.negotiation_status THEN
        -- Calcular el saldo neto reservado contablemente para esta negociación
        SELECT COALESCE(
            SUM(CASE 
                WHEN movement_type = 'reserva' THEN quantity_kg 
                WHEN movement_type = 'liberacion_reserva' THEN -quantity_kg 
                ELSE 0 
            END), 0)
        INTO v_net_reserved
        FROM public.inventory_movements
        WHERE negotiation_id = p_negotiation_id;

        IF v_net_reserved > 0 THEN
            v_released_kg := v_net_reserved;

            -- Bloqueo EXCLUSIVO de fila en crops (FOR UPDATE)
            SELECT id, stock_committed
            INTO v_crop
            FROM public.crops
            WHERE id = v_neg.crop_id
            FOR UPDATE;

            IF FOUND THEN
                IF v_crop.stock_committed < v_released_kg THEN
                    RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) menor que la reserva a liberar (%)',
                        v_crop.stock_committed, v_released_kg USING ERRCODE = '22000';
                END IF;

                UPDATE public.crops
                SET stock_committed = stock_committed - v_released_kg,
                    updated_at = v_now
                WHERE id = v_crop.id;

                -- Registrar movimiento contable de liberación de reserva
                INSERT INTO public.inventory_movements (
                    crop_id,
                    negotiation_id,
                    movement_type,
                    quantity_kg,
                    created_at
                ) VALUES (
                    v_crop.id,
                    p_negotiation_id,
                    'liberacion_reserva'::public.inventory_movement_type,
                    v_released_kg,
                    v_now
                ) RETURNING id INTO v_movement_id;
            END IF;
        END IF;
    END IF;

    -- 8. Actualizar estado de negociación a target_status
    UPDATE public.negotiations
    SET status = p_target_status,
        current_responder = NULL,
        updated_at = v_now
    WHERE id = p_negotiation_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', p_negotiation_id,
        'negotiation_id', p_negotiation_id,
        'status', p_target_status::text,
        'released_kg', v_released_kg,
        'movement_id', v_movement_id,
        'reason', NULLIF(TRIM(p_reason), ''),
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) FROM anon;

COMMIT;
