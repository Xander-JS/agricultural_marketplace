# Core Widgets (`lib/core/widgets/`)

Esta carpeta centraliza los **componentes visuales reutilizables y agnósticos al dominio** de la aplicación Agricultural Marketplace.

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
