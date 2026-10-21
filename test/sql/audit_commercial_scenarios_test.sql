-- ============================================================================
-- SUITE DE AUDITORÍA AUTOMATIZADA: SEIS ESCENARIOS CRÍTICOS Y CONCURRENCIA
-- PROYECTO: agricultural_marketplace (PostgreSQL local)
-- OBJETIVO: Evaluar de forma reproducible y aislada los 6 escenarios de seguridad
--           e integridad comercial, más pruebas de concurrencia e inventario.
-- ============================================================================

CREATE OR REPLACE FUNCTION test_audit_runner()
RETURNS TABLE (
    scenario text,
    test_code text,
    description text,
    expected text,
    obtained text,
    verdict text
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Identificadores temporales aislados
    c_farmer_id uuid := 'a0000000-0000-0000-0000-000000000001';
    c_buyer1_id uuid := 'b0000000-0000-0000-0000-000000000001';
    c_buyer2_id uuid := 'b0000000-0000-0000-0000-000000000002';
    c_buyer_pend uuid := 'b0000000-0000-0000-0000-000000000003';
    c_buyer_ia   uuid := 'b0000000-0000-0000-0000-000000000004';
    c_buyer_rech uuid := 'b0000000-0000-0000-0000-000000000005';
    c_buyer_susp uuid := 'b0000000-0000-0000-0000-000000000006';
    c_third_id   uuid := 'c0000000-0000-0000-0000-000000000001';

    c_crop1_id   uuid := 'd0000000-0000-0000-0000-000000000001';
    c_crop2_id   uuid := 'd0000000-0000-0000-0000-000000000002';

    v_neg_id uuid;
    v_neg2_id uuid;
    v_offer_id uuid;
    v_json jsonb;
    v_err_code text;
    v_err_msg text;
    v_count int;
    v_stock_total numeric;
    v_stock_comm numeric;
    v_stock_sold numeric;
    v_status public.negotiation_status;
BEGIN
    -- Limpieza previa de entorno de pruebas
    DELETE FROM public.inventory_movements WHERE crop_id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.negotiation_offers WHERE sender_id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_third_id);
    DELETE FROM public.negotiations WHERE crop_id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.crops WHERE id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.profiles WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_buyer_ia, c_buyer_rech, c_buyer_susp, c_third_id);
    DELETE FROM auth.users WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_buyer_ia, c_buyer_rech, c_buyer_susp, c_third_id);

    -- Setup: Crear usuarios base en auth.users y profiles
    INSERT INTO auth.users (id, email) VALUES
        (c_farmer_id, 'audit_farmer@test.com'),
        (c_buyer1_id, 'audit_buyer1@test.com'),
        (c_buyer2_id, 'audit_buyer2@test.com'),
        (c_buyer_pend, 'audit_buyer_pend@test.com'),
        (c_buyer_ia, 'audit_buyer_ia@test.com'),
        (c_buyer_rech, 'audit_buyer_rech@test.com'),
        (c_buyer_susp, 'audit_buyer_susp@test.com'),
        (c_third_id, 'audit_third@test.com');

    INSERT INTO public.profiles (id, phone, role, verification_status, full_name) VALUES
        (c_farmer_id, '3100000001', 'agricultor', 'aprobado', 'Agricultor Auditado'),
        (c_buyer1_id, '3100000002', 'comprador', 'aprobado', 'Comprador 1 Auditado'),
        (c_buyer2_id, '3100000003', 'comprador', 'aprobado', 'Comprador 2 Auditado'),
        (c_buyer_pend, '3100000004', 'comprador', 'pendiente', 'Comprador Pendiente'),
        (c_buyer_ia, '3100000005', 'comprador', 'en_revision_ia', 'Comprador En Revision'),
        (c_buyer_rech, '3100000006', 'comprador', 'rechazado', 'Comprador Rechazado'),
        (c_buyer_susp, '3100000007', 'comprador', 'suspendido', 'Comprador Suspendido'),
        (c_third_id, '3100000008', 'comprador', 'aprobado', 'Tercero Ajeno Auditado');

    -- Setup: Crear cultivo de prueba
    INSERT INTO public.crops (id, farmer_id, title, description, crop_type, price_per_kg, stock_total, stock_committed, stock_sold, min_order_kg, department, municipality, status)
    VALUES (c_crop1_id, c_farmer_id, 'Aguacate Hass Audit', 'Calidad exportación', 'Aguacate', 5000, 1000, 0, 0, 50, 'Antioquia', 'Rionegro', 'activa');

    -- ========================================================================
    -- ESCENARIO 1: Comprador no aprobado intenta iniciar negociación
    -- ========================================================================
    scenario := 'Escenario 1';

    -- 1.1: Comprador pendiente
    test_code := '1.1';
    description := 'Comprador en estado pendiente intenta iniciar negociación vía RPC';
    expected := 'Error 42501 (cuenta no verificada y aprobada)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer_pend, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop1_id, 100, 4800, 'en_finca', 'Oferta pendiente');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 1.2: Comprador en_revision_ia
    test_code := '1.2';
    description := 'Comprador en estado en_revision_ia intenta iniciar negociación vía RPC';
    expected := 'Error 42501 (cuenta no verificada y aprobada)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer_ia, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop1_id, 100, 4800, 'en_finca', 'Oferta en revision');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 1.3: Comprador rechazado
    test_code := '1.3';
    description := 'Comprador en estado rechazado intenta iniciar negociación vía RPC';
    expected := 'Error 42501 (cuenta no verificada y aprobada)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer_rech, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop1_id, 100, 4800, 'en_finca', 'Oferta rechazado');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 1.4: Comprador suspendido
    test_code := '1.4';
    description := 'Comprador en estado suspendido intenta iniciar negociación vía RPC';
    expected := 'Error 42501 (cuenta no verificada y aprobada)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer_susp, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop1_id, 100, 4800, 'en_finca', 'Oferta suspendido');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 1.5: Comprador aprobado inicia negociación válida
    test_code := '1.5';
    description := 'Comprador aprobado inicia negociación válida cumpliendo reglas';
    expected := 'Negociación creada exitosamente en estado propuesta';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop1_id, 100, 4800, 'en_finca', 'Oferta valida comprador 1');
        v_neg_id := (v_json->>'id')::uuid;
        obtained := 'Creada: ID ' || v_neg_id || ' status ' || (v_json->>'status');
        verdict := 'APROBADO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error inesperado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- 1.6: Integridad de persistencia en Escenario 1
    test_code := '1.6';
    description := 'Comprobar que no quedaron negociaciones residuales de intentos no aprobados';
    expected := 'Exactamente 1 negociación registrada (la del comprador aprobado)';
    SELECT count(*) INTO v_count FROM public.negotiations WHERE crop_id = c_crop1_id;
    obtained := v_count || ' negociaciones encontradas';
    IF v_count = 1 THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 2: Usuario intenta negociar su propio cultivo
    -- ========================================================================
    scenario := 'Escenario 2';

    -- 2.1: Agricultor intenta negociar su propio cultivo vía RPC
    test_code := '2.1';
    description := 'Agricultor dueño intenta iniciar negociación sobre su propio cultivo';
    expected := 'Error 42501 (No puedes iniciar una negociación sobre tu propio cultivo)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.create_negotiation_with_offer(c_crop1_id, 50, 5000, 'en_finca', 'Auto compra');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 2.2: Intento de auto-negociación mediante inserción directa en tabla
    test_code := '2.2';
    description := 'Agricultor intenta inserción directa en negotiations donde buyer_id = farmer_id';
    expected := 'Bloqueado por privilegios o trigger de integridad';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        INSERT INTO public.negotiations (crop_id, buyer_id, status) VALUES (c_crop1_id, c_farmer_id, 'propuesta');
        obtained := 'Inserción directa permitida (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 2.3: Comprador legítimo distinto sí puede negociar
    test_code := '2.3';
    description := 'Comprador diferente y autorizado puede negociar el mismo cultivo';
    expected := 'Negociación creada exitosamente para Comprador 2';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer2_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop1_id, 150, 4900, 'transportadora', 'Oferta valida comprador 2');
        v_neg2_id := (v_json->>'id')::uuid;
        obtained := 'Creada: ID ' || v_neg2_id;
        verdict := 'APROBADO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 3: Participante intenta responder fuera de turno
    -- ========================================================================
    scenario := 'Escenario 3';
    -- En este punto, v_neg_id está en estado 'propuesta' y current_responder = 'agricultor'.

    -- 3.1: Comprador intenta contraofertar fuera de turno
    test_code := '3.1';
    description := 'Comprador intenta enviar contraoferta cuando el turno es del agricultor';
    expected := 'Error 42501 (No es tu turno para responder)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        PERFORM public.counter_offer(v_neg_id, 120, 4700, 'en_finca', 'Contraoferta fuera de turno');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 3.2: Comprador intenta aceptar fuera de turno (y sobre su propia oferta)
    test_code := '3.2';
    description := 'Comprador intenta aceptar cuando no es su turno y es su propia oferta';
    expected := 'Error 42501 (No es tu turno o propia oferta)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        PERFORM public.accept_negotiation(v_neg_id);
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 3.3: Comprador intenta rechazar fuera de turno
    test_code := '3.3';
    description := 'Comprador intenta rechazar cuando el turno le corresponde al agricultor';
    expected := 'Error 42501 (No es tu turno para responder)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        PERFORM public.reject_negotiation(v_neg_id, 'Rechazo fuera de turno');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 3.4: Inserción directa de oferta para saltarse el turno
    test_code := '3.4';
    description := 'Comprador intenta insertar oferta directamente en negotiation_offers sin pasar por RPC';
    expected := 'Bloqueado por privilegios SQL (sin permiso INSERT directo)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        INSERT INTO public.negotiation_offers (negotiation_id, sender_id, quantity_kg, proposed_price_per_kg, delivery_method, message)
        VALUES (v_neg_id, c_buyer1_id, 100, 4800, 'en_finca', 'Bypass directo');
        obtained := 'Permitido insertar directamente (Vulnerabilidad de salto de turno)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 3.5: Respuesta válida del participante en turno (Agricultor contraoferta)
    test_code := '3.5';
    description := 'Agricultor (con turno válido) envía contraoferta legítima';
    expected := 'Contraoferta exitosa, estado contraofertada, turno pasa a comprador';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.counter_offer(v_neg_id, 100, 4900, 'en_finca', 'Precio minimo 4900');
        obtained := 'Estado: ' || (v_json->>'status') || ', Siguiente turno: ' || (v_json->>'current_responder');
        IF (v_json->>'status') = 'contraofertada' AND (v_json->>'current_responder') = 'comprador' THEN
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

    -- 3.6: Agricultor intenta responder dos veces consecutivas (fuera de turno)
    test_code := '3.6';
    description := 'Agricultor intenta enviar segunda contraoferta consecutiva sin esperar al comprador';
    expected := 'Error 42501 (No es tu turno para responder)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.counter_offer(v_neg_id, 100, 4950, 'en_finca', 'Segunda oferta consecutiva');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 4: Cancelación o rechazo después de reservar inventario
    -- ========================================================================
    scenario := 'Escenario 4';

    -- 4.A: Cancelación con reserva activa
    test_code := '4.A';
    description := 'Aceptar trato ya reservado desde la propuesta y posterior cancelación liberando exactamente una vez';
    expected := 'Reserva compartida 250 kg (100 Neg 1 + 150 Neg 2); tras cancelar Neg 1 quedan 150 kg comprometidos y 1 liberación';
    BEGIN
        -- Comprador acepta la contraoferta del agricultor (100 kg a 4900).
        -- La propuesta ya reservó 100 kg; Neg 2 mantiene otros 150 kg reservados.
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.accept_negotiation(v_neg_id);

        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;
        IF v_stock_comm != 250 THEN
            RAISE EXCEPTION 'Reserva compartida inicial incorrecta: % (esperado 250)', v_stock_comm;
        END IF;

        -- Comprador cancela la negociación acordada
        v_json := public.cancel_negotiation(v_neg_id, 'Imprevisto logístico');
        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements WHERE negotiation_id = v_neg_id AND movement_type = 'liberacion_reserva';

        obtained := 'Comprometido final: ' || v_stock_comm || ' kg, Liberaciones registradas: ' || v_count;
        IF v_stock_comm = 150 AND v_count = 1 THEN
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

    -- 4.B: Rechazo con reserva activa (utilizando la negociación v_neg2_id)
    test_code := '4.B';
    description := 'Aceptar trato de Comprador 2 (150 kg) y rechazarlo verificando liberación exacta';
    expected := 'Stock reservado 150 kg, liberado 150 kg, comprometido final 0';
    BEGIN
        -- Agricultor acepta propuesta de Comprador 2 (150 kg)
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.accept_negotiation(v_neg2_id);

        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;
        IF v_stock_comm != 150 THEN
            RAISE EXCEPTION 'Reserva incorrecta en neg2: % (esperado 150)', v_stock_comm;
        END IF;

        -- Agricultor rechaza la negociación acordada
        v_json := public.reject_negotiation(v_neg2_id, 'Problema con la cosecha pactada');
        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;
        SELECT count(*) INTO v_count FROM public.inventory_movements WHERE negotiation_id = v_neg2_id AND movement_type = 'liberacion_reserva';

        obtained := 'Comprometido final: ' || v_stock_comm || ' kg, Liberaciones: ' || v_count;
        IF v_stock_comm = 0 AND v_count = 1 THEN
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

    -- 4.C: Doble cancelación o doble rechazo
    test_code := '4.C';
    description := 'Intento de cancelar o rechazar nuevamente una negociación ya cancelada/rechazada';
    expected := 'Error 22000 (La negociación ya se encuentra cerrada), sin liberación duplicada';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        PERFORM public.cancel_negotiation(v_neg_id, 'Reintento de cancelación');
        obtained := 'Permitido reintento terminal (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        SELECT count(*) INTO v_count FROM public.inventory_movements WHERE negotiation_id = v_neg_id AND movement_type = 'liberacion_reserva';
        obtained := 'Bloqueado con ' || v_err_code || ' (' || v_err_msg || '), liberaciones totales: ' || v_count;
        IF v_err_code = '22000' AND v_count = 1 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    RETURN NEXT;

    -- 4.D: Cancelación de propuesta con reserva (sin aceptación)
    test_code := '4.D';
    description := 'Cancelar una propuesta inicial que ya había reservado stock, sin haber sido aceptada';
    expected := 'Negociación cancelada, reserva y liberación registradas (2 movimientos), stock comprometido 0';
    BEGIN
        -- Crear negociación temporal para prueba 4.D: reserva 80 kg desde la propuesta
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop1_id, 80, 4900, 'en_finca', 'Propuesta a cancelar con reserva');
        v_neg_id := (v_json->>'id')::uuid;

        -- Cancelar inmediatamente estando en estado propuesta
        v_json := public.cancel_negotiation(v_neg_id, 'Cancelación antes de acordar');

        SELECT count(*) INTO v_count FROM public.inventory_movements WHERE negotiation_id = v_neg_id;
        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;

        obtained := 'Movimientos: ' || v_count || ', Comprometido: ' || v_stock_comm || ' kg';
        IF v_count = 2 AND v_stock_comm = 0 THEN
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

    -- 4.E: Reservas compartidas concurrentes sobre el mismo cultivo
    test_code := '4.E';
    description := 'Dos negociaciones independientes sobre el mismo cultivo: cancelar una no afecta la otra';
    expected := 'Neg 1 reservó 200kg, Neg 2 reservó 300kg; tras cancelar Neg 1, stock_committed permanece en 300kg';
    BEGIN
        -- Negociación 1: Comprador 1 reserva 200 kg
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop1_id, 200, 5000, 'en_finca', 'Neg 1 compartida');
        v_neg_id := (v_json->>'id')::uuid;

        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.accept_negotiation(v_neg_id);

        -- Negociación 2: Comprador 2 reserva 300 kg
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer2_id, 'role', 'authenticated')::text, true);
        v_json := public.create_negotiation_with_offer(c_crop1_id, 300, 5000, 'transportadora', 'Neg 2 compartida');
        v_neg2_id := (v_json->>'id')::uuid;

        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        PERFORM public.accept_negotiation(v_neg2_id);

        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;
        IF v_stock_comm != 500 THEN
            RAISE EXCEPTION 'Reserva compartida total incorrecta: % (esperado 500)', v_stock_comm;
        END IF;

        -- Cancelar únicamente Negociación 1
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        PERFORM public.cancel_negotiation(v_neg_id, 'Cancela Neg 1');

        SELECT stock_committed INTO v_stock_comm FROM public.crops WHERE id = c_crop1_id;

        -- Consultar v_status con identidad participante (agricultor) para validar visibilidad RLS
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        SELECT status INTO v_status FROM public.negotiations WHERE id = v_neg2_id;

        obtained := 'Comprometido restante: ' || v_stock_comm || ' kg, Neg 2 status: ' || v_status;
        IF v_stock_comm = 300 AND v_status = 'acordada' THEN
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

    -- 4.F: Negociación ya completada (venta consumada) no permite cancelación ni liberación
    test_code := '4.F';
    description := 'Completar Negociación 2 (300kg) e intentar cancelarla o rechazarla';
    expected := 'Error 22000 (ya cerrada); stock comprometido permanece en 0, vendido en 300';
    BEGIN
        -- Completar negociación 2 como agricultor participante
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        v_json := public.complete_negotiation(v_neg2_id);

        SELECT stock_committed, stock_sold INTO v_stock_comm, v_stock_sold FROM public.crops WHERE id = c_crop1_id;
        IF v_stock_comm != 0 OR v_stock_sold != 300 THEN
            RAISE EXCEPTION 'Estado de stock post completitud incorrecto: comm=%, sold=%', v_stock_comm, v_stock_sold;
        END IF;

        -- Intentar cancelarla (debe fallar con 22000 por estar ya cerrada)
        BEGIN
            PERFORM public.cancel_negotiation(v_neg2_id, 'Intento cancelar trato completado');
            obtained := 'Cancelación de completada permitida (Vulnerabilidad)';
            verdict := 'FALLIDO';
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
            SELECT stock_committed, stock_sold INTO v_stock_comm, v_stock_sold FROM public.crops WHERE id = c_crop1_id;
            obtained := 'Bloqueado con ' || v_err_code || ', comprometido: ' || v_stock_comm || ' kg, vendido: ' || v_stock_sold || ' kg';
            IF v_err_code = '22000' AND v_stock_comm = 0 AND v_stock_sold = 300 THEN
                verdict := 'APROBADO';
            ELSE
                verdict := 'FALLIDO';
            END IF;
        END;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error externo: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    RETURN NEXT;

    -- 4.G: Consistencia contable total de movimientos e inventario
    test_code := '4.G';
    description := 'Conciliación matemática entre stock_total, comprometido, vendido y balance de movimientos';
    expected := 'Stock disponible = total - comprometido - vendido (1000 - 0 - 300 = 700), suma de movimientos cuadra con saldos';
    BEGIN
        SELECT stock_total, stock_committed, stock_sold INTO v_stock_total, v_stock_comm, v_stock_sold FROM public.crops WHERE id = c_crop1_id;
        SELECT 
            COALESCE(SUM(CASE WHEN movement_type = 'reserva' THEN quantity_kg ELSE 0 END), 0) -
            COALESCE(SUM(CASE WHEN movement_type = 'liberacion_reserva' THEN quantity_kg ELSE 0 END), 0) -
            COALESCE(SUM(CASE WHEN movement_type = 'venta' THEN quantity_kg ELSE 0 END), 0)
        INTO v_stock_comm
        FROM public.inventory_movements
        WHERE crop_id = c_crop1_id;

        SELECT COALESCE(SUM(quantity_kg), 0) INTO v_stock_sold
        FROM public.inventory_movements
        WHERE crop_id = c_crop1_id AND movement_type = 'venta';

        obtained := 'Balance de movimientos: Comprometido=' || v_stock_comm || ' kg, Vendido=' || v_stock_sold || ' kg, Disponible=' || (v_stock_total - v_stock_comm - v_stock_sold);
        IF v_stock_comm = 0 AND v_stock_sold = 300 AND (v_stock_total - v_stock_comm - v_stock_sold) = 700 THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 5: Usuario ajeno intenta aceptar, contraofertar o cerrar trato
    -- ========================================================================
    scenario := 'Escenario 5';

    -- Crear una nueva negociación activa entre Farmer y Buyer 1
    PERFORM set_config('role', 'authenticated', true);
    PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
    v_json := public.create_negotiation_with_offer(c_crop1_id, 100, 5000, 'en_finca', 'Negociacion legitima para prueba tercero');
    v_neg_id := (v_json->>'id')::uuid;

    -- 5.1: Tercero intenta contraofertar
    test_code := '5.1';
    description := 'Usuario ajeno autenticado intenta contraofertar en negociación ajena';
    expected := 'Error 42501 (No eres participante de esta negociación)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_third_id, 'role', 'authenticated')::text, true);
        PERFORM public.counter_offer(v_neg_id, 100, 4500, 'en_finca', 'Intromision tercero');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 5.2: Tercero intenta aceptar
    test_code := '5.2';
    description := 'Usuario ajeno autenticado intenta aceptar negociación ajena';
    expected := 'Error 42501 (No eres participante de esta negociación)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_third_id, 'role', 'authenticated')::text, true);
        PERFORM public.accept_negotiation(v_neg_id);
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 5.3: Tercero intenta rechazar
    test_code := '5.3';
    description := 'Usuario ajeno autenticado intenta rechazar negociación ajena';
    expected := 'Error 42501 (No eres participante de esta negociación)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_third_id, 'role', 'authenticated')::text, true);
        PERFORM public.reject_negotiation(v_neg_id, 'Rechazo por tercero');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 5.4: Tercero intenta cancelar
    test_code := '5.4';
    description := 'Usuario ajeno autenticado intenta cancelar negociación ajena';
    expected := 'Error 42501 (No eres participante de esta negociación)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_third_id, 'role', 'authenticated')::text, true);
        PERFORM public.cancel_negotiation(v_neg_id, 'Cancelacion por tercero');
        obtained := 'Permitido (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    RETURN NEXT;

    -- 5.5: Tercero intenta lectura directa de la negociación ajena (RLS SELECT)
    test_code := '5.5';
    description := 'Usuario ajeno intenta consultar negotiations ajenas mediante SELECT directo';
    expected := '0 filas retornadas por política RLS';
    PERFORM set_config('role', 'authenticated', true);
    PERFORM set_config('request.jwt.claims', json_build_object('sub', c_third_id, 'role', 'authenticated')::text, true);
    SELECT count(*) INTO v_count FROM public.negotiations WHERE id = v_neg_id;
    obtained := v_count || ' filas visibles para el tercero';
    IF v_count = 0 THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 6: Modificación directa de estados, inventario o perfiles
    -- ========================================================================
    scenario := 'Escenario 6';

    -- 6.1: Modificar directamente el estado de negotiations
    test_code := '6.1';
    description := 'Cliente authenticated intenta UPDATE directo en negotiations para forzar acordada';
    expected := 'Bloqueado por RLS o privilegios SQL (sin permiso de UPDATE arbitrario)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        UPDATE public.negotiations SET status = 'acordada' WHERE id = v_neg_id;
        obtained := 'Permitido UPDATE directo (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 6.2: Alterar stock_committed directamente en crops
    test_code := '6.2';
    description := 'Cliente authenticated intenta UPDATE directo en crops.stock_committed';
    expected := 'Bloqueado por permisos de columna o trigger protect_crops_inventory_columns';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        UPDATE public.crops SET stock_committed = 999 WHERE id = c_crop1_id;
        obtained := 'Permitido UPDATE directo en stock_committed (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 6.3: Insertar movimientos de inventario directos
    test_code := '6.3';
    description := 'Cliente authenticated intenta INSERT directo en inventory_movements';
    expected := 'Bloqueado por privilegios SQL (sin permiso INSERT para authenticated)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        INSERT INTO public.inventory_movements (crop_id, movement_type, quantity_kg)
        VALUES (c_crop1_id, 'liberacion_reserva', 500);
        obtained := 'Permitido INSERT directo en inventory_movements (Vulnerabilidad)';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 6.4: Auto-aprobarse el perfil modificando verification_status
    test_code := '6.4';
    description := 'Usuario no aprobado intenta UPDATE directo en profiles para ponerse aprobado';
    expected := 'Bloqueado por trigger/privilegio de columna (inmutable desde cliente)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer_pend, 'role', 'authenticated')::text, true);
        UPDATE public.profiles SET verification_status = 'aprobado' WHERE id = c_buyer_pend;
        -- Verificar si realmente cambió
        SELECT verification_status INTO v_err_msg FROM public.profiles WHERE id = c_buyer_pend;
        IF v_err_msg = 'aprobado' THEN
            obtained := 'Permitido auto-aprobarse (Vulnerabilidad Crítica)';
            verdict := 'FALLIDO';
        ELSE
            obtained := 'No mutó el estado';
            verdict := 'APROBADO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 6.5: Auto-asignarse rol moderador
    test_code := '6.5';
    description := 'Usuario normal intenta UPDATE directo en profiles para asignarse rol moderador';
    expected := 'Bloqueado por trigger o regla de negocio';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_buyer1_id, 'role', 'authenticated')::text, true);
        UPDATE public.profiles SET role = 'moderador' WHERE id = c_buyer1_id;
        SELECT role::text INTO v_err_msg FROM public.profiles WHERE id = c_buyer1_id;
        IF v_err_msg = 'moderador' THEN
            obtained := 'Permitido auto-asignarse rol moderador (Vulnerabilidad Crítica)';
            verdict := 'FALLIDO';
        ELSE
            obtained := 'No mutó el rol';
            verdict := 'APROBADO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- 6.6: Modificar stock_total a un valor negativo o menor que comprometido
    test_code := '6.6';
    description := 'Agricultor intenta UPDATE de stock_total a un valor negativo (-100)';
    expected := 'Bloqueado por restricción CHECK chk_crops_stock_total_valid';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);
        UPDATE public.crops SET stock_total = -100 WHERE id = c_crop1_id;
        SELECT stock_total INTO v_stock_total FROM public.crops WHERE id = c_crop1_id;
        IF v_stock_total < 0 THEN
            obtained := 'Permitido stock negativo: ' || v_stock_total || ' (Vulnerabilidad de Integridad)';
            verdict := 'FALLIDO';
        ELSE
            obtained := 'No mutó';
            verdict := 'APROBADO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'APROBADO';
    END;
    RETURN NEXT;

    -- Reset session
    PERFORM set_config('role', 'postgres', true);

    -- Limpieza final
    DELETE FROM public.inventory_movements WHERE crop_id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.negotiation_offers WHERE sender_id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_third_id);
    DELETE FROM public.negotiations WHERE crop_id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.crops WHERE id IN (c_crop1_id, c_crop2_id);
    DELETE FROM public.profiles WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_buyer_ia, c_buyer_rech, c_buyer_susp, c_third_id);
    DELETE FROM auth.users WHERE id IN (c_farmer_id, c_buyer1_id, c_buyer2_id, c_buyer_pend, c_buyer_ia, c_buyer_rech, c_buyer_susp, c_third_id);

END;
$$;
