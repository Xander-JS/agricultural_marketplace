# Corrección de Ofertas, Preferencias Globales y Ciclo Comercial

> **Documento de Auditoría y Entrega Técnica**  
> **Proyecto:** Agricultural Marketplace (Flutter + Supabase)  
> **Rama:** `feacture/comprador`  
> **Fecha:** Octubre 2026  
> **Autor:** Antigravity Pair Programming Engine

---

## 1. Causa raíz comprobada del error `22P02`

### Diagnóstico
Al intentar emitir una oferta inicial desde el modal de negociación en `CropDetailScreen`, el backend Supabase / PostgREST devolvía la siguiente excepción:

```
PostgrestException(message: invalid input value for enum user_role: "farmer", code: 22P02, details: Bad Request, hint: null)
```

### Inspección del esquema PostgreSQL
Al verificar la definición DDL del esquema de base de datos en `/home/mxander/Documentos/app_movil/app_movil.sql`, se constató la siguiente definición:

```sql
CREATE TYPE user_role AS ENUM (
    'agricultor',
    'comprador',
    'moderador'
);

CREATE TABLE negotiations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE NOT NULL,
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    status VARCHAR(20) DEFAULT 'propuesta',
    current_responder user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Origen exacto
En `lib/features/deals/services/negotiation_service.dart`, el método `createNegotiation` insertaba en la columna `current_responder`:

```dart
// Código anterior erróneo:
'current_responder': 'farmer',
```

Dado que la columna `current_responder` tiene como tipo el enum PostgreSQL `user_role`, el valor en inglés `'farmer'` no está presente en el tipo enum (`'agricultor'`, `'comprador'`, `'moderador'`), disparando el error de sintaxis y tipado `22P02` (data exception: invalid text representation).

Asimismo, `negotiation_offers.delivery_method` requiere valores compatibles con el enum `delivery_method` (`'en_finca'`, `'punto_acordado'`, `'transportadora'`), mientras que la interfaz enviaba etiquetas legibles en español con espacios y mayúsculas (`'En finca'`, `'Destino final'`).

---

## 2. Archivos modificados y razón de cada cambio

| Archivo | Motivo del cambio |
| :--- | :--- |
| `pubspec.yaml` | Trasladar `shared_preferences` a `dependencies` directas de producción para permitir la persistencia en dispositivo del tema e idioma. |
| `lib/core/constants/user_roles.dart` | Crear la correspondencia bidireccional centralizada entre los enums de PostgreSQL (`user_role`, `verification_status`) y los identificadores internos de Flutter. |
| `lib/core/constants/delivery_methods.dart` | Crear mapeo canónico entre etiquetas visuales de la UI y los valores del enum PostgreSQL `delivery_method` (`en_finca`, `punto_acordado`, `transportadora`). |
| `lib/features/crop/models/crop_model.dart` | Añadir getter calculado `availableStock` cumpliendo estrictamente con la regla `stock_disponible = max(0, stock_total - stock_comprometido - stock_vendido)`. |
| `lib/features/deals/models/negotiation_model.dart` | Incorporar métodos tipados `isFarmerTurn`, `isBuyerTurn` e `isMyTurn(isBuyer: ...)` con tolerancia a identificadores históricos y serialización canónica hacia PostgreSQL. |
| `lib/features/deals/models/negotiation_offer_model.dart` | Incorporar resolución segura de métodos de entrega y normalización de turnos en ofertas. |
| `lib/features/deals/services/negotiation_service.dart` | Corregir `current_responder` con `UserRole.agricultor.toDbValue()`, mapear métodos de entrega, agregar rollback transaccional en cliente ante fallos en la oferta inicial, validar verificación de cuenta aprobada antes de comerciar y añadir transiciones de inventario para aceptación (`reserva`), compleción (`venta`), rechazo y cancelación (`liberacion_reserva`). |
| `lib/features/crop/widgets/make_offer_sheet.dart` | Validar contra `availableStock`, impedir envíos concurrentes mediante guard de submit y utilizar opciones centralizadas de `DeliveryMethod`. |
| `lib/features/crop/screens/crop_detail_screen.dart` | Bloquear apertura de ofertas si la cosecha no tiene stock disponible o si la cuenta del usuario no está aprobada (`UserVerificationStatus.aprobado`). |
| `lib/features/deals/screens/counter_offer_screen.dart` | Enviar `nextResponder` tipado a PostgreSQL (`agricultor` / `comprador`), prevenir doble envío y mapear etiquetas de entrega. |
| `lib/features/deals/screens/deal_detail_screen.dart` | Adaptar resolución de turnos con `negotiation.isMyTurn()`, agregar acción de completar entrega física con reserva y diálogo de confirmación localizado. |
| `lib/features/deals/screens/deals_screen.dart` | Utilizar `UserRole.isBuyerRole()` y `negotiation.isMyTurn()` para segmentar con precisión las pestañas de tratos por responder vs. en espera. |
| `lib/core/services/app_preferences_service.dart` | Implementar servicio singleton reactivo (`ChangeNotifier`) respaldado por `SharedPreferences` para controlar `ThemeMode` y `Locale`. |
| `lib/main.dart` | Envolver `MaterialApp` en un `ListenableBuilder` suscrito a `AppPreferencesService`, permitiendo reconstrucciones reactivas instantáneas de tema e idioma sin reiniciar la app. |
| `lib/features/profile/screens/farmer_profile_screen.dart` | Conectar los `SwitchListTile` de "Modo oscuro" e "Idioma inglés" directamente a `AppPreferencesService.instance.toggleDarkMode()` y `toggleEnglish()`. |
| `lib/core/localization/app_es.arb` y `app_en.arb` | Añadir 30+ claves localizadas para el ciclo de negociación, diálogos de confirmación, inventario, verificación y estados, manteniendo paridad simétrica al 100%. |
| `lib/core/localization/app_localizations*.dart` | Archivos autogenerados por el compilador `flutter gen-l10n`. |
| `lib/features/auth/registro/screens/processing_screen.dart` | Retirar import y variable no utilizada para mantener el análisis estático limpio. |
| `test/widget_test.dart` | Actualizar el test inicial del proyecto para instanciar `AgriculturalMarketplaceApp` con mocks de `SharedPreferences`. |
| `test/integration_role_test.dart` | Eliminar import redundante de `main_dashboard_screen.dart`. |
| `test/corrective_offers_test.dart` | 10 pruebas unitarias para mapeo de roles, cálculo de stock disponible, serialización a PostgreSQL, prevención de duplicados y transiciones de turno. |
| `test/theme_and_locale_preferences_test.dart` | 6 pruebas de integración y widgets validando reactividad inmediata de tema claro/oscuro e idioma español/inglés y persistencia en `SharedPreferences`. |
| `test/inventory_commercial_cycle_test.dart` | 5 pruebas unitarias verificando el ciclo completo de inventario (reserva, venta, liberación, cancelación y transiciones de estado). |

---

## 3. Correcciones aplicadas al mapeo de roles

Se diseñó la clase [UserRole](file:///home/mxander/StudioProjects/agricultural_marketplace/lib/core/constants/user_roles.dart) con semántica estricta:

```dart
enum UserRole {
  agricultor,
  comprador,
  moderador;

  /// Conversión canónica al valor exacto admitido por el tipo PostgreSQL `user_role`
  String toDbValue() {
    switch (this) {
      case UserRole.agricultor: return 'agricultor';
      case UserRole.comprador: return 'comprador';
      case UserRole.moderador: return 'moderador';
    }
  }

  /// Mapeo tolerante y centralizado desde cualquier cadena interna o externa
  static UserRole fromString(String? role) {
    if (role == null) return UserRole.comprador;
    final r = role.trim().toLowerCase();
    switch (r) {
      case 'agricultor':
      case 'farmer':
      case 'producer':
        return UserRole.agricultor;
      case 'comprador':
      case 'buyer':
      case 'comerciante':
        return UserRole.comprador;
      case 'moderador':
      case 'moderator':
      case 'admin':
        return UserRole.moderador;
      default:
        return UserRole.comprador;
    }
  }

  static bool isFarmerRole(String? role) => fromString(role) == UserRole.agricultor;
  static bool isBuyerRole(String? role) => fromString(role) == UserRole.comprador;
}
```

### Turno inicial
Al crearse una nueva oferta de compra en `negotiations`:
- `current_responder` se inserta con `UserRole.agricultor.toDbValue()`, que evalúa a `'agricultor'`.
- El modelo `NegotiationModel` resuelve los turnos de manera agnóstica:
  - `isFarmerTurn` retorna `true` si `currentResponder` es `'agricultor'` o `'farmer'`.
  - `isBuyerTurn` retorna `true` si `currentResponder` es `'comprador'` o `'buyer'`.
  - `isMyTurn({required bool isBuyer})` determina si el usuario en pantalla debe responder la contraoferta o si debe esperar.

---

## 4. Funcionamiento del tema global

1. **Gestión centralizada:** Se implementó `AppPreferencesService` como un singleton `ChangeNotifier`.
2. **Persistencia:** Almacena la clave booleana `'pref_dark_mode'` en `SharedPreferences`.
3. **Reactividad inmediata:** En `main.dart`, el widget raíz `MaterialApp` está envuelto dentro de un `ListenableBuilder(listenable: AppPreferencesService.instance, ...)` que escucha cambios de estado.
4. **Interacción en Mi Finca:** Al pulsar el switch en `FarmerProfileScreen`, se invoca `AppPreferencesService.instance.toggleDarkMode(value)`.
5. **Resultado:** Todos los widgets dependientes de `Theme.of(context)` y de los tokens de color centralizados en `AppTheme.lightTheme` y `AppTheme.darkTheme` se redibujan de forma inmediata y automática sin requerir reinicio manual ni recargar la navegación.

---

## 5. Funcionamiento del idioma global

1. **Gestión centralizada:** Administrado en `AppPreferencesService` con la clave `'pref_locale_code'`.
2. **Soporte multilingüe:** Soporta formalmente `Locale('es')` (español, predeterminado) y `Locale('en')` (inglés).
3. **Reactividad:** El `ListenableBuilder` en `main.dart` inyecta dinámicamente `locale: prefs.locale` a `MaterialApp`.
4. **Interacción en Mi Finca:** Al activar o desactivar el interruptor "Idioma inglés" en el perfil, se ejecuta `AppPreferencesService.instance.toggleEnglish(value)`.
5. **Persistencia:** La selección se guarda inmediatamente en el almacenamiento local y se recupera de manera asíncrona durante el bootstrap en `main()`.

---

## 6. Cobertura de localización y claves ARB añadidas

Se añadieron más de 30 claves simétricas a `app_es.arb` y `app_en.arb`, ejecutando posteriormente `flutter gen-l10n`.

### Claves añadidas:
- **Validación de verificación comercial:**
  - `crop_unapproved_dialog_title`: "Verificación requerida" / "Verification Required"
  - `crop_unapproved_dialog_desc`: "Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador." / "To make offers and negotiate with farmers, your profile must be verified and approved by a moderator."
  - `crop_unapproved_dialog_action`: "Entendido" / "Got it"
- **Ciclo y confirmaciones de tratos:**
  - `deal_agreed_desc`: "Trato acordado. Coordina la entrega física para completar la operación." / "Deal agreed. Coordinate physical delivery to complete the operation."
  - `deal_complete_btn`: "Confirmar entrega y completar trato" / "Confirm delivery and complete deal"
  - `deal_cancel_agreed`: "Cancelar acuerdo" / "Cancel agreement"
  - `deal_complete_confirm_title`: "¿Completar este trato?" / "Complete this deal?"
  - `deal_complete_confirm_desc`: "Esta acción confirmará la entrega física del producto y registrará la venta final en el inventario." / "This action will confirm physical delivery of the product and record final sale in inventory."
  - `deal_complete_confirm_btn`: "Completar" / "Complete"
  - `deal_completed_success`: "Trato completado exitosamente" / "Deal completed successfully"
- **Acciones y estados adicionales:**
  - `deal_accept_offer_btn`, `deal_counter_offer_btn`, `deal_reject_offer_btn`, `deal_cancel_offer_btn`
  - `deal_terms_summary`, `deal_delivery_method`, `deal_unit_price`, `deal_quantity_label`
  - `profile_cancel`, `profile_save_changes`, `profile_edit_title`

---

## 7. Verificación del flujo comercial y del inventario

Siguiendo las reglas estipuladas en `app_movil_estados_Sistema.docx` y el esquema relacional de Supabase:

### Fórmula de disponibilidad
$$\text{stock\_disponible} = \max(0, \text{stock\_total} - \text{stock\_comprometido} - \text{stock\_vendido})$$

Implementada nativamente en el getter `CropModel.availableStock`.

### Transiciones de inventario implementadas en `NegotiationService`:
1. **Oferta inicial / Contraoferta (`propuesta` / `contraofertada`):**
   - No descuenta ni compromete inventario por adelantado.
   - Valida estrictamente que $\text{cantidad} \ge \text{pedido\_mínimo}$ y $\text{cantidad} \le \text{stock\_disponible}$.
   - Valida que el usuario tenga estado de verificación `aprobado`.
2. **Aceptación de oferta (`acordada`):**
   - Transiciona el estado a `acordada`.
   - Incrementa `crops.stock_committed += cantidad`.
   - Registra un movimiento en `inventory_movements` con `movement_type = 'reserva'`.
3. **Compleción de trato (`completada`):**
   - Convierte la reserva en venta real:
     - `crops.stock_committed = max(0, stock_committed - cantidad)`
     - `crops.stock_sold += cantidad`
   - Si $\text{stock\_disponible} \le 0$, marca automáticamente `crops.status = 'agotada'`.
   - Registra en `inventory_movements` con `movement_type = 'venta'`.
4. **Rechazo o cancelación tras acuerdo (`rechazada` / `cancelada`):**
   - Si el trato ya estaba en estado `acordada`, libera la reserva:
     - `crops.stock_committed = max(0, stock_committed - cantidad)`
   - Registra en `inventory_movements` con `movement_type = 'liberacion_reserva'`.
5. **Resguardo y atomicidad en cliente:**
   - Si la inserción en `negotiation_offers` falla al crear una negociación, el cliente ejecuta de inmediato un rollback eliminando el registro huérfano de `negotiations` para evitar inconsistencias en base de datos.
   - En las vistas (`MakeOfferSheet`, `CounterOfferScreen`), se bloquearon pulsaciones duplicadas mediante flags booleanos (`_isSubmitting`, `_isLoading`).

---

## 8. Comandos ejecutados y resultados reales

| Comando | Resultado | Observaciones |
| :--- | :--- | :--- |
| `flutter pub get` | Exitoso (exit code 0) | Resolvió dependencias tras mover `shared_preferences` a `dependencies`. |
| `flutter gen-l10n` | Exitoso (exit code 0) | Regeneró `AppLocalizations` con todas las nuevas claves en inglés y español. |
| `flutter analyze` | Exitoso (0 errores, 2 advertencias previas) | 0 errores en el código del proyecto. Solo quedaron 2 advertencias preexistentes en widgets antiguos de badges. |
| `flutter test` | Exitoso (exit code 0) | **77/77 pruebas superadas** en 4.5 segundos (`+77: All tests passed!`). |

---

## 9. Pruebas aprobadas y pendientes

### Baterías de pruebas aprobadas (77/77):
- **Ofertas y Enums (`test/corrective_offers_test.dart` - 10 pruebas):**
  - Mapeo y serialización de `UserRole` a PostgreSQL (`agricultor`, `comprador`, `moderador`).
  - Mapeo y serialización de `DeliveryMethod` a PostgreSQL (`en_finca`, `punto_acordado`, `transportadora`).
  - Validación de `availableStock` ante stock comprometido y vendido.
  - Validación de pedido mínimo y stock disponible en `NegotiationService`.
  - Creación con `current_responder = 'agricultor'`.
  - Detección de turnos y guard contra dobles envíos concurrentes.
  - Verificación de estatus de usuario comercial (`aprobado`).
- **Tema e Idioma Global (`test/theme_and_locale_preferences_test.dart` - 6 pruebas):**
  - Cambio inmediato de `ThemeMode.light` a `ThemeMode.dark` y viceversa.
  - Cambio inmediato de `Locale('es')` a `Locale('en')` y viceversa.
  - Reconstrucción reactiva de `MaterialApp` sin reiniciar la app.
  - Persistencia de preferencias en `SharedPreferences`.
  - Integración de los switches de Mi Finca con el servicio de preferencias.
- **Ciclo Comercial e Inventario (`test/inventory_commercial_cycle_test.dart` - 5 pruebas):**
  - Creación de oferta sin alterar stock comprometido o vendido.
  - Aceptación de oferta reserva stock (`stock_committed`).
  - Compleción de trato convierte comprometido en vendido y agota cosecha cuando stock llega a 0.
  - Rechazo de acuerdo pactado libera reserva de inventario.
  - Cancelación de acuerdo pactado libera reserva de inventario.
- **Pruebas preexistentes de compras, mercado, roles e integración (56 pruebas):**
  - Todas aprobadas sin regresiones.

### Pruebas pendientes / Distinción de entorno:
- **Pruebas en cliente (Ejecutadas y Validadas):** Todas las pruebas unitarias y de widgets se ejecutaron simulando el comportamiento del motor Flutter, `SharedPreferences` y las capas del servicio.
- **Pruebas contra Supabase en vivo (Pendiente de verificación E2E en dispositivo físico con conexión remota):**
  - El error `22P02` fue reproducido y corregido a nivel de payload comprobado en el DDL (`user_role: 'agricultor'`).
  - Se recomienda probar en el dispositivo físico conectado a la base de datos real para verificar que las RLS policies de Supabase permitan los `update` en `crops` e `insert` en `inventory_movements`.

---

## 10. Riesgos que todavía requieran intervención en Supabase

De acuerdo con las restricciones de la consigna, no se alteró el esquema SQL remoto ni se ejecutaron migraciones no autorizadas. No obstante, se identifican los siguientes aspectos técnicos a considerar a nivel de backend:

1. **Políticas de Seguridad a Nivel de Fila (RLS) en `inventory_movements`:**
   - La tabla `inventory_movements` recibe inserciones desde el cliente cuando se acepta, completa o cancela un trato. Es imprescindible confirmar que exista una política `CREATE POLICY ... FOR INSERT` que permita al usuario autenticado registrar movimientos vinculados a sus cosechas/negociaciones.
2. **Políticas de actualización en `crops` (`stock_committed`, `stock_sold`):**
   - Cuando un comprador acepta o completa un trato, o cuando el agricultor confirma la entrega, el cliente realiza un `update` sobre la tabla `crops`. Las RLS deben permitir este `update` para los participantes del trato, o idealmente delegarse a una función RPC.
3. **Transaccionalidad ACID en concurrencia alta (Recomendación Arquitectónica):**
   - Aunque se implementó rollback en el cliente Flutter, si dos compradores intentan acordar simultáneamente los últimos 50 kg disponibles de una cosecha, una validación puramente en cliente podría experimentar una condición de carrera (*race condition*).
   - **Propuesta recomendada para el backend:** Implementar una función RPC con `SELECT ... FOR UPDATE` en PostgreSQL (ej. `rpc_accept_negotiation(p_negotiation_id)`) para que la reserva de stock sea 100% transaccional a nivel de motor de base de datos.
