-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261016190000_commercial_cycle_closing_rpcs.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: RPCs transaccionales para el ciclo comercial de tratos:
--           1. Contraofertar (counter_offer)
--           2. Aceptar oferta y reservar inventario (accept_negotiation)
--           3. Completar trato y registrar venta (complete_negotiation)
--           4. Rechazar trato y liberar reserva si correspondía (reject_negotiation)
--           5. Cancelar propuesta y liberar reserva si correspondía (cancel_negotiation)
-- SEGURIDAD: SECURITY DEFINER, SET search_path = public, pg_temp
--            Validación en servidor de identidad, participantes, estado permitido,
--            turno de respuesta, valores positivos y stock disponible con bloqueos
--            exclusivos (FOR UPDATE) y reversión transaccional completa si falla
--            el registro en inventory_movements.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. RPC: counter_offer
-- ============================================================================
CREATE OR REPLACE FUNCTION public.counter_offer(
    p_negotiation_id uuid,
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
    v_profile record;
    v_neg record;
    v_crop record;
    v_available_stock numeric;
    v_caller_role public.user_role;
    v_next_responder public.user_role;
    v_offer_id uuid;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Validar autenticación obligatoria
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Validar perfil verificado y aprobado
    SELECT id, verification_status, role
    INTO v_profile
    FROM public.profiles
    WHERE id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El perfil del usuario no existe en la base de datos' USING ERRCODE = 'P0002';
    END IF;

    IF v_profile.verification_status IS DISTINCT FROM 'aprobado'::public.user_verification_status THEN
        RAISE EXCEPTION 'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales' USING ERRCODE = '42501';
    END IF;

    -- 3. Validar consistencia de valores numéricos positivos
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    IF p_proposed_price_per_kg IS NULL OR p_proposed_price_per_kg <= 0 THEN
        RAISE EXCEPTION 'El precio propuesto debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    -- 4. Bloqueo de fila y lectura de negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Validar pertenencia de participantes y alternancia de turnos
    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
        v_next_responder := 'agricultor'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
        v_next_responder := 'comprador'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 6. Validar estado permitido
    IF v_neg.status NOT IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'No se pueden enviar contraofertas en una negociación en estado %', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 7. Validar turno de respuesta
    IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
        RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 8. Validar cultivo y stock disponible con bloqueo FOR SHARE
    SELECT id, stock_total, stock_committed, stock_sold, min_order_kg, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo especificado no existe' USING ERRCODE = 'P0002';
    END IF;

    IF v_crop.status IS DISTINCT FROM 'activa'::public.crop_status THEN
        RAISE EXCEPTION 'El cultivo no se encuentra activo para recibir contraofertas (estado actual: %)', v_crop.status USING ERRCODE = '22000';
    END IF;

    v_available_stock := GREATEST(0, (v_crop.stock_total - COALESCE(v_crop.stock_committed, 0) - COALESCE(v_crop.stock_sold, 0)));

    IF p_quantity_kg < COALESCE(v_crop.min_order_kg, 1) THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) no cumple con el pedido mínimo permitido (% kg)',
            p_quantity_kg, v_crop.min_order_kg USING ERRCODE = '22000';
    END IF;

    IF p_quantity_kg > v_available_stock THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) supera el stock disponible (% kg)',
            p_quantity_kg, v_available_stock USING ERRCODE = '22000';
    END IF;

    -- 9. Inserción atómica de la nueva oferta
    INSERT INTO public.negotiation_offers (
        negotiation_id,
        sender_id,
        quantity_kg,
        proposed_price_per_kg,
        delivery_method,
        message,
        created_at
    ) VALUES (
        p_negotiation_id,
        v_user_id,
        p_quantity_kg,
        p_proposed_price_per_kg,
        p_delivery_method,
        NULLIF(TRIM(p_message), ''),
        v_now
    ) RETURNING id INTO v_offer_id;

    -- 10. Actualización de estado y turno en negotiations
    UPDATE public.negotiations
    SET status = 'contraofertada'::public.negotiation_status,
        current_responder = v_next_responder,
        updated_at = v_now
    WHERE id = p_negotiation_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', p_negotiation_id,
        'negotiation_id', p_negotiation_id,
        'offer_id', v_offer_id,
        'status', 'contraofertada',
        'current_responder', v_next_responder::text,
        'updated_at', v_now
    );
END;
$$;


-- ============================================================================
-- 2. RPC: accept_negotiation
-- ============================================================================
CREATE OR REPLACE FUNCTION public.accept_negotiation(
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
    v_available_stock numeric;
    v_caller_role public.user_role;
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

    -- 5. Validar estado permitido
    IF v_neg.status = 'acordada'::public.negotiation_status THEN
        RAISE EXCEPTION 'La negociación ya fue acordada previamente' USING ERRCODE = '22000';
    END IF;

    IF v_neg.status NOT IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'No se puede aceptar una negociación en estado %', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 6. Validar turno de respuesta
    IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
        RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 7. Obtener la última oferta registrada
    SELECT id, sender_id, quantity_kg, proposed_price_per_kg, delivery_method
    INTO v_latest_offer
    FROM public.negotiation_offers
    WHERE negotiation_id = p_negotiation_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No hay ofertas registradas en esta negociación' USING ERRCODE = '22000';
    END IF;

    IF v_latest_offer.sender_id = v_user_id THEN
        RAISE EXCEPTION 'No puedes aceptar tu propia oferta' USING ERRCODE = '42501';
    END IF;

    -- 8. Bloqueo EXCLUSIVO de fila en crops (FOR UPDATE)
    SELECT id, stock_total, stock_committed, stock_sold, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo asociado a la negociación no existe' USING ERRCODE = 'P0002';
    END IF;

    IF v_crop.status IS DISTINCT FROM 'activa'::public.crop_status THEN
        RAISE EXCEPTION 'El cultivo no se encuentra activo para acordar ventas (estado actual: %)', v_crop.status USING ERRCODE = '22000';
    END IF;

    -- 9. Validación atómica de stock disponible
    v_available_stock := GREATEST(0, (v_crop.stock_total - COALESCE(v_crop.stock_committed, 0) - COALESCE(v_crop.stock_sold, 0)));

    IF v_latest_offer.quantity_kg > v_available_stock THEN
        RAISE EXCEPTION 'Stock disponible insuficiente (% kg) para reservar % kg pactados',
            v_available_stock, v_latest_offer.quantity_kg USING ERRCODE = '22000';
    END IF;

    -- 10. Reservar inventario en crops (incrementar stock_committed)
    UPDATE public.crops
    SET stock_committed = COALESCE(stock_committed, 0) + v_latest_offer.quantity_kg,
        updated_at = v_now
    WHERE id = v_crop.id;

    -- 11. Registrar movimiento contable de reserva en inventory_movements
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
        'reserva'::public.inventory_movement_type,
        v_latest_offer.quantity_kg,
        v_now
    ) RETURNING id INTO v_movement_id;

    -- 12. Actualizar estado de negociación a 'acordada'
    UPDATE public.negotiations
    SET status = 'acordada'::public.negotiation_status,
        current_responder = NULL,
        updated_at = v_now
    WHERE id = p_negotiation_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', p_negotiation_id,
        'negotiation_id', p_negotiation_id,
        'status', 'acordada',
        'reserved_kg', v_latest_offer.quantity_kg,
        'movement_id', v_movement_id,
        'updated_at', v_now
    );
END;
$$;


-- ============================================================================
-- 3. RPC: complete_negotiation
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

    -- 8. Calcular conversión de stock: committed -> sold
    v_new_committed := GREATEST(0, COALESCE(v_crop.stock_committed, 0) - v_latest_offer.quantity_kg);
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


-- ============================================================================
-- 4. FUNCIÓN INTERNA WORKER: reject_or_cancel_negotiation
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
    v_latest_offer record;
    v_caller_role public.user_role;
    v_movement_id uuid := NULL;
    v_released_kg numeric := 0;
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

    -- 7. Si el trato estaba 'acordada', liberar el inventario reservado
    IF v_neg.status = 'acordada'::public.negotiation_status THEN
        SELECT id, quantity_kg
        INTO v_latest_offer
        FROM public.negotiation_offers
        WHERE negotiation_id = p_negotiation_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF FOUND AND v_latest_offer.quantity_kg > 0 THEN
            v_released_kg := v_latest_offer.quantity_kg;

            -- Bloqueo EXCLUSIVO de fila en crops
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


-- ============================================================================
-- 5. RPC: reject_negotiation
-- ============================================================================
CREATE OR REPLACE FUNCTION public.reject_negotiation(
    p_negotiation_id uuid,
    p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN public.reject_or_cancel_negotiation(
        p_negotiation_id,
        'rechazada'::public.negotiation_status,
        p_reason
    );
END;
$$;


-- ============================================================================
-- 6. RPC: cancel_negotiation
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cancel_negotiation(
    p_negotiation_id uuid,
    p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN public.reject_or_cancel_negotiation(
        p_negotiation_id,
        'cancelada'::public.negotiation_status,
        p_reason
    );
END;
$$;


-- ============================================================================
-- 7. ASIGNACIÓN DE PROPIEDAD Y PRIVILEGIOS MÍNIMOS
-- ============================================================================
ALTER FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) TO authenticated;

ALTER FUNCTION public.accept_negotiation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.accept_negotiation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accept_negotiation(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.accept_negotiation(uuid) TO authenticated;

ALTER FUNCTION public.complete_negotiation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_negotiation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_negotiation(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_negotiation(uuid) TO authenticated;

ALTER FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) FROM anon;

ALTER FUNCTION public.reject_negotiation(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reject_negotiation(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_negotiation(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.reject_negotiation(uuid, text) TO authenticated;

ALTER FUNCTION public.cancel_negotiation(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.cancel_negotiation(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_negotiation(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.cancel_negotiation(uuid, text) TO authenticated;

COMMIT;
