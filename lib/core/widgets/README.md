# Core Widgets (`lib/core/widgets/`)

Esta carpeta centraliza los **componentes visuales reutilizables y agnósticos al dominio** de la aplicación **KUS** (KumpaSumaq • Comercio agrícola directo).

---

## 1. Propósito

Proveer bloques de construcción de interfaz de usuario consistentes, accesibles y desacoplados de la lógica de negocio, diseñados para ser consumidos transversalmente por dos o más módulos (`features`).

---

## 2. Tipos de componentes permitidos

Se incorporarán progresivamente componentes atómicos y moleculares reutilizables como:

* **Botones:** Botones principales, secundarios, de texto o con estados de carga.
* **Entradas de texto (Inputs):** Campos de formulario estilizados con validación visual unificada.
* **Tarjetas (Cards):** Contenedores base con sombras, bordes y estilos del tema.
* **Búsqueda:** Barras y campos de búsqueda genéricos.
* **Indicadores de estado / Carga:** Spinners, shimmers, esqueletos y vistas de carga.
* **Diálogos y Modales:** Modales de confirmación, alertas informativas y bottom sheets genéricos.
* **Selectores y Chips:** Dropdowns comunes, selectores de fecha/hora y tags.
* **Feedback:** Banners de error, estados vacíos genéricos y snackbars.

---

## 3. ¿Cuándo un componente debe ser agregado a `core/widgets/`?

Aplica la regla de abstracción guiada por el uso real:

1. **Reutilización transversal:** El componente es requerido o utilizado por **dos o más features** distintas (ej. utilizado tanto en `auth` como en `crops`).
2. **Agnóstico al negocio:** No depende de entidades ni modelos específicos de un módulo (no debe recibir directamente un modelo como `Crop` o `Negotiation`, sino propiedades primitivas como `title`, `onPressed`, `icon`, etc.).
3. **Alineación con el Design System:** Consume directamente los tokens definidos en `lib/core/theme/` (`AppColors`, `AppDimensions`, `AppTextStyles`, `ThemeData`).

---

## 4. Diferencia entre un Widget Global y uno Específico de Módulo

| Criterio | Widget Global (`core/widgets/`) | Widget de Módulo (`features/<feature>/presentation/widgets/`) |
| :--- | :--- | :--- |
| **Alcance** | Toda la aplicación. | Únicamente el módulo al que pertenece. |
| **Dependencia de datos** | Solo tipos primitivos, callbacks o widgets hijos genéricos. | Conoce modelos del dominio del feature (ej. `CropCard` que recibe `CropItem`). |
| **Lógica de negocio** | Sin lógica de negocio ni llamadas a repositorios/servicios. | Puede interactuar con blocs, providers o estados locales del módulo. |
| **Ejemplo** | `AppPrimaryButton`, `CustomTextInput`, `EmptyStateView` | `CropNegotiationTile`, `AuthTermsCheckbox`, `InventoryFilterSheet` |

---

## 5. Reglas de implementación futura

* No crear componentes anticipados sin un caso de uso real confirmado.
* Exportar componentes a través de un archivo barril si se requiere simplificar importaciones.
* Mantener alta composabilidad y respetar el soporte para temas claro y oscuro mediante `Theme.of(context)`.

---

## 6. Sistema visual KUS (Fase 7B, parte 1)

Todos los componentes siguen el sistema "Apple Agri-Fintech": fondo agrupado, superficies planas con borde de 1px, controles de 14px, tipografía Plus Jakarta Sans empaquetada e iconografía Lucide.

| Carpeta | Componente | Notas |
| :--- | :--- | :--- |
| `brand/` | `KusBrandLogo` | Variantes `compact`, `header`, `hero`; `onBrandStage` para fondos de marca. |
| `brand/` | `TopoContoursPainter` | Curvas de nivel de la marca (altiplano nariñense). |
| `loading/` | `AppLoading`, `LoadingIndicator`, `LoadingContent` | Escenario de marca, indicador iOS y esqueleto con shimmer. |
| `loading/` | `AppShimmer`, `AppSkeletonBlock` | Shimmer con colores del tema; se detiene con "Reducir movimiento". |
| `misc/` | `PressableScale`, `AppEntrance` | Respuesta táctil (0.97) y entradas únicas sin temporizadores pendientes. |

Movimiento: duraciones y curvas en `lib/core/theme/app_motion.dart` (UI < 300ms, ease-out fuerte). Color: tríadas semánticas (fondo suave + borde 1px + primer plano) en `AppThemeColors`; usar `app<Estado>Text` para texto pequeño.

## 7. Componentes añadidos en la Fase 7B, parte 2

| Carpeta | Componente | Notas |
| :--- | :--- | :--- |
| `cards/` | `InsetGroupCard` | Tarjeta agrupada iOS: `surface`, radio 20 y borde de 1px, sin sombra. |
| `feedback/` | `StatusBanner`, `StatusTone` | Mensaje en línea con la tríada semántica (éxito, error, aviso, IA, marca, neutro). |
| `feedback/` | `showAppSnackBar` | Cápsula flotante neutra; el tono vive solo en el icono para mantener el contraste. |
| `buttons/` | `SecondaryActionButton` | Acompaña al botón primario (52px); tonos `neutral`, `destructive` e `ai`, con micro-loader. |
| `scanner/` | `ScannerViewfinder`, `ScannerChip` | Marco de escáner tipo Wallet con esquinas iluminadas y un barrido único de la guía. |
| `scanner/` | `BiometricFrame`, `CornerBracketsPainter` | Dial tipo Face ID para la selfie y esquinas redondeadas reutilizables. |

`StepProgressBar` ahora muestra "Paso n de N" y rellena el segmento recién alcanzado; `TipPill` se ajusta a su contenido para usarse en `Wrap`; `CustomTextField` siempre muestra su icono al inicio del campo.

## 8. Componentes añadidos en la Fase 7B, parte 4

| Carpeta | Componente | Notas |
| :--- | :--- | :--- |
| `inputs/` | `AppSegmentedControl`, `AppSegment` | Control segmentado deslizante iOS sobre `surfaceVariant`; el segmento elegido gana peso y tinta. `showDot` marca un filtro con trabajo pendiente; `compact` para filas de ajustes. |
| `inputs/` | `ChoiceTile` | Opción de un selector exclusivo pequeño (método de entrega): icono sobre etiqueta, tono suave de marca al elegirse. |
| `cards/` | `InsetGroupSection`, `InsetGroupRow` | Lista agrupada iOS: encabezado, filas sobre una tarjeta plana con separadores indentados y nota al pie. `destructive` centra la fila en tono de error ("Cerrar sesión"). |

`CustomTextField` acepta ahora `maxLines`, `maxLength`, `enabled` y `textCapitalization`; en campos de varias líneas el icono se mantiene en la primera línea. El color `appSegmentThumb` eleva el segmento elegido en modo oscuro.
