-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261020193000_bidirectional_negotiation_consents_and_contact_privacy.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Implementación de la Fase 4.2:
--           1. Transformación de negotiation_consents a modelo bidireccional (por participante).
--           2. Preservación estricta de registros históricos.
--           3. RPCs transaccionales seguras: set_negotiation_consent, get_negotiation_counterpart_contact y get_my_profile.
--           4. Cierre de fuga de datos privados en profiles (phone, email, coordenadas) y crops (coordenadas frente a anon).
--           5. Políticas RLS con principio de mínimo privilegio.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. ADAPTACIÓN DE negotiation_consents A CONSENTIMIENTO BIDIRECCIONAL
-- ============================================================================

-- 1.1. Renombrar columna farmer_id a user_id si aún existe farmer_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'negotiation_consents' 
      AND column_name = 'farmer_id'
  ) THEN
    ALTER TABLE public.negotiation_consents RENAME COLUMN farmer_id TO user_id;
  END IF;
END $$;

-- 1.2. Añadir updated_at si no existe
ALTER TABLE public.negotiation_consents
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- 1.3. Eliminar restricción UNIQUE obsoleta sobre negotiation_id únicamente
ALTER TABLE public.negotiation_consents
  DROP CONSTRAINT IF EXISTS negotiation_consents_negotiation_id_key;

-- 1.4. Eliminar restricciones de clave foránea previas y recrear con ON DELETE CASCADE
ALTER TABLE public.negotiation_consents
  DROP CONSTRAINT IF EXISTS negotiation_consents_farmer_id_fkey,
  DROP CONSTRAINT IF EXISTS negotiation_consents_user_id_fkey;

ALTER TABLE public.negotiation_consents
  ADD CONSTRAINT negotiation_consents_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.negotiation_consents
  DROP CONSTRAINT IF EXISTS negotiation_consents_negotiation_id_fkey;

ALTER TABLE public.negotiation_consents
  ADD CONSTRAINT negotiation_consents_negotiation_id_fkey 
  FOREIGN KEY (negotiation_id) REFERENCES public.negotiations(id) ON DELETE CASCADE;

-- 1.5. Agregar restricción UNIQUE compuesta por negociación y participante
ALTER TABLE public.negotiation_consents
  DROP CONSTRAINT IF EXISTS uq_negotiation_consents_negotiation_user;

ALTER TABLE public.negotiation_consents
  ADD CONSTRAINT uq_negotiation_consents_negotiation_user 
  UNIQUE (negotiation_id, user_id);

-- 1.6. Habilitar RLS en negotiation_consents
ALTER TABLE public.negotiation_consents ENABLE ROW LEVEL SECURITY;

-- 1.7. Políticas RLS en negotiation_consents
DROP POLICY IF EXISTS "negotiation_consents_select_participants" ON public.negotiation_consents;
CREATE POLICY "negotiation_consents_select_participants"
ON public.negotiation_consents
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = negotiation_consents.negotiation_id
      AND (n.buyer_id = auth.uid() OR c.farmer_id = auth.uid())
  )
);

-- Bloquear mutación directa desde REST (las mutaciones se canalizan exclusivamente por set_negotiation_consent)
REVOKE INSERT, UPDATE, DELETE ON public.negotiation_consents FROM authenticated, anon;
GRANT SELECT ON public.negotiation_consents TO authenticated;


-- ============================================================================
-- 2. PROTECCIÓN DE PRIVACIDAD EN profiles Y crops
-- ============================================================================

-- 2.1. Restricción en public.crops: anon no debe consultar coordenadas sensibles de fincas
-- En PostgreSQL se revoca el SELECT general de anon y se otorga únicamente sobre columnas de catálogo públicas.
REVOKE SELECT ON public.crops FROM anon;
GRANT SELECT (
  id,
  farmer_id,
  title,
  description,
  crop_type,
  price_per_kg,
  stock_total,
  stock_committed,
  stock_sold,
  min_order_kg,
  estimated_yield_kg,
  department,
  municipality,
  is_early_sale,
  estimated_harvest_date,
  status,
  created_at,
  updated_at
) ON public.crops TO anon;

-- 2.2. Restricción en public.profiles: cerrar acceso directo a teléfono, correo y coordenadas privadas
-- authenticated solo puede consultar mediante REST los campos públicos requeridos para el catálogo y tratos.
REVOKE SELECT ON public.profiles FROM authenticated;
GRANT SELECT (
  id,
  full_name,
  role,
  verification_status,
  profile_path,
  department,
  municipality,
  created_at,
  updated_at
) ON public.profiles TO authenticated;

-- Permitir actualización legítima de los campos de perfil propios
GRANT UPDATE (
  phone,
  full_name,
  email,
  profile_path,
  department,
  municipality,
  latitude,
  longitude,
  updated_at
) ON public.profiles TO authenticated;

-- 2.3. Actualizar política RLS en profiles para mantener lectura acotada a participantes y catálogo
DROP POLICY IF EXISTS "profiles_select_commercial_participants" ON public.profiles;
CREATE POLICY "profiles_select_commercial_participants"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  -- Perfil propio
  auth.uid() = id
  -- O agricultor de un cultivo activo en el catálogo
  OR EXISTS (
    SELECT 1 FROM public.crops c
    WHERE c.farmer_id = profiles.id
      AND c.status = 'activa'::public.crop_status
  )
  -- O contraparte comercial de una negociación en curso
  OR EXISTS (
    SELECT 1 FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE (n.buyer_id = profiles.id AND c.farmer_id = auth.uid())
       OR (c.farmer_id = profiles.id AND n.buyer_id = auth.uid())
  )
);


-- ============================================================================
-- 3. RPC: get_my_profile (Lectura segura del perfil propio completo)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_res jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
  END IF;

  SELECT to_jsonb(p) INTO v_res 
  FROM public.profiles p 
  WHERE p.id = v_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'El perfil del usuario no existe' USING ERRCODE = 'P0002';
  END IF;

  RETURN v_res;
END;
$$;

ALTER FUNCTION public.get_my_profile() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;


-- ============================================================================
-- 4. RPC: set_negotiation_consent (Gestión de permisos propios por trato)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_negotiation_consent(
    p_negotiation_id uuid,
    p_share_phone boolean,
    p_share_location boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id uuid;
    v_neg record;
    v_now timestamptz := clock_timestamp();
    v_phone_consent boolean := COALESCE(p_share_phone, false);
    v_loc_consent boolean := COALESCE(p_share_location, false);
BEGIN
    -- 1. Validar autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Validar existencia de negociación y pertenencia como participante
    SELECT n.id, n.buyer_id, n.status, c.farmer_id
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    IF v_user_id IS DISTINCT FROM v_neg.buyer_id AND v_user_id IS DISTINCT FROM v_neg.farmer_id THEN
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 3. Upsert atómico del consentimiento propio exclusivamente
    INSERT INTO public.negotiation_consents (
        negotiation_id,
        user_id,
        share_phone,
        share_location,
        updated_at
    ) VALUES (
        p_negotiation_id,
        v_user_id,
        v_phone_consent,
        v_loc_consent,
        v_now
    )
    ON CONFLICT (negotiation_id, user_id)
    DO UPDATE SET
        share_phone = EXCLUDED.share_phone,
        share_location = EXCLUDED.share_location,
        updated_at = EXCLUDED.updated_at;

    RETURN jsonb_build_object(
        'success', true,
        'negotiation_id', p_negotiation_id,
        'user_id', v_user_id,
        'share_phone', v_phone_consent,
        'share_location', v_loc_consent,
        'updated_at', v_now
    );
END;
$$;

ALTER FUNCTION public.set_negotiation_consent(uuid, boolean, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.set_negotiation_consent(uuid, boolean, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_negotiation_consent(uuid, boolean, boolean) TO authenticated;


-- ============================================================================
-- 5. RPC: get_negotiation_counterpart_contact (Consulta segura de contacto)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_negotiation_counterpart_contact(
    p_negotiation_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id uuid;
    v_neg record;
    v_counterpart_id uuid;
    v_counterpart_role text;
    v_counterpart_profile record;
    v_my_consent record;
    v_counterpart_consent record;
    v_is_deal_formalized boolean;
    v_ret_phone text := NULL;
    v_ret_department text := NULL;
    v_ret_municipality text := NULL;
    v_ret_lat numeric := NULL;
    v_ret_lon numeric := NULL;
BEGIN
    -- 1. Validar autenticación
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado' USING ERRCODE = '28000';
    END IF;

    -- 2. Validar negociación y participantes
    SELECT 
        n.id, 
        n.buyer_id, 
        n.status, 
        c.farmer_id,
        c.department AS crop_department,
        c.municipality AS crop_municipality,
        c.latitude AS crop_latitude,
        c.longitude AS crop_longitude
    INTO v_neg
    FROM public.negotiations n
    JOIN public.crops c ON c.id = n.crop_id
    WHERE n.id = p_negotiation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La negociación especificada no existe' USING ERRCODE = 'P0002';
    END IF;

    -- 3. Identificar contraparte
    IF v_user_id = v_neg.buyer_id THEN
        v_counterpart_id := v_neg.farmer_id;
        v_counterpart_role := 'agricultor';
    ELSIF v_user_id = v_neg.farmer_id THEN
        v_counterpart_id := v_neg.buyer_id;
        v_counterpart_role := 'comprador';
    ELSE
        RAISE EXCEPTION 'No eres participante de esta negociación' USING ERRCODE = '42501';
    END IF;

    -- 4. Obtener perfil de la contraparte
    SELECT id, full_name, role, profile_path, phone, department, municipality, latitude, longitude
    INTO v_counterpart_profile
    FROM public.profiles
    WHERE id = v_counterpart_id;

    -- 5. Obtener permisos de consentimiento propios
    SELECT share_phone, share_location, updated_at
    INTO v_my_consent
    FROM public.negotiation_consents
    WHERE negotiation_id = p_negotiation_id AND user_id = v_user_id;

    -- 6. Obtener permisos de consentimiento de la contraparte
    SELECT share_phone, share_location, updated_at
    INTO v_counterpart_consent
    FROM public.negotiation_consents
    WHERE negotiation_id = p_negotiation_id AND user_id = v_counterpart_id;

    -- 7. Los datos privados SOLO se habilitan si el trato está 'acordada' o 'completada'
    v_is_deal_formalized := v_neg.status IN ('acordada'::public.negotiation_status, 'completada'::public.negotiation_status);

    IF v_is_deal_formalized THEN
        -- Teléfono autorizado
        IF COALESCE(v_counterpart_consent.share_phone, false) = true THEN
            v_ret_phone := v_counterpart_profile.phone;
        END IF;

        -- Ubicación autorizada
        IF COALESCE(v_counterpart_consent.share_location, false) = true THEN
            IF v_counterpart_role = 'agricultor' THEN
                v_ret_department := COALESCE(v_neg.crop_department, v_counterpart_profile.department);
                v_ret_municipality := COALESCE(v_neg.crop_municipality, v_counterpart_profile.municipality);
                v_ret_lat := COALESCE(v_neg.crop_latitude, v_counterpart_profile.latitude);
                v_ret_lon := COALESCE(v_neg.crop_longitude, v_counterpart_profile.longitude);
            ELSE
                v_ret_department := v_counterpart_profile.department;
                v_ret_municipality := v_counterpart_profile.municipality;
                v_ret_lat := v_counterpart_profile.latitude;
                v_ret_lon := v_counterpart_profile.longitude;
            END IF;
        END IF;
    END IF;

    -- 8. Retornar estructura completa
    RETURN jsonb_build_object(
        'negotiation_id', p_negotiation_id,
        'status', v_neg.status::text,
        'my_consent', jsonb_build_object(
            'share_phone', COALESCE(v_my_consent.share_phone, false),
            'share_location', COALESCE(v_my_consent.share_location, false),
            'updated_at', v_my_consent.updated_at
        ),
        'counterpart_consent', jsonb_build_object(
            'share_phone', COALESCE(v_counterpart_consent.share_phone, false),
            'share_location', COALESCE(v_counterpart_consent.share_location, false),
            'updated_at', v_counterpart_consent.updated_at
        ),
        'counterpart_profile', jsonb_build_object(
            'id', v_counterpart_id,
            'full_name', v_counterpart_profile.full_name,
            'role', v_counterpart_role,
            'profile_path', v_counterpart_profile.profile_path,
            'phone', v_ret_phone,
            'department', v_ret_department,
            'municipality', v_ret_municipality,
            'latitude', v_ret_lat,
            'longitude', v_ret_lon
        )
    );
END;
$$;

ALTER FUNCTION public.get_negotiation_counterpart_contact(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_negotiation_counterpart_contact(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_negotiation_counterpart_contact(uuid) TO authenticated;

COMMIT;
