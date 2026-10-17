-- ============================================================================
-- SCRIPT DE ROLLBACK VERSIONADO: 20261016190000_commercial_cycle_closing_rpcs_rollback.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Reversión controlada de las RPCs del ciclo de cierre comercial
-- ============================================================================

BEGIN;

-- 1. Eliminar RPCs públicas del ciclo de cierre
DROP FUNCTION IF EXISTS public.cancel_negotiation(uuid, text);
DROP FUNCTION IF EXISTS public.reject_negotiation(uuid, text);
DROP FUNCTION IF EXISTS public.reject_or_cancel_negotiation(uuid, public.negotiation_status, text);
DROP FUNCTION IF EXISTS public.complete_negotiation(uuid);
DROP FUNCTION IF EXISTS public.accept_negotiation(uuid);
DROP FUNCTION IF EXISTS public.counter_offer(uuid, numeric, numeric, public.delivery_method, text);

COMMIT;
