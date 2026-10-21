-- ============================================================================
-- SUITE DE AUDITORÍA AUTOMATIZADA: MODERACIÓN, RLS Y RPCs DE SEGURIDAD
-- PROYECTO: agricultural_marketplace (PostgreSQL / Supabase local)
-- ARCHIVO: test/sql/moderation_rpcs_and_security_test.sql
-- ALCANCE: Fase 1 — Subetapa 1.5: Backend de Moderación
--
-- ADVERTENCIA METODOLÓGICA Y TAXONOMÍA DE ENTORNOS:
-- 1. set_config('role', 'authenticated', true) dentro de una función PL/pgSQL
--    simula el identificador de rol para RLS en consultas dinámicas (EXECUTE),
--    pero NO equivale a una sesión de red auténtica de PostgREST.
--    PostgREST administra transacciones HTTP independientes con directivas
--    SET LOCAL a nivel de conexión y valida firmas JWT criptográficas en cada petición.
-- 2. Las pruebas que implican contención concurrente (2 conexiones simultáneas)
--    y las pruebas de interfaz HTTP/PostgREST NO pueden ejecutarse dentro de
--    un único proceso PL/pgSQL. Por consiguiente, esta suite se estructura en
--    secciones claramente delimitadas.
--
-- ESTRUCTURA DEL DOCUMENTO DE PRUEBAS:
-- [SECCIÓN 1]: Runner SQL Unitario y de Integridad (Transacción desechable ROLLBACK)
--              Ejecutable como superusuario / postgres en entorno local.
-- [SECCIÓN 2]: Pruebas RLS y Privilegios en Sesión Independiente (SET ROLE auténtico)
-- [SECCIÓN 3]: Pruebas RPC con claims JWT auténticos
-- [SECCIÓN 4]: Pruebas de Concurrencia (2 Conexiones simultáneas - CON-01) [PENDIENTE]
-- [SECCIÓN 5]: Pruebas de Interfaz HTTP / PostgREST (HTTP-01) [PENDIENTE]
-- ============================================================================


-- ============================================================================
-- SECCIÓN 1: RUNNER SQL UNITARIO Y DE INTEGRIDAD (TRANSACCIÓN DESECHABLE)
-- ============================================================================
-- Modo de ejecución segura y no destructiva:
--   BEGIN;
--   SELECT * FROM test_moderation_audit_runner();
--   ROLLBACK;
-- ============================================================================

CREATE OR REPLACE FUNCTION test_moderation_audit_runner()
RETURNS TABLE (
    scenario text,
    test_code text,
    description text,
    expected text,
    obtained text,
    verdict text
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    -- Identificadores de prueba aislados (rango e0000000 / f0000000)
    c_mod_id      uuid := 'e0000000-0000-0000-0000-000000000001';
    c_farmer_id   uuid := 'e0000000-0000-0000-0000-000000000002';
    c_buyer_id    uuid := 'e0000000-0000-0000-0000-000000000003';
    c_other_id    uuid := 'e0000000-0000-0000-0000-000000000004';
    c_susp_id     uuid := 'e0000000-0000-0000-0000-000000000005';
    c_obs_user_id uuid := 'e0000000-0000-0000-0000-000000000006';

    v_att_farmer1  uuid := 'f0000000-0000-0000-0000-000000000001';
    v_att_buyer    uuid := 'f0000000-0000-0000-0000-000000000002';
    v_att_susp     uuid := 'f0000000-0000-0000-0000-000000000003';
    v_att_obs_old  uuid := 'f0000000-0000-0000-0000-000000000004';
    v_att_obs_new  uuid := 'f0000000-0000-0000-0000-000000000005';

    v_err_code text;
    v_err_msg text;
    v_count int;
    v_json jsonb;
    v_prof_status public.user_verification_status;
    v_att_status public.user_verification_status;
    v_rejection_reason text;
BEGIN
    -- ------------------------------------------------------------------------
    -- 0. PRE-CHECK ANTI-COLISIÓN Y SETUP ADMINISTRATIVO
    -- ------------------------------------------------------------------------
    -- Garantía no-destructiva: NO se eliminan datos a ciegas. Si algún ID de prueba
    -- ya existe en el sistema, la preparación ABORTA de inmediato con una excepción.
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);

    IF EXISTS (
        SELECT 1 FROM auth.users
        WHERE id IN (c_mod_id, c_farmer_id, c_buyer_id, c_other_id, c_susp_id, c_obs_user_id)
    ) OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id IN (c_mod_id, c_farmer_id, c_buyer_id, c_other_id, c_susp_id, c_obs_user_id)
    ) OR EXISTS (
        SELECT 1 FROM public.verification_attempts
        WHERE id IN (v_att_farmer1, v_att_buyer, v_att_susp, v_att_obs_old, v_att_obs_new)
    ) THEN
        RAISE EXCEPTION 'SETUP_ERROR: Colisión detectada con identificadores de prueba en auth.users, profiles o verification_attempts. Operación abortada para no alterar datos existentes.'
            USING ERRCODE = 'P0004';
    END IF;

    -- Inserción de usuarios de prueba en auth.users
    INSERT INTO auth.users (id, email) VALUES
        (c_mod_id, 'mod_test@agromarket.com'),
        (c_farmer_id, 'farmer_test@agromarket.com'),
        (c_buyer_id, 'buyer_test@agromarket.com'),
        (c_other_id, 'other_test@agromarket.com'),
        (c_susp_id, 'susp_test@agromarket.com'),
        (c_obs_user_id, 'obs_test@agromarket.com');

    -- Inserción de perfiles de prueba en public.profiles
    INSERT INTO public.profiles (id, phone, role, verification_status, full_name, email) VALUES
        (c_mod_id, '+573990000001', 'moderador', 'aprobado', 'Moderador Certificado', 'mod_test@agromarket.com'),
        (c_farmer_id, '+573990000002', 'agricultor', 'pendiente', 'Agricultor Solicitante', 'farmer_test@agromarket.com'),
        (c_buyer_id, '+573990000003', 'comprador', 'pendiente', 'Comprador Solicitante', 'buyer_test@agromarket.com'),
        (c_other_id, '+573990000004', 'comprador', 'pendiente', 'Usuario Sin Solicitud', 'other_test@agromarket.com'),
        (c_susp_id, '+573990000005', 'agricultor', 'suspendido', 'Usuario Suspendido', 'susp_test@agromarket.com'),
        (c_obs_user_id, '+573990000006', 'comprador', 'pendiente', 'Usuario Con Reintento', 'obs_test@agromarket.com');

    -- Inserción de fixtures de verificación:
    INSERT INTO public.verification_attempts (id, user_id, status, document_front_path, created_at) VALUES
        (v_att_farmer1, c_farmer_id, 'pendiente', 'docs/farmer_1.jpg', '2026-10-18 10:00:00+00'),
        (v_att_buyer, c_buyer_id, 'pendiente', 'docs/buyer_1.jpg', '2026-10-18 10:30:00+00'),
        (v_att_susp, c_susp_id, 'pendiente', 'docs/susp_1.jpg', '2026-10-18 10:45:00+00'),
        -- Para prueba de anti-obsolescencia (RPC-05):
        -- Intento antiguo resuelto a 'rechazado' (10:00) y nuevo intento 'pendiente' (12:00) para el mismo usuario.
        -- No viola el índice único parcial porque solo v_att_obs_new está en ('pendiente', 'en_revision_ia').
        (v_att_obs_old, c_obs_user_id, 'rechazado', 'docs/obs_old.jpg', '2026-10-18 10:00:00+00'),
        (v_att_obs_new, c_obs_user_id, 'pendiente', 'docs/obs_new.jpg', '2026-10-18 12:00:00+00');


    -- ========================================================================
    -- BLOQUE 1: PRIVILEGIOS DE COLUMNA Y POLÍTICAS RLS
    -- ========================================================================
    scenario := 'Permisos y RLS verification_attempts';

    -- 1.1: Privilegios de columna en INSERT (PRV-01)
    test_code := 'PRV-01';
    description := 'Cliente autenticado intenta insertar columna restringida de moderación (reviewed_by)';
    expected := 'Error 42501 (permission denied for column)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        EXECUTE 'INSERT INTO public.verification_attempts (user_id, status, reviewed_by) VALUES ($1, ''pendiente'', $2)'
        USING c_farmer_id, c_mod_id;

        obtained := 'Vulnerabilidad: INSERT en reviewed_by permitido sin restricción';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 1.2: Aislamiento de lectura RLS (RLS-01)
    test_code := 'RLS-01';
    description := 'Agricultor consulta verification_attempts (debe ver exclusivamente su propia solicitud)';
    expected := 'Visible exactamente 1 fila propia (v_att_farmer1)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        EXECUTE 'SELECT count(*) FROM public.verification_attempts' INTO v_count;

        IF v_count = 1 THEN
            obtained := 'Aislamiento correcto: 1 fila visible';
            verdict := 'APROBADO';
        ELSE
            obtained := 'Filtro RLS comprometido: ' || v_count || ' filas devueltas';
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 1.3: Bloqueo de UPDATE directo por cliente (RLS-02)
    test_code := 'RLS-02';
    description := 'Cliente autenticado intenta UPDATE directo sobre verification_attempts';
    expected := 'Bloqueado con error 42501 (permisos o trigger de protección)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        EXECUTE 'UPDATE public.verification_attempts SET status = ''aprobado'' WHERE id = $1' USING v_att_farmer1;

        obtained := 'Vulnerabilidad: UPDATE directo permitido';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 1.4: Bloqueo de DELETE directo por cliente (RLS-03)
    test_code := 'RLS-03';
    description := 'Cliente autenticado intenta DELETE directo sobre verification_attempts';
    expected := 'Bloqueado con error 42501 (permisos o trigger de protección)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        EXECUTE 'DELETE FROM public.verification_attempts WHERE id = $1' USING v_att_farmer1;

        obtained := 'Vulnerabilidad: DELETE directo permitido';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 1.5: Bloqueo de creación de solicitud para perfil ya aprobado (RLS-04)
    test_code := 'RLS-04';
    description := 'Usuario con perfil en estado aprobado intenta registrar nueva solicitud';
    expected := 'Bloqueado con error 42501 (perfil ya aprobado)';
    BEGIN
        -- c_mod_id posee verification_status = 'aprobado'
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        EXECUTE 'INSERT INTO public.verification_attempts (user_id, status, document_front_path) VALUES ($1, ''pendiente'', ''docs/illegal.jpg'')'
        USING c_mod_id;

        obtained := 'Vulnerabilidad: usuario ya aprobado pudo insertar nueva solicitud';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 1.6: Menor privilegio en profiles para moderador (POLP-01)
    test_code := 'POLP-01';
    description := 'Moderador consulta profiles: usuario sin solicitudes en verification_attempts debe ser invisible';
    expected := 'c_other_id es invisible para el moderador (0 filas devueltas)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        -- c_other_id no tiene filas en verification_attempts ni publicaciones de cosechas ni negociaciones
        EXECUTE 'SELECT count(*) FROM public.profiles WHERE id = $1' INTO v_count USING c_other_id;

        IF v_count = 0 THEN
            obtained := 'Menor privilegio garantizado: usuario sin solicitud permanece invisible';
            verdict := 'APROBADO';
        ELSE
            obtained := 'Fuga PoLP: usuario sin solicitud es visible para el moderador';
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;


    -- ========================================================================
    -- BLOQUE 2: REGLAS DE NEGOCIO Y RPCs DE MODERACIÓN
    -- ========================================================================
    scenario := 'RPCs de Moderación y Consistencia';

    -- 2.1: Denegación de RPC para rol no autorizado (RPC-01)
    test_code := 'RPC-01';
    description := 'Agricultor intenta invocar approve_verification_attempt';
    expected := 'Error 42501 (se requiere rol de moderador)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_farmer_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        PERFORM public.approve_verification_attempt(v_att_farmer1);

        obtained := 'Vulnerabilidad: usuario no moderador pudo aprobar solicitud';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '42501' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.2: Aprobación atómica válida (RPC-02)
    test_code := 'RPC-02';
    description := 'Moderador aprueba solicitud legítima v_att_farmer1';
    expected := 'Ambas tablas (verification_attempts y profiles) actualizadas atómicamente a aprobado';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        v_json := public.approve_verification_attempt(v_att_farmer1);

        SELECT status INTO v_att_status FROM public.verification_attempts WHERE id = v_att_farmer1;
        SELECT verification_status INTO v_prof_status FROM public.profiles WHERE id = c_farmer_id;

        IF v_att_status = 'aprobado' AND v_prof_status = 'aprobado' AND (v_json->>'success')::boolean = true THEN
            obtained := 'Aprobación atómica verificada en ambas tablas. Status: ' || (v_json->>'status');
            verdict := 'APROBADO';
        ELSE
            obtained := 'Inconsistencia de estado: attempt=' || COALESCE(v_att_status::text, 'NULL') || ', profile=' || COALESCE(v_prof_status::text, 'NULL');
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.3: Rechazo atómico con motivo obligatorio (RPC-03)
    test_code := 'RPC-03';
    description := 'Moderador rechaza v_att_buyer registrando motivo obligatorio';
    expected := 'Ambas tablas en rechazado, motivo almacenado y auditoría registrada';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        v_json := public.reject_verification_attempt(v_att_buyer, 'Cédula borrosa en anverso');

        SELECT status, rejection_reason INTO v_att_status, v_rejection_reason FROM public.verification_attempts WHERE id = v_att_buyer;
        SELECT verification_status INTO v_prof_status FROM public.profiles WHERE id = c_buyer_id;

        IF v_att_status = 'rechazado'
           AND v_prof_status = 'rechazado'
           AND v_rejection_reason = 'Cédula borrosa en anverso'
           AND (v_json->>'reason') = 'Cédula borrosa en anverso' THEN
            obtained := 'Rechazo atómico verificado con motivo consistente en ambas tablas';
            verdict := 'APROBADO';
        ELSE
            obtained := 'Inconsistencia de estado o motivo: attempt=' || COALESCE(v_att_status::text, 'NULL') || ', profile=' || COALESCE(v_prof_status::text, 'NULL');
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.4: Bloqueo de re-resolución de solicitud ya aprobada (RPC-04)
    test_code := 'RPC-04';
    description := 'Moderador intenta aprobar nuevamente una solicitud ya aprobada (v_att_farmer1)';
    expected := 'Error 22000 (ya fue aprobada previamente)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        PERFORM public.approve_verification_attempt(v_att_farmer1);

        obtained := 'Vulnerabilidad: se permitió re-aprobar una solicitud ya resuelta';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '22000' THEN verdict := 'APROBADO'; ELSE verdict := 'FALLIDO'; END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.5: Anti-obsolescencia estricta bajo bloqueo (RPC-05)
    test_code := 'RPC-05';
    description := 'Moderador intenta resolver solicitud antigua (v_att_obs_old) existiendo un intento posterior (v_att_obs_new)';
    expected := 'Error 22000 conteniendo mensaje de solicitud obsoleta';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        -- v_att_obs_old (10:00, rechazado) tiene el intento posterior v_att_obs_new (12:00, pendiente).
        -- Intentar resolver v_att_obs_old debe abortar de inmediato por anti-obsolescencia estricta en el paso 8.
        PERFORM public.approve_verification_attempt(v_att_obs_old);

        obtained := 'Vulnerabilidad: se permitió resolver una solicitud obsoleta';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '22000' AND v_err_msg ILIKE '%obsoleta%' THEN
            verdict := 'APROBADO';
        ELSIF v_err_code = '22000' THEN
            obtained := obtained || ' (Alerta: error 22000 pero mensaje inesperado)';
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.6: Protección de perfiles suspendidos administrativamente (RPC-06)
    test_code := 'RPC-06';
    description := 'Moderador intenta aprobar solicitud asociada a un perfil suspendido (v_att_susp)';
    expected := 'Error 22000 (perfil suspendido no puede alterarse por moderación ordinaria)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        PERFORM public.approve_verification_attempt(v_att_susp);

        obtained := 'Vulnerabilidad: moderación ordinaria alteró un perfil suspendido';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '22000' AND v_err_msg ILIKE '%suspendido%' THEN
            verdict := 'APROBADO';
        ELSIF v_err_code = '22000' THEN
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.7: Índice parcial único anti-spam (IDX-01)
    test_code := 'IDX-01';
    description := 'Usuario intenta insertar segunda solicitud pendiente simultánea (anti-spam)';
    expected := 'Error 23505 (unique_violation por uq_verification_attempts_pending_user)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_obs_user_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        -- c_obs_user_id ya posee v_att_obs_new en estado 'pendiente'
        EXECUTE 'INSERT INTO public.verification_attempts (user_id, status, document_front_path) VALUES ($1, ''pendiente'', ''path/dup.jpg'')'
        USING c_obs_user_id;

        obtained := 'Vulnerabilidad: se permitieron dos solicitudes pendientes simultáneas para el mismo usuario';
        verdict := 'FALLIDO';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Bloqueado: ' || v_err_code || ' - ' || v_err_msg;
        IF v_err_code = '23505' THEN
            verdict := 'APROBADO';
        ELSIF v_err_code = '42501' THEN
            obtained := obtained || ' (Bloqueado por capa RLS/Trigger)';
            verdict := 'APROBADO';
        ELSE
            verdict := 'FALLIDO';
        END IF;
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- 2.8: RPC de lectura de cola de moderación (RPC-QUEUE)
    test_code := 'RPC-QUEUE';
    description := 'Moderador consulta la cola mediante get_moderation_queue (proyección acotada PoLP)';
    expected := 'Devuelve arreglo JSON con campos indispensables y perfil anidado';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claims', json_build_object('sub', c_mod_id, 'role', 'authenticated')::text, true);

        IF current_user <> 'authenticated' THEN
            RAISE EXCEPTION 'Aislamiento fallido: current_user (%) no es authenticated', current_user USING ERRCODE = 'XX000';
        END IF;

        v_json := public.get_moderation_queue('pendiente', 10, 0);

        IF jsonb_array_length(v_json) >= 1
           AND v_json->0 ? 'id'
           AND v_json->0 ? 'user_id'
           AND v_json->0 ? 'profiles'
           AND (v_json->0->'profiles') ? 'full_name' THEN
            obtained := 'Cola obtenida correctamente: ' || jsonb_array_length(v_json) || ' elementos estructurados';
            verdict := 'APROBADO';
        ELSE
            obtained := 'Estructura inesperada en cola: ' || v_json::text;
            verdict := 'FALLIDO';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_code = RETURNED_SQLSTATE, v_err_msg = MESSAGE_TEXT;
        obtained := 'Error: ' || v_err_code || ' - ' || v_err_msg;
        verdict := 'FALLIDO';
    END;
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);
    RETURN NEXT;

    -- ------------------------------------------------------------------------
    -- TEARDOWN SEGURO (Limpia estrictamente los registros insertados en el runner)
    -- ------------------------------------------------------------------------
    DELETE FROM public.verification_attempts WHERE id IN (v_att_farmer1, v_att_buyer, v_att_susp, v_att_obs_old, v_att_obs_new);
    DELETE FROM public.profiles WHERE id IN (c_mod_id, c_farmer_id, c_buyer_id, c_other_id, c_susp_id, c_obs_user_id);
    DELETE FROM auth.users WHERE id IN (c_mod_id, c_farmer_id, c_buyer_id, c_other_id, c_susp_id, c_obs_user_id);
END;
$$;


-- ============================================================================
-- SECCIÓN 2: PRUEBAS RLS EN SESIÓN INDEPENDIENTE (SET ROLE AUTÉNTICO)
-- ============================================================================
-- Instrucciones para ejecución manual en cliente psql independiente:
--
-- 1. Iniciar sesión como superusuario:
--    psql -h localhost -p 54322 -U postgres -d postgres
--
-- 2. Conmutar a authenticated y verificar restricción estricta de columnas:
--    BEGIN;
--    SET ROLE authenticated;
--    SET request.jwt.claims TO '{"sub": "e0000000-0000-0000-0000-000000000002", "role": "authenticated"}';
--    -- Intento de UPDATE directo (debe fallar con error 42501):
--    UPDATE public.verification_attempts SET status = 'aprobado' WHERE id = 'f0000000-0000-0000-0000-000000000001';
--    ROLLBACK;
-- ============================================================================


-- ============================================================================
-- SECCIÓN 3: PRUEBAS DE RPC CON CLAIMS JWT EN SESIÓN DEDICADA
-- ============================================================================
-- Instrucciones para validar RPC con claims JWT:
--
--    BEGIN;
--    SET ROLE authenticated;
--    SET request.jwt.claims TO '{"sub": "e0000000-0000-0000-0000-000000000001", "role": "authenticated"}';
--    -- Como moderador, aprobar solicitud:
--    SELECT public.approve_verification_attempt('f0000000-0000-0000-0000-000000000001');
--    -- Verificar que ambos registros quedaron en aprobado:
--    SELECT status FROM public.verification_attempts WHERE id = 'f0000000-0000-0000-0000-000000000001';
--    SELECT verification_status FROM public.profiles WHERE id = 'e0000000-0000-0000-0000-000000000002';
--    ROLLBACK;
-- ============================================================================


-- ============================================================================
-- SECCIÓN 4: PROTOCOLO DE CONCURRENCIA (2 CONEXIONES SIMULTÁNEAS) [PENDIENTE]
-- ============================================================================
-- Escenario CON-01: Dos moderadores intentan resolver la misma solicitud concurrentemente.
--
-- Terminal 1 (Moderador 1):
--   BEGIN;
--   SET ROLE authenticated;
--   SET request.jwt.claims TO '{"sub": "e0000000-0000-0000-0000-000000000001", "role": "authenticated"}';
--   SELECT public.approve_verification_attempt('f0000000-0000-0000-0000-000000000002');
--   -- NO EJECUTAR COMMIT TODAVÍA (mantiene el bloqueo FOR UPDATE sobre profiles y attempt).
--
-- Terminal 2 (Moderador 2):
--   BEGIN;
--   SET ROLE authenticated;
--   SET request.jwt.claims TO '{"sub": "e0000000-0000-0000-0000-000000000001", "role": "authenticated"}';
--   SELECT public.reject_verification_attempt('f0000000-0000-0000-0000-000000000002', 'Cédula ilegible');
--   -- Se queda bloqueado esperando la liberación del cerrojo FOR UPDATE del perfil.
--
-- Resolución:
--   Terminal 1: COMMIT;
--   Terminal 2: Se desbloquea de inmediato y aborta con excepción SQLSTATE 22000
--               ("La solicitud de verificación ya fue aprobada previamente").
--   Terminal 2: ROLLBACK;
-- Resultado esperado: Serialización perfecta; ninguna inconsistencia entre perfiles e intentos.
-- ============================================================================


-- ============================================================================
-- SECCIÓN 5: PROTOCOLO DE PRUEBAS HTTP / POSTGREST [PENDIENTE]
-- ============================================================================
-- Escenario HTTP-01: Invocación RPC vía PostgREST con token JWT válido e inválido.
--
-- 1. Petición anónima (sin Authorization):
--    curl -X POST "http://127.0.0.1:54321/rest/v1/rpc/approve_verification_attempt" \
--         -H "apikey: <ANON_KEY>" \
--         -H "Content-Type: application/json" \
--         -d '{"p_attempt_id": "f0000000-0000-0000-0000-000000000001"}'
--    Respuesta esperada: HTTP 401 Unauthorized o 403 Forbidden (SQLSTATE 28000 / 42501).
--
-- 2. Petición con JWT de agricultor (rol comercial):
--    curl -X POST "http://127.0.0.1:54321/rest/v1/rpc/approve_verification_attempt" \
--         -H "apikey: <ANON_KEY>" \
--         -H "Authorization: Bearer <FARMER_JWT>" \
--         -H "Content-Type: application/json" \
--         -d '{"p_attempt_id": "f0000000-0000-0000-0000-000000000001"}'
--    Respuesta esperada: HTTP 403 Forbidden (SQLSTATE 42501: se requiere rol de moderador).
-- ============================================================================
