-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261020183000_user_documents_storage_policies.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase/PostgreSQL)
-- ALCANCE: Fase 3 — Corrección del flujo de registro
--
-- OBJETIVO:
-- Añadir las políticas RLS faltantes para el bucket 'user_documents' en
-- storage.objects. Sin estas políticas, el rol 'authenticated' recibe 403
-- al intentar subir documentos de identidad durante el registro, impidiendo
-- que se cree la solicitud de verificación.
--
-- DISEÑO:
-- - INSERT: el usuario solo puede escribir dentro de su propia carpeta
--   (carpeta raíz = auth.uid()).
-- - SELECT: el propio usuario puede leer sus documentos; moderadores pueden
--   leer cualquier documento del bucket para revisar la solicitud.
-- - DELETE: el propio usuario puede eliminar sus documentos (p.ej., reintento).
-- - UPDATE no se incluye: los documentos se deben resubir como nuevos archivos,
--   no modificar en sitio.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Idempotencia: eliminar políticas anteriores si existieran
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "user_documents_insert_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "user_documents_select_own_or_moderator" ON storage.objects;
DROP POLICY IF EXISTS "user_documents_delete_own_folder" ON storage.objects;

-- ----------------------------------------------------------------------------
-- INSERT: solo en la propia carpeta ({user_id}/archivo.ext)
-- ----------------------------------------------------------------------------
CREATE POLICY "user_documents_insert_own_folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user_documents'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

-- ----------------------------------------------------------------------------
-- SELECT: propio usuario o moderador
-- ----------------------------------------------------------------------------
CREATE POLICY "user_documents_select_own_or_moderator"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'user_documents'
  AND (
    (storage.foldername(name))[1] = (SELECT auth.uid())::text
    OR public.is_moderator()
  )
);

-- ----------------------------------------------------------------------------
-- DELETE: solo en la propia carpeta (permite reintentos limpios)
-- ----------------------------------------------------------------------------
CREATE POLICY "user_documents_delete_own_folder"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'user_documents'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

COMMIT;
