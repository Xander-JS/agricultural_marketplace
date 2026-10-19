-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261016210000_moderation_rpcs_and_security.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase/PostgreSQL)
-- ALCANCE: Fase 1 — Subetapa 1.5: Backend de Moderación
--
-- DIAGNÓSTICO PREVENTIVO DE DATOS HISTÓRICOS (Solo lectura):
-- Antes de aplicar esta migración, verificar que no existan solicitudes duplicadas:
--   SELECT user_id, count(*)
--   FROM public.verification_attempts
--   WHERE status IN ('pendiente', 'en_revision_ia')
--   GROUP BY user_id HAVING count(*) > 1;
-- (Auditoría previa confirmó 0 filas duplicadas en el entorno local).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. FUNCIÓN DE COMPROBACIÓN DE ROL: public.is_moderator()
-- ----------------------------------------------------------------------------
-- Garantías:
-- - SECURITY DEFINER con OWNER TO postgres: omite RLS de profiles (relforcerowsecurity=false),
--   evitando totalmente la recursión infinita (SQLSTATE 42P17).
-- - Sin parámetros: utiliza estrictamente auth.uid(), previniendo suplantación de identidad.
-- - search_path endurecido (pg_catalog, public, pg_temp): neutraliza ataques de inyección.
-- - STABLE: permite evaluación única por consulta en filtros de lotes.
CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_role public.user_role;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = auth.uid();

  RETURN COALESCE(v_role = 'moderador'::public.user_role, false);
END;
$$;

ALTER FUNCTION public.is_moderator() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.is_moderator() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_moderator() TO authenticated, service_role;

COMMENT ON FUNCTION public.is_moderator() IS
  'Comprueba de forma segura y sin recursión si el usuario autenticado posee el rol de moderador.';


-- ----------------------------------------------------------------------------
-- 2. SEGURIDAD Y RLS EN public.verification_attempts
-- ----------------------------------------------------------------------------
ALTER TABLE public.verification_attempts ENABLE ROW LEVEL SECURITY;

-- Revocación total de privilegios heredados y saneamiento de PUBLIC
REVOKE ALL ON public.verification_attempts FROM PUBLIC, anon, authenticated;

-- authenticated solo puede consultar e insertar las 5 columnas autorizadas para el registro
GRANT SELECT ON public.verification_attempts TO authenticated;
GRANT INSERT (
  user_id,
  status,
  document_front_path,
  document_back_path,
  selfie_path
) ON public.verification_attempts TO authenticated;

-- 2.1. Índice parcial único anti-spam: impide múltiples solicitudes pendientes simultáneas por usuario.
-- Se libera automáticamente cuando la solicitud se resuelve a 'aprobado' o 'rechazado', permitiendo reintentos.
CREATE UNIQUE INDEX IF NOT EXISTS uq_verification_attempts_pending_user
ON public.verification_attempts (user_id)
WHERE status IN ('pendiente', 'en_revision_ia');

-- 2.2. Política SELECT: usuario ve sus propias solicitudes; moderador ve la cola completa
DROP POLICY IF EXISTS "verification_attempts_select" ON public.verification_attempts;
CREATE POLICY "verification_attempts_select"
ON public.verification_attempts
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
  OR public.is_moderator()
);

-- 2.3. Política INSERT: usuario solo crea solicitudes en estado pendiente si su perfil NO está ya aprobado o suspendido
DROP POLICY IF EXISTS "verification_attempts_insert_own" ON public.verification_attempts;
CREATE POLICY "verification_attempts_insert_own"
ON public.verification_attempts
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND status = 'pendiente'::public.user_verification_status
  AND reviewed_by IS NULL
  AND reviewed_at IS NULL
  AND moderator_result IS NULL
  AND rejection_reason IS NULL
  AND ocr_result IS NULL
  AND face_match_result IS NULL
  AND ai_result IS NULL
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.verification_status IN ('pendiente'::public.user_verification_status, 'rechazado'::public.user_verification_status)
  )
);

-- 2.4. Trigger de protección: coordina bloqueos sobre profiles e impide alteraciones directas
CREATE OR REPLACE FUNCTION public.protect_verification_attempts_security_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_profile_status public.user_verification_status;
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.status IS DISTINCT FROM 'pendiente'::public.user_verification_status THEN
        RAISE EXCEPTION 'No está permitido registrar solicitudes en un estado diferente de pendiente' USING ERRCODE = '42501';
      END IF;
      IF NEW.reviewed_by IS NOT NULL
         OR NEW.reviewed_at IS NOT NULL
         OR NEW.moderator_result IS NOT NULL
         OR NEW.rejection_reason IS NOT NULL THEN
        RAISE EXCEPTION 'No está permitido auto-asignar campos de decisión de moderación' USING ERRCODE = '42501';
      END IF;
      IF NEW.ocr_result IS NOT NULL
         OR NEW.face_match_result IS NOT NULL
         OR NEW.ai_result IS NOT NULL THEN
        RAISE EXCEPTION 'No está permitido registrar resultados automatizados o de IA en la creación' USING ERRCODE = '42501';
      END IF;
      IF NEW.user_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'No está permitido crear solicitudes para un usuario distinto' USING ERRCODE = '42501';
      END IF;

      -- Coordinación de concurrencia: bloquea el perfil padre para serializar contra decisiones concurrentes
      SELECT verification_status INTO v_profile_status
      FROM public.profiles
      WHERE id = NEW.user_id
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'El perfil de usuario asociado no existe' USING ERRCODE = 'P0002';
      END IF;

      IF v_profile_status NOT IN ('pendiente'::public.user_verification_status, 'rechazado'::public.user_verification_status) THEN
        RAISE EXCEPTION 'No está permitido registrar una nueva solicitud si el perfil ya está aprobado o suspendido' USING ERRCODE = '42501';
      END IF;

    ELSIF TG_OP = 'UPDATE' THEN
      RAISE EXCEPTION 'No está permitida la modificación directa de solicitudes de verificación; utilice las RPC autorizadas' USING ERRCODE = '42501';
    ELSIF TG_OP = 'DELETE' THEN
      RAISE EXCEPTION 'No está permitida la eliminación de solicitudes de verificación' USING ERRCODE = '42501';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.protect_verification_attempts_security_fields() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.protect_verification_attempts_security_fields() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS trg_protect_verification_attempts_security_fields ON public.verification_attempts;
CREATE TRIGGER trg_protect_verification_attempts_security_fields
BEFORE INSERT OR UPDATE OR DELETE ON public.verification_attempts
FOR EACH ROW
EXECUTE FUNCTION public.protect_verification_attempts_security_fields();


-- ----------------------------------------------------------------------------
-- 3. POLÍTICA RLS COMPLEMENTARIA EN public.profiles (MENOR PRIVILEGIO - PoLP)
-- ----------------------------------------------------------------------------
-- Compatible con la consulta anidada PostgREST de Flutter sin exponer perfiles ajenos a moderación
DROP POLICY IF EXISTS "profiles_select_moderator" ON public.profiles;
CREATE POLICY "profiles_select_moderator"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  public.is_moderator()
  AND EXISTS (
    SELECT 1 FROM public.verification_attempts va
    WHERE va.user_id = profiles.id
  )
);


-- ----------------------------------------------------------------------------
-- 4. RPC DE LECTURA DE COLA DE MODERACIÓN (MENOR PRIVILEGIO ESTRICTO)
-- ----------------------------------------------------------------------------
-- Proporciona una ruta segura y encapsulada para listar la cola con proyección controlada.
CREATE OR REPLACE FUNCTION public.get_moderation_queue(
  p_status_filter text DEFAULT NULL,
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_result jsonb;
  v_limit int;
  v_offset int;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_moderator() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol de moderador' USING ERRCODE = '42501';
  END IF;

  v_limit := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
  v_offset := GREATEST(COALESCE(p_offset, 0), 0);

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', va.id,
      'user_id', va.user_id,
      'status', va.status,
      'document_front_path', va.document_front_path,
      'document_back_path', va.document_back_path,
      'selfie_path', va.selfie_path,
      'rejection_reason', va.rejection_reason,
      'reviewed_by', va.reviewed_by,
      'reviewed_at', va.reviewed_at,
      'created_at', va.created_at,
      'updated_at', va.updated_at,
      'profiles', jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'phone', p.phone,
        'email', p.email,
        'role', p.role,
        'verification_status', p.verification_status
      )
    )
  )
  INTO v_result
  FROM (
    SELECT *
    FROM public.verification_attempts
    WHERE (
      CASE
        WHEN p_status_filter IS NOT NULL AND trim(p_status_filter) <> ''
          THEN status = p_status_filter::public.user_verification_status
        ELSE status IN ('pendiente'::public.user_verification_status, 'en_revision_ia'::public.user_verification_status)
      END
    )
    ORDER BY created_at DESC, id DESC
    LIMIT v_limit OFFSET v_offset
  ) va
  JOIN public.profiles p ON p.id = va.user_id;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

ALTER FUNCTION public.get_moderation_queue(text, int, int) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_moderation_queue(text, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_moderation_queue(text, int, int) TO authenticated;

COMMENT ON FUNCTION public.get_moderation_queue(text, int, int) IS
  'Consulta estructurada y de menor privilegio para la cola de moderación.';


-- ----------------------------------------------------------------------------
-- 5. RPC: public.approve_verification_attempt(p_attempt_id uuid)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_verification_attempt(
  p_attempt_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_current_status public.user_verification_status;
  v_created_at timestamptz;
  v_profile_status public.user_verification_status;
  v_rows_updated int;
  v_now timestamptz := clock_timestamp();
BEGIN
  -- 1. Validar autenticación
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
  END IF;

  -- 2. Validar autorización de moderador
  IF NOT public.is_moderator() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol de moderador' USING ERRCODE = '42501';
  END IF;

  -- 3. Validar parámetro
  IF p_attempt_id IS NULL THEN
    RAISE EXCEPTION 'El identificador de la solicitud (p_attempt_id) es obligatorio' USING ERRCODE = '22023';
  END IF;

  -- 4. Obtener user_id preliminar para orden de bloqueo canónico
  SELECT user_id INTO v_user_id
  FROM public.verification_attempts
  WHERE id = p_attempt_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La solicitud de verificación % no existe', p_attempt_id USING ERRCODE = 'P0002';
  END IF;

  -- 5. BLOQUEO CANÓNICO PASO 1: Bloquear la fila del perfil padre (Parent Resource)
  -- Serializa todas las decisiones y mutaciones concurrentes sobre el usuario
  SELECT verification_status
  INTO v_profile_status
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'El perfil de usuario % asociado a la solicitud no existe', v_user_id USING ERRCODE = 'P0002';
  END IF;

  -- 6. Proteger perfiles suspendidos administrativamente
  IF v_profile_status = 'suspendido'::public.user_verification_status THEN
    RAISE EXCEPTION 'El perfil se encuentra suspendido y no puede ser alterado mediante moderación ordinaria'
      USING ERRCODE = '22000';
  END IF;

  -- 7. BLOQUEO CANÓNICO PASO 2: Bloquear la fila de la solicitud en verification_attempts
  SELECT status, created_at
  INTO v_current_status, v_created_at
  FROM public.verification_attempts
  WHERE id = p_attempt_id
  FOR UPDATE;

  -- 8. Anti-obsolescencia estricta bajo bloqueo: tupla compuesta (created_at, id)
  IF EXISTS (
    SELECT 1 FROM public.verification_attempts
    WHERE user_id = v_user_id
      AND (created_at, id) > (v_created_at, p_attempt_id)
  ) THEN
    RAISE EXCEPTION 'No se puede resolver una solicitud obsoleta; existe un intento más reciente para el usuario'
      USING ERRCODE = '22000';
  END IF;

  -- 9. Re-validación del estado actual de la solicitud tras adquirir los bloqueos
  IF v_current_status = 'aprobado'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación ya fue aprobada previamente' USING ERRCODE = '22000';
  ELSIF v_current_status = 'rechazado'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación ya fue rechazada y no puede ser aprobada directamente' USING ERRCODE = '22000';
  ELSIF v_current_status = 'suspendido'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación está suspendida' USING ERRCODE = '22000';
  ELSIF v_current_status NOT IN ('pendiente'::public.user_verification_status, 'en_revision_ia'::public.user_verification_status) THEN
    RAISE EXCEPTION 'Estado no válido para aprobación: %', v_current_status USING ERRCODE = '22000';
  END IF;

  -- 10. Actualizar verification_attempts
  UPDATE public.verification_attempts
  SET
    status = 'aprobado'::public.user_verification_status,
    reviewed_by = auth.uid(),
    reviewed_at = v_now,
    rejection_reason = NULL,
    moderator_result = jsonb_build_object(
      'decision', 'aprobado',
      'moderator_id', auth.uid(),
      'timestamp', v_now
    ),
    updated_at = v_now
  WHERE id = p_attempt_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'Fallo de concurrencia al actualizar verification_attempts (filas: %)', v_rows_updated USING ERRCODE = '40001';
  END IF;

  -- 11. Actualizar profiles
  UPDATE public.profiles
  SET
    verification_status = 'aprobado'::public.user_verification_status,
    updated_at = v_now
  WHERE id = v_user_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'Fallo de concurrencia al actualizar profiles (filas: %)', v_rows_updated USING ERRCODE = '40001';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'user_id', v_user_id,
    'status', 'aprobado',
    'moderator_id', auth.uid(),
    'reviewed_at', v_now
  );
END;
$$;

ALTER FUNCTION public.approve_verification_attempt(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.approve_verification_attempt(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_verification_attempt(uuid) TO authenticated;

COMMENT ON FUNCTION public.approve_verification_attempt(uuid) IS
  'Aprueba atómicamente una solicitud de verificación y actualiza el estado del perfil a aprobado.';


-- ----------------------------------------------------------------------------
-- 6. RPC: public.reject_verification_attempt(p_attempt_id uuid, p_reason text)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_verification_attempt(
  p_attempt_id uuid,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_current_status public.user_verification_status;
  v_created_at timestamptz;
  v_profile_status public.user_verification_status;
  v_clean_reason text;
  v_rows_updated int;
  v_now timestamptz := clock_timestamp();
BEGIN
  -- 1. Validar autenticación
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
  END IF;

  -- 2. Validar autorización de moderador
  IF NOT public.is_moderator() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol de moderador' USING ERRCODE = '42501';
  END IF;

  -- 3. Validar parámetros
  IF p_attempt_id IS NULL THEN
    RAISE EXCEPTION 'El identificador de la solicitud (p_attempt_id) es obligatorio' USING ERRCODE = '22023';
  END IF;

  v_clean_reason := trim(p_reason);
  IF v_clean_reason IS NULL OR v_clean_reason = '' THEN
    RAISE EXCEPTION 'El motivo de rechazo es obligatorio y no puede estar vacío' USING ERRCODE = '22023';
  END IF;

  -- 4. Obtener user_id preliminar para orden de bloqueo canónico
  SELECT user_id INTO v_user_id
  FROM public.verification_attempts
  WHERE id = p_attempt_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La solicitud de verificación % no existe', p_attempt_id USING ERRCODE = 'P0002';
  END IF;

  -- 5. BLOQUEO CANÓNICO PASO 1: Bloquear la fila del perfil padre (Parent Resource)
  SELECT verification_status
  INTO v_profile_status
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'El perfil de usuario % asociado a la solicitud no existe', v_user_id USING ERRCODE = 'P0002';
  END IF;

  -- 6. Proteger perfiles suspendidos administrativamente
  IF v_profile_status = 'suspendido'::public.user_verification_status THEN
    RAISE EXCEPTION 'El perfil se encuentra suspendido y no puede ser alterado mediante moderación ordinaria'
      USING ERRCODE = '22000';
  END IF;

  -- 7. BLOQUEO CANÓNICO PASO 2: Bloquear la fila de la solicitud en verification_attempts
  SELECT status, created_at
  INTO v_current_status, v_created_at
  FROM public.verification_attempts
  WHERE id = p_attempt_id
  FOR UPDATE;

  -- 8. Anti-obsolescencia estricta bajo bloqueo: tupla compuesta (created_at, id)
  IF EXISTS (
    SELECT 1 FROM public.verification_attempts
    WHERE user_id = v_user_id
      AND (created_at, id) > (v_created_at, p_attempt_id)
  ) THEN
    RAISE EXCEPTION 'No se puede resolver una solicitud obsoleta; existe un intento más reciente para el usuario'
      USING ERRCODE = '22000';
  END IF;

  -- 9. Re-validación del estado actual de la solicitud tras adquirir los bloqueos
  IF v_current_status = 'rechazado'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación ya fue rechazada previamente' USING ERRCODE = '22000';
  ELSIF v_current_status = 'aprobado'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación ya fue aprobada y no puede ser rechazada directamente' USING ERRCODE = '22000';
  ELSIF v_current_status = 'suspendido'::public.user_verification_status THEN
    RAISE EXCEPTION 'La solicitud de verificación está suspendida' USING ERRCODE = '22000';
  ELSIF v_current_status NOT IN ('pendiente'::public.user_verification_status, 'en_revision_ia'::public.user_verification_status) THEN
    RAISE EXCEPTION 'Estado no válido para rechazo: %', v_current_status USING ERRCODE = '22000';
  END IF;

  -- 10. Actualizar verification_attempts
  UPDATE public.verification_attempts
  SET
    status = 'rechazado'::public.user_verification_status,
    rejection_reason = v_clean_reason,
    reviewed_by = auth.uid(),
    reviewed_at = v_now,
    moderator_result = jsonb_build_object(
      'decision', 'rechazado',
      'reason', v_clean_reason,
      'moderator_id', auth.uid(),
      'timestamp', v_now
    ),
    updated_at = v_now
  WHERE id = p_attempt_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'Fallo de concurrencia al actualizar verification_attempts (filas: %)', v_rows_updated USING ERRCODE = '40001';
  END IF;

  -- 11. Actualizar profiles
  UPDATE public.profiles
  SET
    verification_status = 'rechazado'::public.user_verification_status,
    updated_at = v_now
  WHERE id = v_user_id;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated <> 1 THEN
    RAISE EXCEPTION 'Fallo de concurrencia al actualizar profiles (filas: %)', v_rows_updated USING ERRCODE = '40001';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'attempt_id', p_attempt_id,
    'user_id', v_user_id,
    'status', 'rechazado',
    'reason', v_clean_reason,
    'moderator_id', auth.uid(),
    'reviewed_at', v_now
  );
END;
$$;

ALTER FUNCTION public.reject_verification_attempt(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reject_verification_attempt(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_verification_attempt(uuid, text) TO authenticated;

COMMENT ON FUNCTION public.reject_verification_attempt(uuid, text) IS
  'Rechaza atómicamente una solicitud de verificación con motivo obligatorio y actualiza el estado del perfil a rechazado.';

COMMIT;
