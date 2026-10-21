-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261020200000_inventory_lifecycle_resilience_and_reconciliation.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Robustecimiento del ciclo de inventario (Fase 4.3):
--           1. Reactivación automática del cultivo a 'activa' al liberar reservas en
--              reject_or_cancel_negotiation si el cultivo estaba en 'agotada' y recupera stock disponible.
--           2. Verificación contable defensiva en complete_negotiation para prevenir sub-desbordamiento silencioso.
--           3. Preservación estricta de atomicidad, bloqueos FOR UPDATE, permisos y transiciones.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. ROBUSTEZ Y REACTIVACIÓN DE STOCK EN reject_or_cancel_negotiation
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
    v_new_committed numeric := 0;
    v_new_available numeric := 0;
    v_new_crop_status public.crop_status;
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
            SELECT id, stock_total, stock_committed, stock_sold, status
            INTO v_crop
            FROM public.crops
            WHERE id = v_neg.crop_id
            FOR UPDATE;

            IF FOUND THEN
                IF v_crop.stock_committed < v_released_kg THEN
                    RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) menor que la reserva a liberar (%)',
                        v_crop.stock_committed, v_released_kg USING ERRCODE = '22000';
                END IF;

                v_new_committed := v_crop.stock_committed - v_released_kg;
                v_new_available := v_crop.stock_total - v_new_committed - COALESCE(v_crop.stock_sold, 0);

                -- Reactivación automática si estaba 'agotada' y recupera stock disponible
                v_new_crop_status := CASE
                    WHEN v_crop.status = 'agotada'::public.crop_status AND v_new_available > 0 THEN 'activa'::public.crop_status
                    ELSE v_crop.status
                END;

                UPDATE public.crops
                SET stock_committed = v_new_committed,
                    status = v_new_crop_status,
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
GRANT EXECUTE ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) TO authenticated;


-- ============================================================================
-- 2. VERIFICACIÓN DEFENSIVA Y CONVERSIÓN EN complete_negotiation
-- ============================================================================

CREATE OR REPLACE FUNCTION public.complete_negotiation(
    p_negotiation_id uuid
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
    v_new_committed numeric;
    v_new_sold numeric;
    v_available_remaining numeric;
    v_new_crop_status public.crop_status;
    v_movement_id uuid;
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
    SELECT n.id, n.crop_id, n.buyer_id, n.status, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Validar participantes
    IF v_user_id NOT IN (v_neg.buyer_id, v_neg.farmer_id) THEN
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 5. Validar estado permitido
    IF v_neg.status IS DISTINCT FROM 'acordada'::public.negotiation_status THEN
        RAISE EXCEPTION 'Solo se pueden completar negociaciones que se encuentren en estado acordada (estado actual: %)', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 6. Obtener última oferta acordada
    SELECT id, quantity_kg, proposed_price_per_kg
    INTO v_latest_offer
    FROM public.negotiation_offers
    WHERE negotiation_id = p_negotiation_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No hay ofertas registradas en esta negociación' USING ERRCODE = '22000';
    END IF;

    -- 7. Bloqueo EXCLUSIVO de fila en crops (FOR UPDATE)
    SELECT id, stock_total, stock_committed, stock_sold, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo asociado a la negociación no existe' USING ERRCODE = 'P0002';
    END IF;

    -- Validación contable defensiva: stock_committed no puede ser menor a la cantidad pactada
    IF COALESCE(v_crop.stock_committed, 0) < v_latest_offer.quantity_kg THEN
        RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) menor que la cantidad acordada (%)',
            v_crop.stock_committed, v_latest_offer.quantity_kg USING ERRCODE = '22000';
    END IF;

    -- 8. Calcular conversión de stock: committed -> sold
    v_new_committed := v_crop.stock_committed - v_latest_offer.quantity_kg;
    v_new_sold := COALESCE(v_crop.stock_sold, 0) + v_latest_offer.quantity_kg;
    v_available_remaining := v_crop.stock_total - v_new_committed - v_new_sold;

    v_new_crop_status := CASE
        WHEN v_available_remaining <= 0 THEN 'agotada'::public.crop_status
        ELSE v_crop.status
    END;

    -- 9. Actualizar crops
    UPDATE public.crops
    SET stock_committed = v_new_committed,
        stock_sold = v_new_sold,
        status = v_new_crop_status,
        updated_at = v_now
    WHERE id = v_crop.id;

    -- 10. Registrar movimiento contable de venta en inventory_movements
    -- OBLIGATORIO: Si falla, toda la transacción se revierte
    INSERT INTO public.inventory_movements (
        crop_id,
        negotiation_id,
        movement_type,
        quantity_kg,
        created_at
    ) VALUES (
        v_crop.id,
        p_negotiation_id,
        'venta'::public.inventory_movement_type,
        v_latest_offer.quantity_kg,
        v_now
    ) RETURNING id INTO v_movement_id;

    -- 11. Actualizar estado de negociación a 'completada'
    UPDATE public.negotiations
    SET status = 'completada'::public.negotiation_status,
        current_responder = NULL,
        updated_at = v_now
    WHERE id = p_negotiation_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', p_negotiation_id,
        'negotiation_id', p_negotiation_id,
        'status', 'completada',
        'sold_kg', v_latest_offer.quantity_kg,
        'movement_id', v_movement_id,
        'crop_status', v_new_crop_status::text,
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.complete_negotiation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_negotiation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_negotiation(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_negotiation(uuid) TO authenticated;

COMMIT;
