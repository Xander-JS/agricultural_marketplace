# Diagnóstico Técnico y Corrección del Error 22P02 al Crear Ofertas

> **Proyecto:** Agricultural Marketplace (Flutter + Supabase)  
> **Rama de trabajo:** `feacture/comprador`  
> **Documento de Auditoría y Verificación:** `DIAGNOSTICO_ERROR_OFERTAS_22P02.md`  
> **Fecha:** Octubre 2026  

---

## 1. Causa raíz comprobada

El error reportado en el dispositivo físico:

```
PostgrestException(message: invalid input value for enum user_role: "farmer", code: 22P02, details: Bad Request, hint: null)
```

corresponde al código de error PostgreSQL **`22P02` (`invalid_text_representation`)**.

### Evidencia empírica directa contra la base de datos de Supabase
Se ejecutó una prueba directa contra el endpoint REST de la instancia en vivo de Supabase (`https://vmoubpokzsdlotqdiskk.supabase.co/rest/v1/negotiations`):

1. **Petición enviando `"current_responder": "farmer"`:**
   ```bash
   curl -s -X POST \
     -H "apikey: <SUPABASE_ANON_KEY>" \
     -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"current_responder":"farmer"}' \
     "https://vmoubpokzsdlotqdiskk.supabase.co/rest/v1/negotiations"
   ```
   **Respuesta de PostgreSQL:**
   ```json
   {"code":"22P02","details":null,"hint":null,"message":"invalid input value for enum user_role: \"farmer\""}
   ```

2. **Petición enviando `"current_responder": "agricultor"`:**
   ```bash
   curl -s -X POST \
     -H "apikey: <SUPABASE_ANON_KEY>" \
     -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"current_responder":"agricultor"}' \
     "https://vmoubpokzsdlotqdiskk.supabase.co/rest/v1/negotiations"
   ```
   **Respuesta de PostgreSQL:**
   ```json
   {"code":"42501","details":null,"hint":null,"message":"new row violates row-level security policy for table \"negotiations\""}
   ```

**Conclusión comprobada:**
- El tipo enum PostgreSQL `user_role` **rechaza estrictamente** la cadena `"farmer"` disparando el error `22P02`.
- El tipo enum PostgreSQL `user_role` **acepta** la cadena canónica `"agricultor"`, superando la validación del enum sin error `22P02`.

---

## 2. Archivos y métodos exactos que originaban el error

### A. Archivo de Servicio: `lib/features/deals/services/negotiation_service.dart`
- **Método:** `createNegotiation(...)`
- **Operación:** Inserción en la tabla `negotiations`.
- **Columna afectada:** `current_responder` (tipo `user_role`).
- **Valor rechazado:** `'farmer'`.
- **Valor admitido:** `'agricultor'`.

### B. Archivo de Pantalla: `lib/features/deals/screens/counter_offer_screen.dart`
- **Método:** `_submit()`
- **Operación:** Inserción y actualización de turnos en `negotiations`.
- **Valores anteriores:** `final nextResponder = _isBuyer ? 'farmer' : 'buyer';`
- **Valores corregidos:** `final nextResponder = _isBuyer ? UserRole.agricultor.toDbValue() : UserRole.comprador.toDbValue();`

### C. Archivo de Registro: `lib/features/auth/registro/services/registration_service.dart`
- **Método:** `registerUser(...)`
- **Operación:** Inserción en tabla `profiles`.
- **Columna:** `role` (tipo `user_role`).
- **Blindaje aplicado:** Se normalizó con `UserRole.toDb(role)` para impedir que cualquier entrada sin normalizar alcance `profiles.role`.

---

## 3. Cambios aplicados en el código de la aplicación

1. **Constructores estáticos de Payload en `NegotiationService`:**
   Se desacopló la construcción de payloads a métodos con aserciones estrictas que impiden cualquier inclusión de `'farmer'`:
   - `NegotiationService.buildInitialNegotiationPayload(...)`:
     ```dart
     static Map<String, dynamic> buildInitialNegotiationPayload({
       required String cropId,
       required String buyerId,
       required String timestamp,
     }) {
       final roleDb = UserRole.agricultor.toDbValue();
       assert(roleDb == 'agricultor' && roleDb != 'farmer');
       return {
         'crop_id': cropId,
         'buyer_id': buyerId,
         'status': NegotiationStatus.propuesta.toShortString(),
         'current_responder': roleDb, // 'agricultor'
         'created_at': timestamp,
         'updated_at': timestamp,
       };
     }
     ```
   - `NegotiationService.buildOfferPayload(...)`:
     Traduce el método de entrega de la interfaz (`'En finca'`, `'Transportadora / Bodega'`, etc.) a los valores exactos del enum PostgreSQL `delivery_method` (`'en_finca'`, `'punto_acordado'`, `'transportadora'`).
   - `NegotiationService.buildCounterOfferNegotiationPayload(...)`:
     Normaliza el rol que responde a `'agricultor'` o `'comprador'`.

2. **Atomicidad de rollback:**
   Si la inserción en `negotiation_offers` falla, el servicio ejecuta de inmediato la eliminación del registro en `negotiations` para evitar registros huérfanos.

3. **Prevención de envíos múltiples:**
   Tanto `MakeOfferSheet` como `CounterOfferScreen` deshabilitan el botón de envío y bloquean reentradas mediante indicadores booleanos (`_isSubmitting`, `_isLoading`).

---

## 4. Consulta SQL de Auditoría para Supabase SQL Editor

Si tras compilar la aplicación actualizada el backend aún emitiera el error `22P02`, este provendría de una política RLS o un Trigger en PostgreSQL que evalúa internamente la condición `role = 'farmer'` o `current_responder = 'farmer'`.

Ejecuta la siguiente consulta de **solo lectura** en el **SQL Editor de Supabase**:

```sql
-- ============================================================================
-- AUDITORÍA DE ENUMS, COLUMNAS, TRIGGERS Y POLÍTICAS CON REFERENCIAS A 'farmer'
-- ============================================================================

-- 1. Valores reales del enum user_role en la base de datos
SELECT 
    t.typname AS enum_name,
    e.enumlabel AS enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- 2. Columnas que usan el enum user_role y sus valores por defecto
SELECT 
    table_name, 
    column_name, 
    data_type, 
    udt_name, 
    column_default, 
    is_nullable
FROM information_schema.columns
WHERE udt_name = 'user_role'
ORDER BY table_name, column_name;

-- 3. Triggers activos en las tablas del ciclo comercial
SELECT 
    event_object_table AS tabla,
    trigger_name,
    event_manipulation AS evento,
    action_timing AS momento,
    action_statement AS definicion
FROM information_schema.triggers
WHERE event_object_table IN ('negotiations', 'negotiation_offers', 'crops', 'profiles')
ORDER BY event_object_table;

-- 4. Políticas RLS en negotiations, crops y profiles que contengan 'farmer'
SELECT 
    tablename,
    policyname,
    roles,
    cmd,
    qual AS using_expression,
    with_check AS check_expression
FROM pg_policies
WHERE tablename IN ('negotiations', 'negotiation_offers', 'crops', 'profiles')
  AND (qual::text ILIKE '%farmer%' OR with_check::text ILIKE '%farmer%');

-- 5. Restricciones de Check en las tablas que contengan 'farmer'
SELECT 
    r.relname AS tabla,
    c.conname AS nombre_restriccion,
    pg_get_constraintdef(c.oid) AS definicion
FROM pg_constraint c
JOIN pg_class r ON r.oid = c.conrelid
WHERE pg_get_constraintdef(c.oid) ILIKE '%farmer%';
```

> **Interpretación:**  
> Si la consulta 4 devuelve alguna política RLS con `with_check` o `qual` que compare `current_responder = 'farmer'` o `role = 'farmer'`, esa política debe actualizarse en Supabase a `'agricultor'`, ya que PostgreSQL no puede castear `'farmer'` al enum `user_role`.

---

## 5. Resultados de pruebas automatizadas

### A. Batería de Regresión (`test/corrective_offers_test.dart`)
14 pruebas unitarias ejecutadas y aprobadas:
- `buildInitialNegotiationPayload NUNCA envía "farmer" y asigna canónicamente "agricultor"`: **APROBADO**
- `buildOfferPayload mapea métodos de entrega válidos hacia el enum PostgreSQL delivery_method`: **APROBADO**
- `buildCounterOfferNegotiationPayload normaliza nextResponderRole y no propaga "farmer"`: **APROBADO**
- `UserRole.toDb mapea identificadores de usuario evitando strings incompatibles`: **APROBADO**
- Mapeo bidireccional y normalización de enums: **APROBADO**

### B. Análisis Estático
- **Comando:** `flutter analyze`
- **Resultado:** **0 errores en el proyecto**.

### C. Total de la Suite de Pruebas
- **Comando:** `flutter test`
- **Resultado:** **81 de 81 pruebas aprobadas (100%)** en 9 segundos.

---

## 6. Pasos manuales de verificación en el dispositivo físico

1. **Recompilar limpiamente la aplicación en el dispositivo:**
   Para asegurar que el APK o binario no conserve cachés anteriores de Dart:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
2. **Iniciar sesión:**
   Ingresar con un usuario con rol Comprador / Comerciante con estado de verificación `aprobado`.
3. **Navegar a Cosecha:**
   Abrir una cosecha activa en el mercado con stock disponible.
4. **Abrir Modal de Oferta:**
   Pulsar *«Hacer oferta / Negociar»*.
5. **Configurar la propuesta:**
   - Cantidad: Introducir un valor superior o igual al pedido mínimo y menor o igual al stock disponible.
   - Precio: Definir precio por kg propuesto.
   - Entrega: Seleccionar cualquiera de las opciones (ej. *En finca*).
6. **Enviar propuesta:**
   Pulsar *«Enviar propuesta»*.
   - Se muestra el indicador de carga.
   - La negociación se inserta con `current_responder: 'agricultor'`.
   - La oferta se inserta en `negotiation_offers`.
   - Se muestra el SnackBar verde *«Propuesta enviada exitosamente»*.
7. **Verificación en Tratos:**
   Abrir la pestaña *Tratos*. La nueva negociación debe aparecer con el badge *«Esperando respuesta del productor»*.
