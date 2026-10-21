BEGIN;

-- ============================================================================
-- Justificación técnica de la migración:
-- La tabla 'crops' ya cuenta con columnas 'latitude' y 'longitude' (numeric(10,7)),
-- así como 'department' y 'municipality'. Sin embargo, la tabla 'profiles'
-- carece de campos geográficos para persistir la ubicación simulada asignada a cada
-- usuario (compradores y agricultores) durante el registro en el piloto de Nariño.
-- 
-- Para garantizar que la ubicación asignada permanezca estable (no cambie al
-- reiniciar sesión o consultar el perfil) y permitir el cálculo de distancias
-- en la Fase 2 sin recurrir a geolocalización GPS real ni permisos de dispositivo,
-- se agregan las columnas mínimas necesarias de forma no destructiva con ADD COLUMN IF NOT EXISTS.
-- ============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS department varchar(100) DEFAULT 'Nariño',
  ADD COLUMN IF NOT EXISTS municipality varchar(100),
  ADD COLUMN IF NOT EXISTS latitude numeric(10,7),
  ADD COLUMN IF NOT EXISTS longitude numeric(10,7);

COMMENT ON COLUMN public.profiles.department IS
  'Departamento administrativo asignado o seleccionado para el usuario en el piloto.';

COMMENT ON COLUMN public.profiles.municipality IS
  'Municipio administrativo asignado o seleccionado para el usuario en el piloto.';

COMMENT ON COLUMN public.profiles.latitude IS
  'Latitud geográfica simulada para el piloto de Nariño. No representa ubicación GPS real.';

COMMENT ON COLUMN public.profiles.longitude IS
  'Longitud geográfica simulada para el piloto de Nariño. No representa ubicación GPS real.';

COMMIT;
