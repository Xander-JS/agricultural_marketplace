-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261023120000_verification_resubmission_status_sync.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase/PostgreSQL)
-- ALCANCE: Reenvío de documentos tras un rechazo
--
-- PROBLEMA:
-- Un usuario rechazado puede insertar una nueva solicitud (la política
-- verification_attempts_insert_own admite perfiles 'rechazado'), pero su
-- perfil sigue en 'rechazado' para siempre: el cliente no puede cambiar
-- profiles.verification_status (no tiene GRANT UPDATE sobre la columna y el
-- trigger trg_protect_profiles_security_fields lo bloquea con 42501).
--
-- SOLUCIÓN:
-- Trigger AFTER INSERT en verification_attempts que, cuando el perfil está en
-- 'rechazado', lo mueve a 'en_revision_ia'. La función es SECURITY DEFINER
-- (propietario postgres), por lo que el trigger de protección de profiles la
-- permite (current_user deja de ser 'authenticated').
--
-- GARANTÍAS:
-- - Solo transiciona 'rechazado' -> 'en_revision_ia'. Nunca aprueba, nunca
--   toca perfiles aprobados o suspendidos ni perfiles 'pendiente'.
-- - La solicitud se sigue insertando como 'pendiente' (la política RLS de
--   INSERT no cambia) y la decisión sigue siendo manual del moderador.
-- - Idempotente: puede ejecutarse varias veces.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.sync_profile_status_on_resubmission()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
  IF NEW.status IN (
    'pendiente'::public.user_verification_status,
    'en_revision_ia'::public.user_verification_status
  ) THEN
    UPDATE public.profiles
    SET
      verification_status = 'en_revision_ia'::public.user_verification_status,
      updated_at = clock_timestamp()
    WHERE id = NEW.user_id
      AND verification_status = 'rechazado'::public.user_verification_status;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.sync_profile_status_on_resubmission() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.sync_profile_status_on_resubmission() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_sync_profile_status_on_resubmission ON public.verification_attempts;
CREATE TRIGGER trg_sync_profile_status_on_resubmission
AFTER INSERT ON public.verification_attempts
FOR EACH ROW
EXECUTE FUNCTION public.sync_profile_status_on_resubmission();

COMMENT ON FUNCTION public.sync_profile_status_on_resubmission() IS
  'Tras un rechazo, una nueva solicitud devuelve el perfil a en_revision_ia para que el usuario vuelva a la espera de moderación.';

COMMIT;
