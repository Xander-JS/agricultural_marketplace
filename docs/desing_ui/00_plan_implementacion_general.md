# Resumen de la Ruta de Implementación (4 Prompts)

```
[Prompt 1: Base Global, Marca KUS, Cero "Simulado" y Loaders]  (Ya entregado)
                              ↓
[Prompt 2: Acceso, Onboarding, Guías de Cédula/FaceID y Panel Admin]
                              ↓
[Prompt 3: Animación de Sección, Mercado, Costos IA y Ventanas Flotantes]
                              ↓
[Prompt 4: Negociación (Chat), Consentimiento, Compras, Calificación y Perfil]
```

---

## Desglose de qué cambios traerá cada Prompt a tu aplicación

### 🔹 PROMPT 1: Motor de Tema Global (Estilo iOS), Marca "KUS", Limpieza de "Simulado" y Componentes Base (El que ya tienes listo)

**Qué transforma en la app:**
* **Identidad de Marca (KusBrandLogo):** Crea el logo compuesto oficial combinando tus iconos (`app_movil_only_sm/lg/xl.png`) con la sigla KUS (KumpaSumaq / Kumaq) y lo adapta automáticamente al Modo Claro y Modo Oscuro.
* **Eliminación de "Simulado":** Borra de raíz las palabras "simulado", "ficticio" o "demostración" en español e inglés (`app_es.arb` / `app_en.arb`), reemplazándolas por textos de IA activa en tiempo real ("Análisis Biométrico KUS Vision", "Proyección de mercado KUS IA").
* **Paleta y Contraste Perfecto (Apple HIG):** Instala el color primario Esmeralda Institucional (`#14532D` en Claro / `#34D399` en Oscuro), fondos agrupados estilo iPhone (`#F4F6F4` / `#0B110E`) y la tríada de colores para Errores, Información, Alertas y Éxito (fondo pastel + borde 1px + icono/texto fuerte) garantizando que jamás quede texto blanco sobre fondo claro.
* **Loaders y Componentes Atómicos (`lib/core/widgets/`):** Rediseña la barra inferior (`AppBottomNavigation`) con efecto cristal e iconos profesionales de `LucideIcons`, agrega micro-loaders a los botones (`PrimaryActionButton`), e implementa esqueletos brillantes Shimmer en `loading_content.dart` y en la carga de fotos de Supabase Storage.

---

### 🔹 PROMPT 2: Autenticación, Recuperación de Contraseña, Guías Documentales (`assets/images`) y Panel del Administrador

**Qué transforma en la app:**
* **Bienvenida, Login y Recuperar Contraseña (`WelcomeScreen`, `LoginScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen`):** Rediseña el TopoHeader integrando el logo KUS en formato Hero, estiliza los formularios con bordes suaves estilo iOS, mejora las alertas flotantes de error/confirmación y deja el flujo de recuperación de contraseña con apariencia bancaria limpia.
* **Registro Multi-paso y Visor de Cédula / Face ID (`CaptureFrontScreen`, `CaptureBackScreen`, `FacialVerificationScreen`):** Toma tus imágenes guía (`cc_frontal.png`, `cc_reverso.png`, `licencia_frontal.png`, `licencia_reverso.png` y `face_id.png`) y las mete dentro de marcos estéticos tipo Escáner de Apple Wallet / Face ID, con esquinas iluminadas, barra de progreso por pasos (`StepProgressBar`) estilizada y pantalla de espera (`VerificationStatusScreen`) con animaciones de estado.
* **Panel del Administrador / Moderador (`ModerationQueueScreen`, `ModerationDetailScreen`):** Aunque el panel es directo, lo deja impecable: tarjetas ejecutivas para cada solicitud pendiente, visor de las 3 fotos con carga Shimmer (`DocumentImagePreview`) y transforma la antigua tarjeta `SimulatedDocumentDiagnosisCard` en un Panel de Telemetría y Verificación IA en color Azul Zafiro (`#0284C7` / `#38BDF8`) con insignias limpias para aprobar o rechazar.

---

### 🔹 PROMPT 3: Animaciones del Dashboard (Cambio de Sección), Mercado, Calculadora de Costos y Ventanas Flotantes de Cosechas

**Qué transforma en la app:**
* **Animación al cambiar de sección en el Bar (`MainDashboardScreen`):** Implementa la transición suave estilo iOS (Fade + Slide sutil de 220ms con `flutter_animate`) cada vez que el agricultor o el comprador toca una de las 4 pestañas inferiores, mostrando los esqueletos Shimmer mientras cargan los datos de cada sección.
* **Catálogo y Detalle de Cosecha (`MarketplaceScreen`, `CropCard`, `CropDetailScreen`, `PublishCropScreen`):**
  * Buscador y chips de filtro/ordenamiento estilo iOS en la parte superior.
  * Tarjetas `CropCard` con borde fino de 1px, insignias de Venta Anticipada y Distancia (a 12 km) en cápsulas de alto contraste, precio en COP con números tabulares (`$ 200.000`) y reputación (`★ 4.8`).
  * Galería multi-imagen tipo carrusel con indicador de puntos en `CropDetailScreen`.
* **Módulo de Costos y Rentabilidad (`CostsScreen`, `CropCostsDetailScreen`, `CropProfitabilityScreen`):** Tarjetas financieras limpias por categoría (jornales, fertilizantes, fletes) con iconos de `LucideIcons` y comparativa visual frente al índice regional de Nariño.
* **Ventanas Flotantes con Cristal Esmerilado (Frosted Glass):**
  * `UnitEquivalencesSheet`: Grilla 2x2 estilo iOS con iconos para Bultos, Canastillas, Cajas y Arrobas.
  * `VoiceCropAssistantSheet`: Ventana flotante del asistente de voz con ondas animadas de pulso mientras escucha o procesa con IA.
  * `MakeOfferSheet`: Hoja flotante para ofertar con resumen dinámico del subtotal en COP.

---

### 🔹 PROMPT 4: Negociación (Burbujas de Tratos), Consentimiento de Privacidad, Compras, Calificación y Perfil

**Qué transforma en la app:**
* **Tratos y Línea de Tiempo de Ofertas (`DealsScreen`, `DealDetailScreen`, `CounterOfferScreen`):**
  * Pestañas superiores tipo selector deslizante de iPhone (Todas, En curso, Acordadas, Finalizadas).
  * Rediseño total de las burbujas de negociación en `DealDetailScreen`: estilo iMessage / Apple Pay, diferenciando claramente tus ofertas de las de la contraparte, con indicador visual de quién tiene el turno activo.
* **Ventanas Flotantes de Privacidad y Calificación (`_AcceptOfferConsentSheet`, `_EditConsentSheet`, `_RatingSheet`):**
  * Modal estético con switches estilo iOS e iconos de escudo/privacidad para que el agricultor decida si libera su WhatsApp y ubicación al aceptar el trato.
  * Modal de calificación post-venta con estrellas interactivas animadas y comentario opcional.
* **Compras del Comerciante y Perfil Unificado (`PurchasesScreen`, `PurchaseCard`, `FarmerProfileScreen`):**
  * Tarjetas de resumen de compras e inversión acumulada.
  * Perfil estilo configuración de iOS (Inset Grouped List): avatar con anillo de estado verificado y recarga instantánea, tarjetas de métricas comerciales (Publicados, Negociando, Cerrados) y switches limpios para cambiar entre Modo Claro / Oscuro e Idioma (ES / EN) en vivo frente al profesor.