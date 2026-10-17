-- Esquema base adaptado para Supabase local a partir de app_movil.sql.
-- No ejecutar este archivo manualmente en un proyecto remoto.

CREATE TYPE "user_role" AS ENUM (
  'agricultor',
  'comprador',
  'moderador'
);

CREATE TYPE "user_verification_status" AS ENUM (
  'pendiente',
  'en_revision_ia',
  'aprobado',
  'rechazado',
  'suspendido'
);

CREATE TYPE "crop_status" AS ENUM (
  'borrador',
  'activa',
  'pausada',
  'agotada'
);

CREATE TYPE "negotiation_status" AS ENUM (
  'propuesta',
  'contraofertada',
  'acordada',
  'completada',
  'rechazada',
  'cancelada'
);

CREATE TYPE "delivery_method" AS ENUM (
  'transportadora',
  'en_finca',
  'punto_acordado'
);

CREATE TYPE "unit_type" AS ENUM (
  'bulto',
  'canastilla',
  'caja',
  'tonelada',
  'arroba'
);

CREATE TYPE "cost_category" AS ENUM (
  'jornales',
  'fertilizantes',
  'transporte',
  'otros'
);

CREATE TYPE "inventory_movement_type" AS ENUM (
  'reserva',
  'liberacion_reserva',
  'venta',
  'ajuste'
);

CREATE TABLE "profiles" (
  "id" uuid PRIMARY KEY,
  "phone" varchar(20) UNIQUE NOT NULL,
  "full_name" varchar(100),
  "role" user_role NOT NULL,
  "verification_status" user_verification_status NOT NULL DEFAULT 'pendiente',
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "verification_attempts" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "user_id" uuid NOT NULL,
  "status" user_verification_status NOT NULL DEFAULT 'pendiente',
  "document_front_path" text,
  "document_back_path" text,
  "selfie_path" text,
  "ocr_result" jsonb,
  "face_match_result" jsonb,
  "ai_result" jsonb,
  "moderator_result" jsonb,
  "rejection_reason" text,
  "reviewed_by" uuid,
  "reviewed_at" timestamptz,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "crops" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "farmer_id" uuid NOT NULL,
  "title" varchar(150) NOT NULL,
  "description" varchar(350) NOT NULL,
  "crop_type" varchar(100) NOT NULL,
  "price_per_kg" numeric(12,2) NOT NULL,
  "stock_total" numeric(12,2) NOT NULL,
  "stock_committed" numeric(12,2) NOT NULL DEFAULT 0,
  "stock_sold" numeric(12,2) NOT NULL DEFAULT 0,
  "min_order_kg" numeric(12,2) NOT NULL DEFAULT 1,
  "estimated_yield_kg" numeric(12,2),
  "department" varchar(100) NOT NULL,
  "municipality" varchar(100) NOT NULL,
  "latitude" numeric(10,7),
  "longitude" numeric(10,7),
  "is_early_sale" boolean NOT NULL DEFAULT false,
  "estimated_harvest_date" date,
  "status" crop_status NOT NULL DEFAULT 'borrador',
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "crop_images" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "crop_id" uuid NOT NULL,
  "image_path" text NOT NULL,
  "is_primary" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "unit_conversions" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "crop_type" varchar(100) NOT NULL,
  "unit_type" unit_type NOT NULL,
  "kg_equivalent" numeric(12,3) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "crop_costs" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "crop_id" uuid NOT NULL,
  "category" cost_category NOT NULL,
  "description" varchar(350) NOT NULL,
  "amount" numeric(12,2) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "negotiations" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "crop_id" uuid NOT NULL,
  "buyer_id" uuid NOT NULL,
  "status" negotiation_status NOT NULL DEFAULT 'propuesta',
  "current_responder" user_role,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "negotiation_offers" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "negotiation_id" uuid NOT NULL,
  "sender_id" uuid NOT NULL,
  "quantity_kg" numeric(12,2) NOT NULL,
  "proposed_price_per_kg" numeric(12,2) NOT NULL,
  "delivery_method" delivery_method NOT NULL,
  "message" text,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "negotiation_consents" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "negotiation_id" uuid UNIQUE NOT NULL,
  "farmer_id" uuid NOT NULL,
  "share_phone" boolean NOT NULL DEFAULT false,
  "share_location" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "inventory_movements" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "crop_id" uuid NOT NULL,
  "negotiation_id" uuid,
  "movement_type" inventory_movement_type NOT NULL,
  "quantity_kg" numeric(12,2) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "reviews" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "negotiation_id" uuid NOT NULL,
  "reviewer_id" uuid NOT NULL,
  "reviewed_user_id" uuid NOT NULL,
  "rating" smallint NOT NULL,
  "comment" text,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE UNIQUE INDEX ON "unit_conversions" ("crop_type", "unit_type");

CREATE UNIQUE INDEX ON "reviews" ("negotiation_id", "reviewer_id");

COMMENT ON TABLE "profiles" IS 'Perfil principal del usuario.

La autenticación se gestiona mediante Supabase Auth.
profiles.id corresponde a auth.users.id.
';

COMMENT ON TABLE "crops" IS 'Publicación de una cosecha/lote.

stock_disponible =
stock_total - stock_committed - stock_sold

latitude y longitude son información sensible
y no deberían exponerse mediante la vista pública.
';

COMMENT ON TABLE "negotiations" IS 'Representa la negociación entre comprador y productor.

El productor se obtiene desde:
crops.farmer_id
';
ALTER TABLE "verification_attempts" ADD FOREIGN KEY ("user_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "verification_attempts" ADD FOREIGN KEY ("reviewed_by") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "crops" ADD FOREIGN KEY ("farmer_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "crop_images" ADD FOREIGN KEY ("crop_id") REFERENCES "crops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "crop_costs" ADD FOREIGN KEY ("crop_id") REFERENCES "crops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "negotiations" ADD FOREIGN KEY ("crop_id") REFERENCES "crops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "negotiations" ADD FOREIGN KEY ("buyer_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "negotiation_offers" ADD FOREIGN KEY ("negotiation_id") REFERENCES "negotiations" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "negotiation_offers" ADD FOREIGN KEY ("sender_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "negotiation_consents" ADD FOREIGN KEY ("negotiation_id") REFERENCES "negotiations" ("id") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "negotiation_consents" ADD FOREIGN KEY ("farmer_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "inventory_movements" ADD FOREIGN KEY ("crop_id") REFERENCES "crops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "inventory_movements" ADD FOREIGN KEY ("negotiation_id") REFERENCES "negotiations" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("negotiation_id") REFERENCES "negotiations" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("reviewer_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("reviewed_user_id") REFERENCES "profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;


-- Relación correcta entre el perfil de la aplicación y Supabase Auth.
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_auth_users_fkey
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
