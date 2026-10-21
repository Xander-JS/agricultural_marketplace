-- ============================================================================
-- SUITE DE REGRESIÓN: RESERVA DE INVENTARIO DESDE LA PROPUESTA
-- PROYECTO: agricultural_marketplace (PostgreSQL local)
-- OBJETIVO: Verificar el ciclo completo de reserva anticipada:
--           1. create_negotiation_with_offer reserva stock y actualiza estado.
--           2. La disponibilidad se calcula como total - comprometido - vendido.
--           3. counter_offer ajusta la reserva neta (reserva o libera diferencia).
--           4. accept_negotiation no duplica reservas.
--           5. complete_negotiation transfiere la reserva a vendido una sola vez.
--           6. reject_or_cancel_negotiation libera sólo la reserva real.
--           7. Negociaciones heredadas sin movimientos reservan al aceptar.
--           8. El comprador conserva visibilidad del cultivo aunque esté agotado.
-- ============================================================================

CREATE OR REPLACE FUNCTION test_proposal_reservation_runner()
RETURNS TABLE (
    test_code text,
    description text,
    expected text,
    obtained text,
    verdict text
)
LANGUAGE plpgsql
AS $$
DECLARE
    c_farmer_id uuid := 'aa000000-0000-0000-0000-000000000001';
    c_buyer1_id uuid := 'bb000000-0000-0000-0000-000000000001';
    c_buyer2_id uuid := 'bb000000-0000-0000-0000-000000000002';
    c_crop_id   uuid := 'dd000000-0000-0000-0000-000000000001';

    v_neg1 uuid;
    v_neg2 uuid;
    v_legacy uuid;
    v_json jsonb;
    v_err_code text;
    v_err_msg text;
    v_committed numeric;
    v_sold numeric;
    v_status public.crop_status;
    v_neg_status public.negotiation_status;
    v_count int;
    v_reserved numeric;
BEGIN
    -- Limpieza previa
    DELETE FROM public.inventory_movements WHERE crop_id = c_crop_id;
    DELETE FROM public.negotiation_offers WHERE sender_id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);
    DELETE FROM public.negotiations WHERE crop_id = c_crop_id;
    DELETE FROM public.crops WHERE id = c_crop_id;
    DELETE FROM public.profiles WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);
    DELETE FROM auth.users WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);

    INSERT INTO auth.users (id, email) VALUES
        (c_farmer_id, 'reservation_farmer@test.com'),
        (c_buyer1_id, 'reservation_buyer1@test.com'),
        (c_buyer2_id, 'reservation_buyer2@test.com');

    INSERT INTO public.profiles (id, phone, role, verification_status, full_name) VALUES
        (c_farmer_id, '3200000001', 'agricultor', 'aprobado', 'Productor Reserva'),
        (c_buyer1_id, '3200000002', 'comprador', 'aprobado', 'Comprador Reserva 1'),
        (c_buyer2_id, '3200000003', 'comprador', 'aprobado', 'Comprador Reserva 2');

    INSERT INTO public.crops (
        id, farmer_id, title, description, crop_type, price_per_kg,
        stock_total, stock_committed, stock_sold, min_order_kg,
        department, municipality, status
    ) VALUES (
        c_crop_id, c_farmer_id, 'Café Reserva Anticipada', 'Lote de prueba', 'Café', 5000,
        1000, 0, 0, 10, 'Huila', 'Pitalito', 'activa'
    );

    -- ------------------------------------------------------------------------
    test_code := '1';
    description := 'Propuesta inicial reserva inventario y registra movimiento reserva';
    expected := 'stock_committed = 100, 1 movimiento reserva de 100, estado propuesta';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop_id, 100, 5000, 'en_finca', 'Propuesta con reserva');
        v_neg1 := (v_json->>'id')::uuid;

        SELECT stock_committed INTO v_committed FROM public.crops WHERE id = c_crop_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements
        WHERE negotiation_id = v_neg1 AND movement_type = 'reserva' AND quantity_kg = 100;

        obtained := 'committed=' || v_committed || ', movimientos_reserva=' || v_count || ', status=' || (v_json->>'status');
        IF v_committed = 100 AND v_count = 1 AND (v_json->>'status') = 'propuesta' THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '2';
    description := 'La disponibilidad descuenta la reserva de propuestas activas';
    expected := 'Segunda propuesta de 950 kg rechazada por 900 kg disponibles';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer2_id, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop_id, 950, 5000, 'en_finca', 'Excede disponibilidad');
        obtained := 'Permitido crear propuesta de 950 kg (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '22000' AND v_err_msg LIKE '%stock disponible%' THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '3';
    description := 'Reservar todo el stock deja el cultivo agotado y visible para el comprador';
    expected := 'stock_committed = 1000, cultivo agotada, comprador ve 1 fila del cultivo';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer2_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop_id, 900, 5000, 'en_finca', 'Reserva total');
        v_neg2 := (v_json->>'id')::uuid;
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed, status INTO v_committed, v_status FROM public.crops WHERE id = c_crop_id;

        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer2_id, 'role', 'authenticated')::text, true);
        SELECT count(*) INTO v_count FROM public.crops WHERE id = c_crop_id;
        PERFORM set_config('role', 'postgres', true);

        obtained := 'committed=' || v_committed || ', status=' || v_status || ', filas_visibles_comprador=' || v_count;
        IF v_committed = 1000 AND v_status = 'agotada' AND v_count = 1 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '4';
    description := 'Contraoferta sobre cultivo agotado no puede exceder la reserva vigente';
    expected := 'Error 22000 al intentar subir de 100 a 120 kg sin disponibilidad';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.counter_offer(v_neg1, 120, 5100, 'en_finca', 'Subir cantidad sin stock');
        obtained := 'Permitido subir cantidad sin stock (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '22000' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '5';
    description := 'Contraoferta que reduce cantidad libera la diferencia y reactiva el cultivo';
    expected := 'Reserva neta 80, stock_committed 980, liberación 20, cultivo activa';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.counter_offer(v_neg1, 80, 5100, 'en_finca', 'Reducir cantidad');
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed, status INTO v_committed, v_status FROM public.crops WHERE id = c_crop_id;
        SELECT public.negotiation_net_reserved_kg(v_neg1) INTO v_reserved;
        SELECT count(*) INTO v_count FROM public.inventory_movements
        WHERE negotiation_id = v_neg1 AND movement_type = 'liberacion_reserva' AND quantity_kg = 20;

        obtained := 'committed=' || v_committed || ', reserva_neta=' || v_reserved || ', status=' || v_status || ', liberaciones20=' || v_count;
        IF v_committed = 980 AND v_reserved = 80 AND v_status = 'activa' AND v_count = 1 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '6';
    description := 'Aceptar una propuesta ya reservada no duplica la reserva';
    expected := 'stock_committed permanece 980 y no se inserta una nueva reserva para Neg 1';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.accept_negotiation(v_neg1);
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed INTO v_committed FROM public.crops WHERE id = c_crop_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements
        WHERE negotiation_id = v_neg1 AND movement_type = 'reserva';
        SELECT status INTO v_neg_status FROM public.negotiations WHERE id = v_neg1;

        obtained := 'committed=' || v_committed || ', movimientos_reserva_neg1=' || v_count || ', status=' || v_neg_status;
        IF v_committed = 980 AND v_count = 1 AND v_neg_status = 'acordada' THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '7';
    description := 'Cancelar un trato acordado libera sólo su reserva neta';
    expected := 'stock_committed 900 (se liberan 80) y Neg 2 sigue reservando 900';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.cancel_negotiation(v_neg1, 'Cancelación de trato con reserva');
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed INTO v_committed FROM public.crops WHERE id = c_crop_id;
        SELECT public.negotiation_net_reserved_kg(v_neg2) INTO v_reserved;

        obtained := 'committed=' || v_committed || ', reserva_neta_neg2=' || v_reserved || ', liberado=' || (v_json->>'released_kg');
        IF v_committed = 900 AND v_reserved = 900 AND (v_json->>'released_kg')::numeric = 80 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '8';
    description := 'Completar transfiere la reserva a vendido exactamente una vez';
    expected := 'Aceptar Neg 2 sin duplicar, completar deja committed 0 y sold 900';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.accept_negotiation(v_neg2);
        v_json := public.complete_negotiation(v_neg2);
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed, stock_sold INTO v_committed, v_sold FROM public.crops WHERE id = c_crop_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements
        WHERE negotiation_id = v_neg2 AND movement_type = 'venta' AND quantity_kg = 900;

        obtained := 'committed=' || v_committed || ', sold=' || v_sold || ', movimientos_venta=' || v_count;
        IF v_committed = 0 AND v_sold = 900 AND v_count = 1 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '9';
    description := 'Rechazar una propuesta no aceptada libera su reserva de inmediato';
    expected := 'Propuesta de 50 reserva y rechazo devuelve committed a 0 con liberación de 50';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop_id, 50, 5000, 'en_finca', 'Propuesta a rechazar');
        v_legacy := (v_json->>'id')::uuid;

        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.reject_negotiation(v_legacy, 'No disponible para entrega');
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed INTO v_committed FROM public.crops WHERE id = c_crop_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements
        WHERE negotiation_id = v_legacy AND movement_type = 'liberacion_reserva' AND quantity_kg = 50;

        obtained := 'committed=' || v_committed || ', liberaciones50=' || v_count;
        IF v_committed = 0 AND v_count = 1 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    test_code := '10';
    description := 'Negociación heredada sin movimientos reserva al aceptar';
    expected := 'Aceptación crea reserva de 50 y committed pasa de 0 a 50';
    BEGIN
        INSERT INTO public.negotiations (crop_id, buyer_id, status, current_responder)
        VALUES (c_crop_id, c_buyer1_id, 'contraofertada', 'agricultor')
        RETURNING id INTO v_legacy;

        INSERT INTO public.negotiation_offers (
            negotiation_id, sender_id, quantity_kg, proposed_price_per_kg, delivery_method
        ) VALUES (v_legacy, c_buyer1_id, 50, 5000, 'en_finca');

        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.accept_negotiation(v_legacy);
        PERFORM set_config('role', 'postgres', true);

        SELECT stock_committed INTO v_committed FROM public.crops WHERE id = c_crop_id;
        SELECT public.negotiation_net_reserved_kg(v_legacy) INTO v_reserved;

        obtained := 'committed=' || v_committed || ', reserva_neta_legacy=' || v_reserved || ', delta=' || (v_json->>'reservation_delta_kg');
        IF v_committed = 50 AND v_reserved = 50 AND (v_json->>'reservation_delta_kg')::numeric = 50 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        PERFORM set_config('role', 'postgres', true);
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- Limpieza final
    PERFORM set_config('role', 'postgres', true);
    DELETE FROM public.inventory_movements WHERE crop_id = c_crop_id;
    DELETE FROM public.negotiation_offers WHERE sender_id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);
    DELETE FROM public.negotiations WHERE crop_id = c_crop_id;
    DELETE FROM public.crops WHERE id = c_crop_id;
    DELETE FROM public.profiles WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);
    DELETE FROM auth.users WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id);
END;
$$;
