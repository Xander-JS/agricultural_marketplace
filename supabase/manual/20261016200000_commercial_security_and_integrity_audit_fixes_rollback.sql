-- ============================================================================
-- SCRIPT DE ROLLBACK: 20261016200000_commercial_security_and_integrity_audit_fixes_rollback.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Reversión controlada de la migración 20261016200000 al estado exacto
--           de la migración 20261016190000_commercial_cycle_closing_rpcs.sql
--           sin eliminar tablas ni objetos preexistentes.
-- ============================================================================

BEGIN;

-- 1. Eliminar trigger y función de perfiles, y restaurar privilegios de actualización
DROP TRIGGER IF EXISTS trg_protect_profiles_security_fields ON public.profiles;
DROP FUNCTION IF EXISTS public.protect_profiles_security_fields();
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- 2. Eliminar trigger de integridad de auto-negociación en negotiations
DROP TRIGGER IF EXISTS trg_validate_negotiation_integrity ON public.negotiations;
DROP FUNCTION IF EXISTS public.validate_negotiation_integrity();

-- 3. Restaurar permisos y políticas previas en negotiation_offers
GRANT INSERT ON public.negotiation_offers TO authenticated;

DROP POLICY IF EXISTS "negotiation_offers_insert_sender" ON public.negotiation_offers;
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

-- 4. Restaurar permisos y políticas previas en negotiations
GRANT UPDATE, DELETE ON public.negotiations TO authenticated;

DROP POLICY IF EXISTS "negotiations_update_participants" ON public.negotiations;
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

DROP POLICY IF EXISTS "negotiations_delete_rollback" ON public.negotiations;
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

-- 5. Eliminar restricciones CHECK añadidas
ALTER TABLE public.crops
  DROP CONSTRAINT IF EXISTS chk_crops_stock_committed_non_negative,
  DROP CONSTRAINT IF EXISTS chk_crops_stock_sold_non_negative,
  DROP CONSTRAINT IF EXISTS chk_crops_stock_total_valid,
  DROP CONSTRAINT IF EXISTS chk_crops_price_positive,
  DROP CONSTRAINT IF EXISTS chk_crops_min_order_positive;

ALTER TABLE public.inventory_movements
  DROP CONSTRAINT IF EXISTS chk_inventory_movements_qty_positive;

ALTER TABLE public.negotiation_offers
  DROP CONSTRAINT IF EXISTS chk_negotiation_offers_qty_positive,
  DROP CONSTRAINT IF EXISTS chk_negotiation_offers_price_positive;

-- 6. Restaurar versión previa de reject_or_cancel_negotiation de la migración 20261016190000
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
    v_latest_offer record;
    v_caller_role public.user_role;
    v_movement_id uuid := NULL;
    v_released_kg numeric := 0;
    v_now timestamptz := clock_timestamp();
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

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

    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    IF v_neg.status IN ('completada'::public.negotiation_status, 'rechazada'::public.negotiation_status, 'cancelada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'La negociación ya se encuentra cerrada (estado actual: %)', v_neg.status USING ERRCODE = '22000';
    END IF;

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

    IF v_neg.status = 'acordada'::public.negotiation_status THEN
        SELECT id, quantity_kg
        INTO v_latest_offer
        FROM public.negotiation_offers
        WHERE negotiation_id = p_negotiation_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF FOUND AND v_latest_offer.quantity_kg > 0 THEN
            v_released_kg := v_latest_offer.quantity_kg;

            SELECT id, stock_committed
            INTO v_crop
            FROM public.crops
            WHERE id = v_neg.crop_id
            FOR UPDATE;

            IF FOUND THEN
                UPDATE public.crops
                SET stock_committed = GREATEST(0, COALESCE(stock_committed, 0) - v_released_kg),
                    updated_at = v_now
                WHERE id = v_crop.id;

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

COMMIT;
