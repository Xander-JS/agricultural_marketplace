-- ============================================================================
-- SUITE DE AUDITORÍA AUTOMATIZADA: SEGURIDAD EN SUPABASE STORAGE Y CROP_IMAGES
-- PROYECTO: agricultural_marketplace (PostgreSQL / Supabase local)
-- ARCHIVO: test/sql/storage_security_and_crop_images_test.sql
-- ALCANCE: Fase 2 — Subetapa 2.1: Galería de imágenes y seguridad en Storage
--
-- OBJETIVO:
-- Demostrar de forma reproducible y transaccional que:
-- 1. En 'product_images', solo el dueño del cultivo (o un moderador) puede
--    insertar, sobrescribir (update) y eliminar archivos; usuarios ajenos
--    son bloqueados por RLS.
-- 2. En 'profiles', solo el usuario correspondiente a la carpeta auth.uid()
--    puede insertar, modificar o eliminar su avatar.
-- 3. La lectura en ambos buckets es pública.
-- 4. En la tabla 'public.crop_images', solo el propietario (o moderador)
--    puede actualizar ('is_primary') o eliminar registros.
--
-- EJECUCIÓN SEGURA (TRANSACCIÓN DESECHABLE):
--   BEGIN;
--   SELECT * FROM test_storage_security_audit_runner();
--   ROLLBACK;
-- ============================================================================

CREATE OR REPLACE FUNCTION test_storage_security_audit_runner()
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
    -- Identificadores de prueba aislados en rango c000... / d000...
    c_mod_id      uuid := 'c0000000-0000-0000-0000-000000000001';
    c_farmer_a_id uuid := 'c0000000-0000-0000-0000-000000000002';
    c_farmer_b_id uuid := 'c0000000-0000-0000-0000-000000000003';
    c_buyer_id    uuid := 'c0000000-0000-0000-0000-000000000004';

    c_crop_a_id   uuid := 'd0000000-0000-0000-0000-000000000001';
    c_crop_b_id   uuid := 'd0000000-0000-0000-0000-000000000002';

    c_crop_img_a  uuid := 'd0000000-0000-0000-0000-000000000010';
    c_crop_img_b  uuid := 'd0000000-0000-0000-0000-000000000020';

    c_obj_prod_a  uuid := 'd0000000-0000-0000-0000-000000000100';
    c_obj_prof_a  uuid := 'd0000000-0000-0000-0000-000000000200';

    v_err_code text;
    v_err_msg  text;
    v_count    int;
BEGIN
    -- ------------------------------------------------------------------------
    -- 0. PRE-CHECK ANTI-COLISIÓN Y SETUP DE PRUEBA
    -- ------------------------------------------------------------------------
    PERFORM set_config('role', 'postgres', true);
    PERFORM set_config('request.jwt.claims', '', true);

    IF EXISTS (
        SELECT 1 FROM auth.users
        WHERE id IN (c_mod_id, c_farmer_a_id, c_farmer_b_id, c_buyer_id)
    ) OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id IN (c_mod_id, c_farmer_a_id, c_farmer_b_id, c_buyer_id)
    ) OR EXISTS (
        SELECT 1 FROM public.crops
        WHERE id IN (c_crop_a_id, c_crop_b_id)
    ) THEN
        RAISE EXCEPTION 'SETUP_ERROR: Colisión detectada con identificadores de prueba en auth.users, profiles o crops. Operación abortada para no alterar datos existentes.'
            USING ERRCODE = 'P0004';
    END IF;

    -- Inserción en auth.users
    INSERT INTO auth.users (id, email) VALUES
        (c_mod_id, 'mod_storage_test@agromarket.com'),
        (c_farmer_a_id, 'farmer_a_storage_test@agromarket.com'),
        (c_farmer_b_id, 'farmer_b_storage_test@agromarket.com'),
        (c_buyer_id, 'buyer_storage_test@agromarket.com');

    -- Inserción en profiles
    INSERT INTO public.profiles (id, phone, role, verification_status, full_name, email) VALUES
        (c_mod_id, '+573980000001', 'moderador', 'aprobado', 'Moderador Storage', 'mod_storage_test@agromarket.com'),
        (c_farmer_a_id, '+573980000002', 'agricultor', 'aprobado', 'Agricultor A Legítimo', 'farmer_a_storage_test@agromarket.com'),
        (c_farmer_b_id, '+573980000003', 'agricultor', 'aprobado', 'Agricultor B Rival', 'farmer_b_storage_test@agromarket.com'),
        (c_buyer_id, '+573980000004', 'comprador', 'aprobado', 'Comprador Storage', 'buyer_storage_test@agromarket.com');

    -- Inserción de cosechas de prueba
    INSERT INTO public.crops (id, farmer_id, title, description, crop_type, price_per_kg, stock_total, min_order_kg, department, municipality, status) VALUES
        (c_crop_a_id, c_farmer_a_id, 'Café Especial A', 'Café lavado de altura', 'Café', 18000, 500, 10, 'Antioquia', 'Fredonia', 'activa'),
        (c_crop_b_id, c_farmer_b_id, 'Aguacate Hass B', 'Aguacate de exportación', 'Aguacate', 6000, 300, 5, 'Antioquia', 'Sonsón', 'activa');

    -- Inserción de metadatos de imágenes en public.crop_images
    INSERT INTO public.crop_images (id, crop_id, image_path, is_primary) VALUES
        (c_crop_img_a, c_crop_a_id, c_crop_a_id::text || '/img_a_1.jpg', true),
        (c_crop_img_b, c_crop_b_id, c_crop_b_id::text || '/img_b_1.jpg', true);


    -- ========================================================================
    -- ESCENARIO 1: SEGURIDAD EN BUCKET 'product_images'
    -- ========================================================================

    -- SEC-PROD-01: Propietario (Agricultor A) sube imagen a su propio cultivo
    scenario := 'product_images: Subida de imágenes';
    test_code := 'SEC-PROD-01';
    description := 'Agricultor A (propietario) sube imagen a su carpeta de cultivo';
    expected := 'ÉXITO (1 fila insertada en storage.objects)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_a_id::text, true);

        INSERT INTO storage.objects (id, bucket_id, name, owner)
        VALUES (c_obj_prod_a, 'product_images', c_crop_a_id::text || '/img_a_1.jpg', c_farmer_a_id);

        obtained := 'ÉXITO (1 fila insertada en storage.objects)';
        verdict := 'PASÓ';
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROD-02: Agricultor rival (B) intenta subir imagen al cultivo de A (Bloqueo RLS)
    scenario := 'product_images: Intento de subida no autorizada';
    test_code := 'SEC-PROD-02';
    description := 'Agricultor B intenta subir imagen al cultivo del Agricultor A';
    expected := 'BLOQUEADO_RLS (SQLSTATE 42501)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        INSERT INTO storage.objects (id, bucket_id, name, owner)
        VALUES (gen_random_uuid(), 'product_images', c_crop_a_id::text || '/hacked.jpg', c_farmer_b_id);

        obtained := 'VULNERABILIDAD: Inserción ajena no autorizada fue permitida';
        verdict := 'FALLÓ';
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (SQLSTATE 42501)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROD-03: Agricultor rival (B) intenta sobrescribir (UPDATE) la imagen de A
    scenario := 'product_images: Intento de sobrescritura ajena';
    test_code := 'SEC-PROD-03';
    description := 'Agricultor B intenta modificar/sobrescribir la imagen del Agricultor A';
    expected := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        UPDATE storage.objects
        SET metadata = '{"tampered": true}'::jsonb
        WHERE id = c_obj_prod_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' fila(s) ajenas modificadas';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROD-04: Agricultor rival (B) intenta borrar (DELETE) la imagen de A
    scenario := 'product_images: Intento de borrado ajeno';
    test_code := 'SEC-PROD-04';
    description := 'Agricultor B intenta eliminar la imagen de cultivo del Agricultor A';
    expected := 'BLOQUEADO_RLS (0 filas eliminadas)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);
        -- Simulación del contexto interno de Supabase Storage API al invocar remove()
        PERFORM set_config('storage.allow_delete_query', 'true', true);

        DELETE FROM storage.objects WHERE id = c_obj_prod_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' fila(s) ajenas eliminadas';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROD-05: Lectura pública de imagen de producto
    scenario := 'product_images: Lectura pública';
    test_code := 'SEC-PROD-05';
    description := 'Usuario anónimo (anon) o visitante consulta la imagen del catálogo';
    expected := 'LECTURA_PERMITIDA (1 fila visible)';
    BEGIN
        PERFORM set_config('role', 'anon', true);
        PERFORM set_config('request.jwt.claim.sub', '', true);

        SELECT count(*) INTO v_count
        FROM storage.objects
        WHERE id = c_obj_prod_a;

        IF v_count = 1 THEN
            obtained := 'LECTURA_PERMITIDA (1 fila visible)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'ERROR: 0 filas visibles para lectura pública';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROD-06: Moderador elimina imagen indebida de cultivo
    scenario := 'product_images: Moderación de imágenes';
    test_code := 'SEC-PROD-06';
    description := 'Moderador certificado elimina imagen de cultivo por reporte/auditoría';
    expected := 'ÉXITO (1 fila eliminada por moderador)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_mod_id::text, true);
        -- Simulación del contexto interno de Supabase Storage API al invocar remove()
        PERFORM set_config('storage.allow_delete_query', 'true', true);

        DELETE FROM storage.objects WHERE id = c_obj_prod_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 1 THEN
            obtained := 'ÉXITO (1 fila eliminada por moderador)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'ERROR: Moderador no pudo eliminar el archivo (filas: ' || v_count || ')';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 2: SEGURIDAD EN BUCKET 'profiles'
    -- ========================================================================

    -- SEC-PROF-01: Usuario A sube su propio avatar
    scenario := 'profiles: Subida de avatar propio';
    test_code := 'SEC-PROF-01';
    description := 'Usuario A sube avatar a su propia carpeta (user_a/avatar.jpg)';
    expected := 'ÉXITO (1 fila insertada en storage.objects)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_a_id::text, true);

        INSERT INTO storage.objects (id, bucket_id, name, owner)
        VALUES (c_obj_prof_a, 'profiles', c_farmer_a_id::text || '/avatar.jpg', c_farmer_a_id);

        obtained := 'ÉXITO (1 fila insertada en storage.objects)';
        verdict := 'PASÓ';
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROF-02: Usuario B intenta subir avatar a la carpeta de Usuario A
    scenario := 'profiles: Intento de suplantación de avatar';
    test_code := 'SEC-PROF-02';
    description := 'Usuario B intenta subir avatar a la carpeta de Usuario A';
    expected := 'BLOQUEADO_RLS (SQLSTATE 42501)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        INSERT INTO storage.objects (id, bucket_id, name, owner)
        VALUES (gen_random_uuid(), 'profiles', c_farmer_a_id::text || '/avatar_fake.jpg', c_farmer_b_id);

        obtained := 'VULNERABILIDAD: Usuario B pudo escribir en carpeta de Usuario A';
        verdict := 'FALLÓ';
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (SQLSTATE 42501)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROF-03: Usuario B intenta sobrescribir (UPDATE) el avatar de A
    scenario := 'profiles: Intento de sobrescritura de avatar ajeno';
    test_code := 'SEC-PROF-03';
    description := 'Usuario B intenta modificar el archivo de avatar de Usuario A';
    expected := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        UPDATE storage.objects
        SET metadata = '{"tampered": true}'::jsonb
        WHERE id = c_obj_prof_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' avatar ajeno modificado';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas afectadas / 42501)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROF-04: Usuario B intenta borrar (DELETE) el avatar de A
    scenario := 'profiles: Intento de borrado de avatar ajeno';
    test_code := 'SEC-PROF-04';
    description := 'Usuario B intenta eliminar el avatar de Usuario A';
    expected := 'BLOQUEADO_RLS (0 filas eliminadas)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);
        PERFORM set_config('storage.allow_delete_query', 'true', true);

        DELETE FROM storage.objects WHERE id = c_obj_prof_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' avatar ajeno eliminado';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-PROF-05: Usuario A borra su propio avatar legítimamente
    scenario := 'profiles: Borrado de avatar propio';
    test_code := 'SEC-PROF-05';
    description := 'Usuario A elimina su propio avatar de su carpeta';
    expected := 'ÉXITO (1 fila eliminada)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_a_id::text, true);
        PERFORM set_config('storage.allow_delete_query', 'true', true);

        DELETE FROM storage.objects WHERE id = c_obj_prof_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 1 THEN
            obtained := 'ÉXITO (1 fila eliminada)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'ERROR: 0 filas eliminadas para el propietario';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;


    -- ========================================================================
    -- ESCENARIO 3: SEGURIDAD Y PERMISOS EN public.crop_images
    -- ========================================================================

    -- SEC-TBL-01: Propietario (Agricultor A) actualiza 'is_primary' en public.crop_images
    scenario := 'crop_images: Actualización de imagen principal';
    test_code := 'SEC-TBL-01';
    description := 'Agricultor A actualiza is_primary = false en imagen propia';
    expected := 'ÉXITO (1 fila actualizada por el propietario)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_a_id::text, true);

        UPDATE public.crop_images
        SET is_primary = false
        WHERE id = c_crop_img_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 1 THEN
            obtained := 'ÉXITO (1 fila actualizada por el propietario)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'ERROR: Fila no actualizada (filas: ' || v_count || ')';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-TBL-02: Agricultor rival (B) intenta actualizar 'is_primary' en cultivo de A
    scenario := 'crop_images: Intento de actualización ajena';
    test_code := 'SEC-TBL-02';
    description := 'Agricultor B intenta modificar is_primary en imagen de Agricultor A';
    expected := 'BLOQUEADO_RLS (0 filas actualizadas)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        UPDATE public.crop_images
        SET is_primary = true
        WHERE id = c_crop_img_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas actualizadas)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' fila ajena actualizada';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas actualizadas)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-TBL-03: Agricultor rival (B) intenta borrar registro en public.crop_images de A
    scenario := 'crop_images: Intento de borrado ajeno';
    test_code := 'SEC-TBL-03';
    description := 'Agricultor B intenta borrar registro de imagen perteneciente al cultivo de A';
    expected := 'BLOQUEADO_RLS (0 filas eliminadas)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_farmer_b_id::text, true);

        DELETE FROM public.crop_images WHERE id = c_crop_img_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 0 THEN
            obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'VULNERABILIDAD: ' || v_count || ' fila ajena eliminada';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        obtained := 'BLOQUEADO_RLS (0 filas eliminadas)';
        verdict := 'PASÓ';
    WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

    -- SEC-TBL-04: Moderador elimina registro en public.crop_images
    scenario := 'crop_images: Borrado por moderador';
    test_code := 'SEC-TBL-04';
    description := 'Moderador certificado elimina registro en crop_images de cultivo reportado';
    expected := 'ÉXITO (1 fila eliminada por moderador)';
    BEGIN
        PERFORM set_config('role', 'authenticated', true);
        PERFORM set_config('request.jwt.claim.sub', c_mod_id::text, true);

        DELETE FROM public.crop_images WHERE id = c_crop_img_a;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        IF v_count = 1 THEN
            obtained := 'ÉXITO (1 fila eliminada por moderador)';
            verdict := 'PASÓ';
        ELSE
            obtained := 'ERROR: Moderador no pudo eliminar el registro (filas: ' || v_count || ')';
            verdict := 'FALLÓ';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        obtained := 'ERROR_INESPERADO: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        verdict := 'FALLÓ';
    END;
    RETURN NEXT;

END;
$$;

-- Permisos del runner
ALTER FUNCTION test_storage_security_audit_runner() OWNER TO postgres;
REVOKE ALL ON FUNCTION test_storage_security_audit_runner() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION test_storage_security_audit_runner() TO postgres;
