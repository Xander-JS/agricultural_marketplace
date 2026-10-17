BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS profile_path text;

COMMENT ON COLUMN public.profiles.email IS
  'Correo electrónico de contacto del perfil.';

COMMENT ON COLUMN public.profiles.profile_path IS
  'Ruta de la imagen de perfil en Supabase Storage.';

COMMIT;
