# Cambios aplicados tras la auditoría

2026-09-06. Complementa `REPORT.md`, que conserva la fotografía anterior. Implementación autorizada; se mantiene la preferencia **Luna/max para el principal**.

## Configuración final

| Rol | Modelo | Thinking | Herramientas |
|---|---|---|---|
| Principal | Luna, sin cambiar su configuración | max | Herramientas habituales |
| scout | Luna | low | read, grep, find, ls |
| researcher | Luna | medium | codex-research, web_fetch |
| planner | Luna | high | read, grep, find, ls |
| worker | Luna | medium | read, write, edit, grep, find, ls, safe_bash, ast_grep, web_fetch |

`subagent(..., thinking: "high")` permite elevar una invocación difícil sin cambiar defaults. También admite low/medium/max. Se comprueba soporte real del modelo antes de arrancar. No se configura un proveedor alternativo que actualmente falla ni un fallback silencioso con posible gasto adicional.

Scout y planner siguen siendo de lectura: no reciben shell ni AST con capacidad de escritura. Researcher puede **buscar de verdad**, no solo descargar URLs. Search usa las credenciales Codex de su paquete y es independiente del modelo del investigador. Worker tiene herramientas para ejecutar pruebas, localizar código, transformar AST y consultar documentación. No inyecto LSP/MCP indiscriminadamente: no todos los proyectos tienen servidor y el MCP actual no tiene servidores activos.

## Fallos corregidos

### Protocolo, ejecución y contabilidad

- Errores propagados mediante el hook soportado por Pi 0.85.1; conserva evidencia parcial y el mensaje de error.
- Distingue ejecución completa, parcial, fallida, cancelada y expirada. Texto intermedio, respuestas vacías, commentary, length y deferred no se presentan como final válido.
- El estado de ejecución no certifica aceptación: un proceso puede completar y devolver una tarea bloqueada.
- Usage superior para que Pi contabilice al hijo, más usage reportado por tools y compactación. No se suman árboles de details dos veces.
- Modelo solicitado/efectivo, thinking validado, tiempo de cola y tiempo total en details.
- Selección explícita de modelo. Nombres de agentes, tools ausentes y combinaciones modelo/thinking inválidas fallan antes de iniciar trabajo.
- Concurrencia predeterminada **2**, FIFO con reserva de plaza y cancelación incluso entre concesión y reanudación.
- Deadline predeterminado **10 minutos incluyendo cola**. TERM/KILL al grupo, sin confundir `proc.killed` con terminación ni perder descendientes cuando el padre sale antes.
- Espera de limpieza acotada; temporales y timers de progreso se limpian. Los tests esperan que los handlers de señales estén instalados antes de cancelar.
- Sin delegación anidada. Coordinación y propiedad de archivos permanecen en el principal; no se añade un sistema distribuido de locks.
- Output por defecto **16 KiB / 200 líneas**, truncado Unicode correcto y artifact recuperable; buffers de protocolo/stderr/previews acotados.

### Contexto y workflow

- Prompt base de hijos compacto. Sustituye solo el default genérico de Pi; respeta un SYSTEM.md explícito y sigue cargando contexto AGENTS/CLAUDE.
- Contratos con objetivo, hechos/evidencia conocidos, restricciones, aceptación, checks y parada. El principal debe transmitir invariantes y skills pertinentes: no se copia la conversación.
- Eliminadas obligaciones de delegación por número de archivos, modelos/Haiku/forked desactualizados, delegación recursiva y listas de planes equivalentes.
- Presupuestos blandos en los roles; high/max no son requisito para localizar un archivo.
- TASKS ya no se inyecta completo: referencia canónica y sección In Progress acotada. Inbox/Done quedan bajo demanda.
- Validación de slugs de planes, creación de directorios cuando hace falta y resultados compatibles con el contrato de tipos actual.
- `git status` y `git log` independientes se ejecutan en paralelo.
- Guidelines para no repetir LSP cuando falla su inicialización. No se ha instalado TypeScript en cada proyecto ni modificado el paquete LSP externo.
- Versiones de los cuatro paquetes activos fijadas a las ya instaladas/evaluadas. No cambia Luna/max ni la selección de modelos del usuario.

### Recuperación web

- Límite sobre el stream real, no solo Content-Length: 5 MiB o 20 MiB para PDF.
- Abort cancela lecturas pendientes; timeout devuelve control aunque una operación asíncrona no coopere.
- Ventanas por caracteres Unicode/líneas con avance garantizado; offset, limit, refresh y artifact.
- Artifacts inmutables, asociados a URL e instancia, creados perezosamente en directorio privado. Refresh no devuelve el artifact anterior.
- Caché de sesión pequeña con TTL, respetando headers, cookies, redirects y exclusiones de URLs sensibles/privadas.
- Jina solo recibe URLs que pasan un filtro conservador de URLs públicas; sus respuestas no se cachean por URL.
- Readability actualizado de 0.5 a **0.6.0** para corregir un DoS por regex confirmado por advisory [2]. Añadidos tipos de Turndown para comprobación estricta.

## Evaluación de modelos: qué demuestra la prueba

`benchmark.mjs` ejecutó **10 completions reales**, de un máximo autorizado de 12:

- Tres tareas sintéticas por Luna/low, Luna/medium y Luna/max.
- Un intento Flash/low; respondió HTTP 401 / saldo insuficiente. Se detuvo ese perfil sin reintentar ni activar facturación.
- Sin ejecución de código generado ni llamadas de herramientas reales dentro del benchmark: una tarea comprueba la selección/argumentos de un tool; otras revisan concurrencia y extraen hechos de fuentes sintéticas.
- Una completion por tarea/perfil, orden rotado, sin retries, timeout y output máximos explícitos. No hay repeticiones estadísticas ni tareas autónomas de edición.

| Perfil | Mediana por completion | Tiempo sumado, tres tareas | Output reportado acumulado |
|---|---:|---:|---:|
| Luna low | 4,76 s | 11,86 s | 146 tokens |
| Luna medium | 4,19 s | 13,46 s | 252 tokens |
| Luna max | 5,65 s | 18,98 s | 752 tokens |
| Flash low | No evaluable | Error de acceso en 0,46 s | No evaluable |

Los tres perfiles Luna acertaron las dos tareas sin ambigüedad. En la revisión, todos seleccionaron la corrección correcta B; un booleano del enunciado no especificaba si describía el algoritmo original o el corregido. **Se conserva el fallo del grader original y se excluye ese booleano de conclusiones de calidad**, en lugar de declarar una regresión o corregir las notas a conveniencia. Véanse `benchmark-results.json` y su `gradingNote`.

No se demuestra equivalencia de calidad en bugs difíciles, ni que low sea siempre más rápido que medium. Tampoco que Flash sea superior: no hubo respuesta válida. El resultado sí apoya probar menos esfuerzo en trabajo acotado antes de comprar otra suscripción. El coste de un scout con decenas de turnos puede dominar ampliamente estos segundos por completion.

La selección por rol es una **decisión conservadora que hay que validar con uso real**, no un óptimo estadísticamente probado. Planner conserva high por el tipo de decisiones; worker/researcher medium equilibran ejecución/síntesis. En auth, datos o concurrencia difícil, elevar worker a high desde el inicio es preferible a hacerle fallar deliberadamente en low.

## Opinión sobre OpenCode Go y Flash

La documentación actual anuncia Go a **$10/mes**, pero distingue límites base y asignación efectiva por modelo: Flash tiene **$30** de uso mensual y Pro **$15**; no asumir $60 universales. Incluye Flash, Pro y Kimi K2.6, entre otros. Exige identificación y header de sesión para otros agentes; los recuentos de peticiones publicados son estimaciones, no garantías [1].

**Mi recomendación:** Flash merece una prueba como scout/low y, después, worker/low en slices verificables, dada tu preferencia. No contrataría Go esperando una mejora sustancial ya demostrada: el acceso actual está bloqueado y no pude medirlo. Si delegas mucho, un mes de evaluación puede tener sentido; para resolver el exceso de reasoning no es necesario pagar antes de probar estos cambios. No adoptaría Pro/Kimi por defecto sin una ventaja medida que compense más complejidad de routing.

No he renovado la suscripción, cambiado saldos, activado overflow ni añadido un fallback de pago. La reactivación requiere una acción de cuenta del usuario. Tras ella, cambiar solo scout a `opencode-go/deepseek-v4-flash` / low y repetir tareas pareadas; no migrar todos los roles a la vez.

## Verificación y alcance

- **22 tests deterministas pasan**: 12 subagents, 9 web-fetch y una integración con múltiples aserciones sobre el SDK/herramientas reales.
- Pruebas de carrera FIFO/abort, cancelación con descendientes ignorando TERM, truncado, JSONL grande, recuperación después de error, usage y respuestas no finales.
- Integración sin proveedores ni red externa: carga de extensiones, allowlists, modelo/thinking, hook de error, partial/cancelled, tools inválidas, web HTML/texto/cache/artifacts y TASKS acotado.
- Type-check estricto de los archivos de lógica modificados contra el SDK instalado; `git diff --check` limpio.
- `npm audit` en web-fetch: **0 vulnerabilidades reportadas** tras actualizar Readability.
- Los archivos activos y los del repositorio comparten los cambios; el principal necesita `/reload` o una sesión nueva para cargar su nueva extensión/prompt. No se ha interrumpido la sesión actual.
- Cambios ajenos preexistentes de Neovim, cachés/modelos y las preferencias previas de settings no se han revertido.
- Sin CHANGELOG.md raíz: no se creó uno artificial. El informe anterior sigue siendo evidencia histórica, no documentación de la configuración final.

### Límites deliberados

No se implantó router LLM, pool persistente, memoria vectorial, sandbox, caché semántica entre proyectos, votación de agentes ni un gran benchmark autónomo. La cuenta Go impide completar su comparación. La política de LSP evita rituales/reintentos, pero no repara un servidor TypeScript ausente en un proyecto concreto. No se parchean paquetes npm externos a mano.

Los procesos comparten filesystem/entorno. La cancelación de grupo no alcanza procesos que se separen deliberadamente. Los timers JS no interrumpen parsers síncronos CPU-bound. Los artifacts permanecen en temporales hasta limpieza del sistema/usuario. Estos límites están documentados; no se presenta la solución como aislamiento de seguridad completo.

## Reproducir pruebas

Desde la raíz:

```sh
node --experimental-strip-types --test \
  pi/.pi/agent/extensions/pi-subagents/helpers.test.ts \
  pi/.pi/agent/extensions/web-fetch/helpers.test.ts

PI_SDK_ROOT=/absolute/path/to/pi-coding-agent \
  node --test pi/.pi/agent/extensions/pi-subagents/integration.test.mjs

(cd pi/.pi/agent/extensions/web-fetch && npm audit --audit-level=low)
```

El benchmark consume cuota y requiere `--run` explícito. No reejecutarlo automáticamente como parte de tests. Su selección de tareas es una prueba de humo, no el dataset A/B amplio propuesto en la auditoría.

## Fuentes

[1] https://opencode.ai/docs/go/ — consultado 2026-09-06, especialmente límites efectivos, cuotas y uso desde otros agentes.

[2] https://github.com/advisories/GHSA-3p6v-hrg8-8qj7 — Readability <0.6.0 afectado; 0.6.0 corregido.
