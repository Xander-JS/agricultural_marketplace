-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261020210000_proposal_time_inventory_reservation.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Reserva de inventario desde la propuesta inicial:
--           1. create_negotiation_with_offer reserva stock_committed de forma atómica.
--           2. counter_offer ajusta exactamente la reserva neta de la negociación
--              (reserva la diferencia o libera el excedente).
--           3. accept_negotiation no vuelve a reservar si la propuesta ya reservó;
--              sólo completa la reserva en negociaciones heredadas sin movimientos.
--           4. complete_negotiation convierte la reserva neta en venta exactamente
--              una vez y aborta si la reserva es insuficiente.
--           5. reject_or_cancel_negotiation libera únicamente la reserva neta real,
--              en cualquier estado activo, y reactiva cultivos agotados si aplica.
--           6. El estado del cultivo ('activa' / 'agotada') refleja la disponibilidad.
--           7. Los compradores pueden seguir leyendo el cultivo asociado a su trato
--              aunque éste haya quedado 'agotada'.
-- SEGURIDAD: SECURITY DEFINER, SET search_path = public, pg_temp.
--            Bloqueo exclusivo FOR UPDATE sobre crops para serializar operaciones
--            concurrentes. Todas las mutaciones son atómicas.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. ÍNDICE DE APOYO PARA CONCILIAR RESERVAS POR NEGOCIACIÓN
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_inventory_movements_negotiation
  ON public.inventory_movements (negotiation_id);

-- ============================================================================
-- 2. FUNCIÓN INTERNA: RESERVA NETA CONTABLE DE UNA NEGOCIACIÓN
--    neta = SUM(reserva) - SUM(liberacion_reserva) - SUM(venta)
--    No se concede EXECUTE a roles cliente: sólo la usan las RPCs definer.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.negotiation_net_reserved_kg(
    p_negotiation_id uuid
)
RETURNS numeric
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE(SUM(
        CASE
            WHEN movement_type = 'reserva'::public.inventory_movement_type THEN quantity_kg
            WHEN movement_type IN (
                'liberacion_reserva'::public.inventory_movement_type,
                'venta'::public.inventory_movement_type
            ) THEN -quantity_kg
            ELSE 0
        END
    ), 0)
    FROM public.inventory_movements
    WHERE negotiation_id = p_negotiation_id;
$$;

ALTER FUNCTION public.negotiation_net_reserved_kg(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.negotiation_net_reserved_kg(uuid) FROM PUBLIC, anon, authenticated;

-- ============================================================================
-- 3. RPC: create_negotiation_with_offer
--    La propuesta inicial reserva stock de inmediato.
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
    v_negotiation_id uuid;
    v_offer_id uuid;
    v_movement_id uuid;
    v_available_stock numeric;
    v_new_committed numeric;
    v_new_available numeric;
    v_new_crop_status public.crop_status;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Autenticación obligatoria
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Perfil aprobado y rol comprador
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

    -- 3. Parámetros numéricos
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    IF p_proposed_price_per_kg IS NULL OR p_proposed_price_per_kg <= 0 THEN
        RAISE EXCEPTION 'El precio propuesto debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    -- 4. Bloqueo EXCLUSIVO del cultivo: serializa propuestas concurrentes
    SELECT id, farmer_id, stock_total, stock_committed, stock_sold, min_order_kg, status
    INTO v_crop
    FROM public.crops
    WHERE id = p_crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo especificado no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Comprador distinto del agricultor
    IF v_crop.farmer_id = v_user_id THEN
        RAISE EXCEPTION 'No puedes iniciar una negociación sobre tu propio cultivo' USING ERRCODE = '42501';
    END IF;

    -- 6. Cultivo activo
    IF v_crop.status IS DISTINCT FROM 'activa'::public.crop_status THEN
        RAISE EXCEPTION 'El cultivo no se encuentra activo para recibir ofertas (estado actual: %)', v_crop.status USING ERRCODE = '22000';
    END IF;

    -- 7. Negociación activa previa (antes de validar stock para conservar el
    --    error de duplicado ante dobles clics concurrentes)
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

    -- 8. Pedido mínimo y disponibilidad real
    v_available_stock := GREATEST(0, (
        v_crop.stock_total
        - COALESCE(v_crop.stock_committed, 0)
        - COALESCE(v_crop.stock_sold, 0)
    ));

    IF p_quantity_kg < COALESCE(v_crop.min_order_kg, 1) THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) no cumple con el pedido mínimo permitido (% kg)',
            p_quantity_kg, v_crop.min_order_kg USING ERRCODE = '22000';
    END IF;

    IF p_quantity_kg > v_available_stock THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) supera el stock disponible (% kg)',
            p_quantity_kg, v_available_stock USING ERRCODE = '22000';
    END IF;

    -- 9. Creación atómica de la negociación y su oferta inicial
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

    -- 10. Reserva de inventario desde la propuesta
    v_new_committed := COALESCE(v_crop.stock_committed, 0) + p_quantity_kg;
    v_new_available := v_crop.stock_total - v_new_committed - COALESCE(v_crop.stock_sold, 0);

    v_new_crop_status := CASE
        WHEN v_new_available <= 0 THEN 'agotada'::public.crop_status
        ELSE v_crop.status
    END;

    UPDATE public.crops
    SET stock_committed = v_new_committed,
        status = v_new_crop_status,
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
        v_negotiation_id,
        'reserva'::public.inventory_movement_type,
        p_quantity_kg,
        v_now
    ) RETURNING id INTO v_movement_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', v_negotiation_id,
        'crop_id', p_crop_id,
        'buyer_id', v_user_id,
        'status', 'propuesta',
        'current_responder', 'agricultor',
        'reserved_kg', p_quantity_kg,
        'movement_id', v_movement_id,
        'crop_status', v_new_crop_status::text,
        'created_at', v_now,
        'updated_at', v_now,
        'initial_offer_id', v_offer_id
    );
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya tienes una negociación activa para este cultivo' USING ERRCODE = '23505';
END;
$$;

ALTER FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_negotiation_with_offer(uuid, numeric, numeric, public.delivery_method, text) TO authenticated;

-- ============================================================================
-- 4. RPC: counter_offer
--    Ajusta la reserva neta al nuevo volumen ofertado.
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
    v_caller_role public.user_role;
    v_next_responder public.user_role;
    v_offer_id uuid;
    v_movement_id uuid := NULL;
    v_net_reserved numeric := 0;
    v_delta numeric := 0;
    v_available_stock numeric;
    v_new_committed numeric;
    v_new_available numeric;
    v_new_crop_status public.crop_status;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Perfil aprobado
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

    -- 3. Parámetros numéricos
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    IF p_proposed_price_per_kg IS NULL OR p_proposed_price_per_kg <= 0 THEN
        RAISE EXCEPTION 'El precio propuesto debe ser mayor a cero' USING ERRCODE = '22000';
    END IF;

    -- 4. Bloqueo de la negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Participantes y turno
    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
        v_next_responder := 'agricultor'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
        v_next_responder := 'comprador'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    IF v_neg.status NOT IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'No se pueden enviar contraofertas en una negociación en estado %', v_neg.status USING ERRCODE = '22000';
    END IF;

    IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
        RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 6. Bloqueo EXCLUSIVO del cultivo
    SELECT id, stock_total, stock_committed, stock_sold, min_order_kg, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo especificado no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 7. Reserva neta actual de esta negociación
    v_net_reserved := public.negotiation_net_reserved_kg(p_negotiation_id);

    -- 8. Estado del cultivo: una negociación con reserva vigente puede
    --    contraofertar aunque el cultivo esté 'agotada' por esa misma reserva.
    IF v_crop.status IS DISTINCT FROM 'activa'::public.crop_status
       AND v_net_reserved <= 0 THEN
        RAISE EXCEPTION 'El cultivo no se encuentra activo para recibir contraofertas (estado actual: %)', v_crop.status USING ERRCODE = '22000';
    END IF;

    IF p_quantity_kg < COALESCE(v_crop.min_order_kg, 1) THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) no cumple con el pedido mínimo permitido (% kg)',
            p_quantity_kg, v_crop.min_order_kg USING ERRCODE = '22000';
    END IF;

    -- 9. Ajuste de la reserva: sólo se necesita disponibilidad para el delta
    v_available_stock := GREATEST(0, (
        v_crop.stock_total
        - COALESCE(v_crop.stock_committed, 0)
        - COALESCE(v_crop.stock_sold, 0)
    ));
    v_delta := p_quantity_kg - v_net_reserved;

    IF v_delta > 0 AND v_delta > v_available_stock THEN
        RAISE EXCEPTION 'La cantidad solicitada (% kg) supera el stock disponible (% kg)',
            p_quantity_kg, v_available_stock + v_net_reserved USING ERRCODE = '22000';
    END IF;

    v_new_committed := COALESCE(v_crop.stock_committed, 0) + v_delta;

    IF v_new_committed < 0 THEN
        RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) insuficiente para liberar % kg',
            v_crop.stock_committed, (-v_delta) USING ERRCODE = '22000';
    END IF;

    v_new_available := v_crop.stock_total - v_new_committed - COALESCE(v_crop.stock_sold, 0);

    v_new_crop_status := CASE
        WHEN v_new_available <= 0 THEN 'agotada'::public.crop_status
        WHEN v_crop.status = 'agotada'::public.crop_status THEN 'activa'::public.crop_status
        ELSE v_crop.status
    END;

    UPDATE public.crops
    SET stock_committed = v_new_committed,
        status = v_new_crop_status,
        updated_at = v_now
    WHERE id = v_crop.id;

    -- 10. Movimiento contable del ajuste (sólo si cambió la reserva)
    IF v_delta > 0 THEN
        INSERT INTO public.inventory_movements (
            crop_id, negotiation_id, movement_type, quantity_kg, created_at
        ) VALUES (
            v_crop.id, p_negotiation_id, 'reserva'::public.inventory_movement_type, v_delta, v_now
        ) RETURNING id INTO v_movement_id;
    ELSIF v_delta < 0 THEN
        INSERT INTO public.inventory_movements (
            crop_id, negotiation_id, movement_type, quantity_kg, created_at
        ) VALUES (
            v_crop.id, p_negotiation_id, 'liberacion_reserva'::public.inventory_movement_type, -v_delta, v_now
        ) RETURNING id INTO v_movement_id;
    END IF;

    -- 11. Nueva oferta y transición de estado
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
        'reserved_kg', p_quantity_kg,
        'reservation_delta_kg', v_delta,
        'movement_id', v_movement_id,
        'crop_status', v_new_crop_status::text,
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.counter_offer(uuid, numeric, numeric, public.delivery_method, text) TO authenticated;

-- ============================================================================
-- 5. RPC: accept_negotiation
--    No duplica la reserva; sólo completa la diferencia (legacy) o libera
--    excedentes anómalos.
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
    v_caller_role public.user_role;
    v_net_reserved numeric := 0;
    v_delta numeric := 0;
    v_available_stock numeric;
    v_new_committed numeric;
    v_new_available numeric;
    v_new_crop_status public.crop_status;
    v_movement_id uuid := NULL;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Perfil aprobado
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

    -- 3. Bloqueo de la negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Participantes
    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 5. Estado permitido
    IF v_neg.status = 'acordada'::public.negotiation_status THEN
        RAISE EXCEPTION 'La negociación ya fue acordada previamente' USING ERRCODE = '22000';
    END IF;

    IF v_neg.status NOT IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
        RAISE EXCEPTION 'No se puede aceptar una negociación en estado %', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 6. Turno
    IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
        RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 7. Última oferta
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

    -- 8. Bloqueo EXCLUSIVO del cultivo
    SELECT id, stock_total, stock_committed, stock_sold, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo asociado a la negociación no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 9. Reserva neta ya registrada (propuesta/contraoferta) y ajuste necesario
    v_net_reserved := public.negotiation_net_reserved_kg(p_negotiation_id);
    v_delta := v_latest_offer.quantity_kg - v_net_reserved;

    IF v_delta > 0 THEN
        v_available_stock := GREATEST(0, (
            v_crop.stock_total
            - COALESCE(v_crop.stock_committed, 0)
            - COALESCE(v_crop.stock_sold, 0)
        ));

        IF v_delta > v_available_stock THEN
            RAISE EXCEPTION 'Stock disponible insuficiente (% kg) para reservar % kg pactados',
                v_available_stock + v_net_reserved, v_latest_offer.quantity_kg USING ERRCODE = '22000';
        END IF;
    END IF;

    v_new_committed := COALESCE(v_crop.stock_committed, 0) + v_delta;

    IF v_new_committed < 0 THEN
        RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) insuficiente para ajustar la reserva',
            v_crop.stock_committed USING ERRCODE = '22000';
    END IF;

    v_new_available := v_crop.stock_total - v_new_committed - COALESCE(v_crop.stock_sold, 0);

    v_new_crop_status := CASE
        WHEN v_new_available <= 0 THEN 'agotada'::public.crop_status
        WHEN v_crop.status = 'agotada'::public.crop_status THEN 'activa'::public.crop_status
        ELSE v_crop.status
    END;

    IF v_delta <> 0 THEN
        UPDATE public.crops
        SET stock_committed = v_new_committed,
            status = v_new_crop_status,
            updated_at = v_now
        WHERE id = v_crop.id;

        IF v_delta > 0 THEN
            INSERT INTO public.inventory_movements (
                crop_id, negotiation_id, movement_type, quantity_kg, created_at
            ) VALUES (
                v_crop.id, p_negotiation_id, 'reserva'::public.inventory_movement_type, v_delta, v_now
            ) RETURNING id INTO v_movement_id;
        ELSE
            INSERT INTO public.inventory_movements (
                crop_id, negotiation_id, movement_type, quantity_kg, created_at
            ) VALUES (
                v_crop.id, p_negotiation_id, 'liberacion_reserva'::public.inventory_movement_type, -v_delta, v_now
            ) RETURNING id INTO v_movement_id;
        END IF;
    END IF;

    -- 10. Estado acordada
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
        'reservation_delta_kg', v_delta,
        'movement_id', v_movement_id,
        'crop_status', v_new_crop_status::text,
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.accept_negotiation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.accept_negotiation(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_negotiation(uuid) TO authenticated;

-- ============================================================================
-- 6. RPC: complete_negotiation
--    Convierte exactamente una vez la reserva neta en venta. Aborta si la
--    reserva es insuficiente.
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
    v_net_reserved numeric := 0;
    v_excess_release numeric := 0;
    v_new_committed numeric;
    v_new_sold numeric;
    v_new_available numeric;
    v_new_crop_status public.crop_status;
    v_sale_movement_id uuid;
    v_release_movement_id uuid := NULL;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Perfil aprobado
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

    -- 3. Bloqueo de la negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Participantes
    IF v_user_id NOT IN (v_neg.buyer_id, v_neg.farmer_id) THEN
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 5. Sólo tratos acordados y no completados (exactamente una vez)
    IF v_neg.status IS DISTINCT FROM 'acordada'::public.negotiation_status THEN
        RAISE EXCEPTION 'Solo se pueden completar negociaciones que se encuentren en estado acordada (estado actual: %)', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 6. Última oferta acordada
    SELECT id, quantity_kg, proposed_price_per_kg
    INTO v_latest_offer
    FROM public.negotiation_offers
    WHERE negotiation_id = p_negotiation_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No hay ofertas registradas en esta negociación' USING ERRCODE = '22000';
    END IF;

    -- 7. Bloqueo EXCLUSIVO del cultivo
    SELECT id, stock_total, stock_committed, stock_sold, status
    INTO v_crop
    FROM public.crops
    WHERE id = v_neg.crop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cultivo asociado a la negociación no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 8. La reserva neta debe cubrir la cantidad pactada
    v_net_reserved := public.negotiation_net_reserved_kg(p_negotiation_id);

    IF v_net_reserved < v_latest_offer.quantity_kg THEN
        RAISE EXCEPTION 'Inconsistencia contable: reserva neta (% kg) insuficiente para completar la venta de % kg',
            v_net_reserved, v_latest_offer.quantity_kg USING ERRCODE = '22000';
    END IF;

    IF COALESCE(v_crop.stock_committed, 0) < v_net_reserved THEN
        RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) menor que la reserva neta (%)',
            v_crop.stock_committed, v_net_reserved USING ERRCODE = '22000';
    END IF;

    -- 9. Transferencia exacta reserva -> vendido
    v_excess_release := v_net_reserved - v_latest_offer.quantity_kg;
    v_new_committed := COALESCE(v_crop.stock_committed, 0) - v_net_reserved;
    v_new_sold := COALESCE(v_crop.stock_sold, 0) + v_latest_offer.quantity_kg;
    v_new_available := v_crop.stock_total - v_new_committed - v_new_sold;

    v_new_crop_status := CASE
        WHEN v_new_available <= 0 THEN 'agotada'::public.crop_status
        WHEN v_crop.status = 'agotada'::public.crop_status THEN 'activa'::public.crop_status
        ELSE v_crop.status
    END;

    UPDATE public.crops
    SET stock_committed = v_new_committed,
        stock_sold = v_new_sold,
        status = v_new_crop_status,
        updated_at = v_now
    WHERE id = v_crop.id;

    -- 10. Movimientos contables: venta y, si hubiera, liberación de excedente
    INSERT INTO public.inventory_movements (
        crop_id, negotiation_id, movement_type, quantity_kg, created_at
    ) VALUES (
        v_crop.id, p_negotiation_id, 'venta'::public.inventory_movement_type,
        v_latest_offer.quantity_kg, v_now
    ) RETURNING id INTO v_sale_movement_id;

    IF v_excess_release > 0 THEN
        INSERT INTO public.inventory_movements (
            crop_id, negotiation_id, movement_type, quantity_kg, created_at
        ) VALUES (
            v_crop.id, p_negotiation_id, 'liberacion_reserva'::public.inventory_movement_type,
            v_excess_release, v_now
        ) RETURNING id INTO v_release_movement_id;
    END IF;

    -- 11. Estado completada
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
        'net_reserved_kg', v_net_reserved,
        'movement_id', v_sale_movement_id,
        'release_movement_id', v_release_movement_id,
        'crop_status', v_new_crop_status::text,
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.complete_negotiation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_negotiation(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_negotiation(uuid) TO authenticated;

-- ============================================================================
-- 7. RPC: reject_or_cancel_negotiation
--    Libera sólo la reserva neta real, en cualquier estado activo.
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
    v_net_reserved numeric := 0;
    v_released_kg numeric := 0;
    v_new_committed numeric;
    v_new_available numeric;
    v_new_crop_status public.crop_status;
    v_now timestamptz := clock_timestamp();
BEGIN
    -- 1. Autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Perfil aprobado
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

    -- 3. Sólo se permiten los dos estados terminales de cierre
    IF p_target_status NOT IN (
        'rechazada'::public.negotiation_status,
        'cancelada'::public.negotiation_status
    ) THEN
        RAISE EXCEPTION 'Estado destino no permitido para cierre de negociación: %', p_target_status USING ERRCODE = '22000';
    END IF;

    -- 4. Bloqueo de la negociación
    SELECT n.id, n.crop_id, n.buyer_id, n.status, n.current_responder, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Participantes
    IF v_user_id = v_neg.buyer_id THEN
        v_caller_role := 'comprador'::public.user_role;
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_caller_role := 'agricultor'::public.user_role;
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 6. Estado no terminal
    IF v_neg.status IN (
        'completada'::public.negotiation_status,
        'rechazada'::public.negotiation_status,
        'cancelada'::public.negotiation_status
    ) THEN
        RAISE EXCEPTION 'La negociación ya se encuentra cerrada (estado actual: %)', v_neg.status USING ERRCODE = '22000';
    END IF;

    -- 7. Reglas por acción
    IF p_target_status = 'rechazada'::public.negotiation_status THEN
        IF v_neg.status IN ('propuesta'::public.negotiation_status, 'contraofertada'::public.negotiation_status) THEN
            IF v_neg.current_responder IS NOT NULL AND v_neg.current_responder IS DISTINCT FROM v_caller_role THEN
                RAISE EXCEPTION 'No es tu turno para responder a esta negociación' USING ERRCODE = '42501';
            END IF;
        END IF;
    ELSE
        IF v_neg.status = 'propuesta'::public.negotiation_status
           AND v_caller_role IS DISTINCT FROM 'comprador'::public.user_role THEN
            RAISE EXCEPTION 'Solo el comprador proponente puede cancelar una propuesta inicial' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- 8. Liberación de la reserva neta real
    v_net_reserved := public.negotiation_net_reserved_kg(p_negotiation_id);

    IF v_net_reserved > 0 THEN
        SELECT id, stock_total, stock_committed, stock_sold, status
        INTO v_crop
        FROM public.crops
        WHERE id = v_neg.crop_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'El cultivo asociado a la negociación no existe' USING ERRCODE = 'P0002';
        END IF;

        IF COALESCE(v_crop.stock_committed, 0) < v_net_reserved THEN
            RAISE EXCEPTION 'Inconsistencia contable: stock comprometido (%) menor que la reserva neta a liberar (%)',
                v_crop.stock_committed, v_net_reserved USING ERRCODE = '22000';
        END IF;

        v_released_kg := v_net_reserved;
        v_new_committed := COALESCE(v_crop.stock_committed, 0) - v_released_kg;
        v_new_available := v_crop.stock_total - v_new_committed - COALESCE(v_crop.stock_sold, 0);

        v_new_crop_status := CASE
            WHEN v_crop.status = 'agotada'::public.crop_status AND v_new_available > 0 THEN 'activa'::public.crop_status
            ELSE v_crop.status
        END;

        UPDATE public.crops
        SET stock_committed = v_new_committed,
            status = v_new_crop_status,
            updated_at = v_now
        WHERE id = v_crop.id;

        INSERT INTO public.inventory_movements (
            crop_id, negotiation_id, movement_type, quantity_kg, created_at
        ) VALUES (
            v_crop.id, p_negotiation_id, 'liberacion_reserva'::public.inventory_movement_type,
            v_released_kg, v_now
        ) RETURNING id INTO v_movement_id;
    END IF;

    -- 9. Cierre de la negociación
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
REVOKE ALL ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text) TO authenticated;

-- ============================================================================
-- 8. WRAPPERS DE COMPATIBILIDAD
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

ALTER FUNCTION public.reject_negotiation(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reject_negotiation(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_negotiation(uuid, text) TO authenticated;

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

ALTER FUNCTION public.cancel_negotiation(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.cancel_negotiation(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_negotiation(uuid, text) TO authenticated;

-- ============================================================================
-- 9. VISIBILIDAD DEL CULTIVO PARA EL COMPRADOR DEL TRATO
--    Se usa una función SECURITY DEFINER para evitar recursión entre políticas
--    RLS de crops y negotiations.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_negotiation_buyer_of_crop(p_crop_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.negotiations n
        WHERE n.crop_id = p_crop_id
          AND n.buyer_id = auth.uid()
    );
$$;

ALTER FUNCTION public.is_negotiation_buyer_of_crop(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.is_negotiation_buyer_of_crop(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_negotiation_buyer_of_crop(uuid) TO authenticated;

DROP POLICY IF EXISTS "crops_select_negotiation_buyer" ON public.crops;
CREATE POLICY "crops_select_negotiation_buyer"
ON public.crops
FOR SELECT
TO authenticated
USING (public.is_negotiation_buyer_of_crop(id));

COMMIT;
