# Directiva de Control de Versiones con Git

El uso de Git es estricto y obligatorio durante todo el ciclo de desarrollo. El objetivo es construir un historial granular, organizado y reproducible que permita auditar cambios paso a paso y realizar rollbacks quirúrgicos.

## Reglas de ejecución

1. **Alta granularidad y frecuencia**: Segmentar la implementación en sus componentes lógicos mínimos. No agrupar múltiples responsabilidades en un solo commit; el número de commits debe ser sustancial, reflejando cada microetapa completada de forma atómica.
2. **Orden lógico y progresivo**: Crear commits siguiendo el flujo natural de construcción: configuración/modelos base -> lógica/servicios -> componentes UI/consumo -> ajustes o validaciones.
3. **Formato de mensaje**: Mensajes en español, en infinitivo, claros y concisos, describiendo la acción exacta realizada. Ejemplo: `git commit -m "definir los colores globales del sistema de diseño"`.
4. **Acción restringida**: Generar exclusivamente comandos `git add` y `git commit`. Nunca ejecutar `git push`; esa acción está reservada al desarrollador.
