-- ============================================================================
-- SCRIPT DE VERIFICACIÓN: 20261016180000_comercial_cycle_rls_verification.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase)
-- OBJETIVO: Consultas de auditoría de solo lectura para comprobar la correcta aplicación.
-- ESTADO: CORREGIDO (FASE 2) — Incluye verificación de perfiles, privilegios de columnas y triggers.
-- ============================================================================

-- 1. Verificar políticas RLS activas en las 5 tablas del ciclo comercial
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual AS using_expression,
    with_check AS check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('negotiations', 'negotiation_offers', 'inventory_movements', 'crops', 'profiles')
ORDER BY tablename, cmd, policyname;

-- 2. Verificar que no queden políticas abiertas (ALL true) en inventory_movements
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'inventory_movements'
  AND (qual = 'true' OR with_check = 'true');
-- Resultado esperado: 0 filas.

-- 3. Verificar que authenticated NO tenga permiso directo de INSERT en negotiations (Cierre A-02)
SELECT table_name, grantee, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name = 'negotiations'
  AND grantee IN ('authenticated', 'anon')
  AND privilege_type = 'INSERT';
-- Resultado esperado: 0 filas (la inserción debe realizarse exclusivamente vía RPC).

-- 4. Verificar privilegios por columna en crops para authenticated (Cierre M-01)
-- Confirma que stock_committed y stock_sold NO figuran con privilegio de UPDATE
SELECT table_name, column_name, grantee, privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'crops'
  AND grantee = 'authenticated'
  AND privilege_type = 'UPDATE'
  AND column_name IN ('stock_committed', 'stock_sold');
-- Resultado esperado: 0 filas.

-- 5. Verificar existencia, search_path y seguridad de la función create_negotiation_with_offer
SELECT 
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS owner_name,
    p.prosecdef AS is_security_definer,
    p.proconfig AS configuration_settings,
    pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'create_negotiation_with_offer';
-- Resultado esperado: is_security_definer = true, configuration_settings incluye search_path=public, pg_temp, owner = postgres.

-- 6. Verificar permisos de ejecución de la función RPC
SELECT 
    routine_schema,
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND routine_name = 'create_negotiation_with_offer'
ORDER BY grantee;
-- Resultado esperado: EXECUTE únicamente concedido a 'authenticated' y al owner (postgres). No a anon ni PUBLIC.

-- 7. Verificar privilegios sobre inventory_movements (solo lectura para authenticated)
SELECT 
    table_schema,
    table_name,
    grantee,
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name = 'inventory_movements'
  AND grantee IN ('authenticated', 'anon');
-- Resultado esperado: Únicamente SELECT para 'authenticated'. Ningún INSERT, UPDATE o DELETE.

-- 8. Verificar existencia del índice único parcial de concurrencia
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'negotiations'
  AND indexname = 'idx_single_active_negotiation_per_buyer';
-- Resultado esperado: 1 fila con predicado WHERE en ('propuesta', 'contraofertada', 'acordada').

-- 9. Verificar triggers de protección de inmutabilidad e inventario
SELECT 
    event_object_table AS tablename,
    trigger_name,
    action_timing,
    event_manipulation AS event,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('negotiations', 'crops')
  AND trigger_name IN ('trg_protect_negotiations_immutable_fields', 'trg_protect_crops_inventory_columns');
-- Resultado esperado: 2 filas (BEFORE UPDATE).
