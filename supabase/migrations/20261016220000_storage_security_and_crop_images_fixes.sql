-- ============================================================================
-- MIGRACIÓN SQL VERSIONADA: 20261016220000_storage_security_and_crop_images_fixes.sql
-- PROYECTO: agricultural_marketplace (Flutter + Supabase/PostgreSQL)
-- ALCANCE: Fase 2 — Subetapa 2.1: Seguridad y RLS en Supabase Storage y crop_images
--
-- OBJETIVOS:
-- 1. Registrar y configurar buckets 'product_images' y 'profiles' como públicos,
--    y asegurar la existencia de 'user_documents' privado sin relajar permisos.
-- 2. Establecer políticas de RLS en storage.objects para product_images:
--    - Lectura pública (SELECT) para visitantes y compradores.
--    - Escritura (INSERT, UPDATE, DELETE) estrictamente restringida al agricultor
--      propietario del cultivo (crops.farmer_id = auth.uid()) mediante el crop_id
--      de la ruta existente (crop_id/archivo.ext), con acceso autorizado a moderadores.
-- 3. Establecer políticas de RLS en storage.objects para profiles:
--    - Lectura pública (SELECT) para visualización de avatares en mercado y ofertas.
--    - Escritura (INSERT, UPDATE, DELETE) estrictamente restringida a la carpeta
--      propia del usuario autenticado ((storage.foldername(name))[1] = auth.uid()::text).
-- 4. Reemplazar cualquier política permisiva previa evitando accesos duplicados.
-- 5. Subsanar permisos SQL faltantes en public.crop_images (GRANT UPDATE acotado a
--    columnas de presentación y política RLS FOR UPDATE para el propietario/moderador).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CONFIGURACIÓN E IDEMPOTENCIA DE BUCKETS DE ALMACENAMIENTO
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('product_images', 'product_images', true),
  ('profiles', 'profiles', true),
  ('user_documents', 'user_documents', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- storage.objects ya tiene RLS habilitado nativamente por la extensión storage.


-- ----------------------------------------------------------------------------
-- 2. SANEAMIENTO DE POLÍTICAS PREVIAS EN storage.objects
-- ----------------------------------------------------------------------------
-- Evita políticas duplicadas o permisivas que otorguen acceso no restringido.
DROP POLICY IF EXISTS "product_images_select_public" ON storage.objects;
DROP POLICY IF EXISTS "product_images_insert_crop_owner_or_moderator" ON storage.objects;
DROP POLICY IF EXISTS "product_images_update_crop_owner_or_moderator" ON storage.objects;
DROP POLICY IF EXISTS "product_images_delete_crop_owner_or_moderator" ON storage.objects;

DROP POLICY IF EXISTS "profiles_select_public" ON storage.objects;
DROP POLICY IF EXISTS "profiles_insert_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "profiles_update_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "profiles_delete_own_folder" ON storage.objects;

-- Políticas genéricas de plantillas Supabase si existieran
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read product_images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated insert product_images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read profiles" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated insert profiles" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update profiles" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated delete profiles" ON storage.objects;


-- ----------------------------------------------------------------------------
-- 3. POLÍTICAS RLS PARA 'product_images' (storage.objects)
-- ----------------------------------------------------------------------------

-- 3.1. Lectura pública de imágenes de producto (catálogo abierto)
CREATE POLICY "product_images_select_public"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product_images');

-- 3.2. Inserción: restringida al agricultor dueño del cultivo o a un moderador
CREATE POLICY "product_images_insert_crop_owner_or_moderator"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product_images'
  AND (
    public.is_moderator()
    OR EXISTS (
      SELECT 1
      FROM public.crops c
      WHERE c.id = (
        CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid
          ELSE NULL
        END
      )
      AND c.farmer_id = (SELECT auth.uid())
    )
  )
);

-- 3.3. Actualización (sobrescritura / replace): dueño del cultivo o moderador
CREATE POLICY "product_images_update_crop_owner_or_moderator"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'product_images'
  AND (
    public.is_moderator()
    OR EXISTS (
      SELECT 1
      FROM public.crops c
      WHERE c.id = (
        CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid
          ELSE NULL
        END
      )
      AND c.farmer_id = (SELECT auth.uid())
    )
  )
)
WITH CHECK (
  bucket_id = 'product_images'
  AND (
    public.is_moderator()
    OR EXISTS (
      SELECT 1
      FROM public.crops c
      WHERE c.id = (
        CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid
          ELSE NULL
        END
      )
      AND c.farmer_id = (SELECT auth.uid())
    )
  )
);

-- 3.4. Eliminación: dueño del cultivo o moderador
CREATE POLICY "product_images_delete_crop_owner_or_moderator"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'product_images'
  AND (
    public.is_moderator()
    OR EXISTS (
      SELECT 1
      FROM public.crops c
      WHERE c.id = (
        CASE
          WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN ((storage.foldername(name))[1])::uuid
          ELSE NULL
        END
      )
      AND c.farmer_id = (SELECT auth.uid())
    )
  )
);


-- ----------------------------------------------------------------------------
-- 4. POLÍTICAS RLS PARA 'profiles' (storage.objects)
-- ----------------------------------------------------------------------------

-- 4.1. Lectura pública de avatares (visible en marketplace y negociaciones)
CREATE POLICY "profiles_select_public"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profiles');

-- 4.2. Inserción: restringida a la carpeta identificada con el auth.uid() del usuario
CREATE POLICY "profiles_insert_own_folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

-- 4.3. Actualización: restringida a la carpeta del propio usuario
CREATE POLICY "profiles_update_own_folder"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
)
WITH CHECK (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);

-- 4.4. Eliminación: restringida a la carpeta del propio usuario
CREATE POLICY "profiles_delete_own_folder"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
);


-- ----------------------------------------------------------------------------
-- 5. CORRECCIONES DE SEGURIDAD Y PERMISOS SQL EN public.crop_images
-- ----------------------------------------------------------------------------

-- 5.1. Concesión de privilegios mínimos de UPDATE sobre columnas permitidas
GRANT UPDATE (
  image_path,
  is_primary
) ON public.crop_images TO authenticated;

-- 5.2. Actualización de política SELECT para incluir revisión de moderadores
DROP POLICY IF EXISTS "crop_images_select_visible_crops" ON public.crop_images;
CREATE POLICY "crop_images_select_visible_crops"
ON public.crop_images
FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND (
        c.status = 'activa'::public.crop_status
        OR c.farmer_id = (SELECT auth.uid())
        OR public.is_moderator()
      )
  )
);

-- 5.3. Política UPDATE para permitir alternar is_primary / actualizar image_path
DROP POLICY IF EXISTS "crop_images_update_crop_owner" ON public.crop_images;
CREATE POLICY "crop_images_update_crop_owner"
ON public.crop_images
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND (
        c.farmer_id = (SELECT auth.uid())
        OR public.is_moderator()
      )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND (
        c.farmer_id = (SELECT auth.uid())
        OR public.is_moderator()
      )
  )
);

-- 5.4. Política DELETE actualizada para permitir baja por moderación
DROP POLICY IF EXISTS "crop_images_delete_crop_owner" ON public.crop_images;
CREATE POLICY "crop_images_delete_crop_owner"
ON public.crop_images
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.crops c
    WHERE c.id = crop_images.crop_id
      AND (
        c.farmer_id = (SELECT auth.uid())
        OR public.is_moderator()
      )
  )
);

COMMIT;
