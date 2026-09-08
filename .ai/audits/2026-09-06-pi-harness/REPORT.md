# Auditoría técnica del harness Pi

Fecha: 2026-09-06 · Pi instalado: **0.85.1** · Estado: auditoría, sin cambios de configuración.

## 1. Resumen ejecutivo

**La mejora principal no es sustituir modelos: es eliminar delegaciones obligatorias, controlar el trabajo que hace cada hijo y corregir la comunicación de errores y consumo.** La arquitectura existente permite hacerlo sin reemplazar el plugin.

La base es buena: procesos nuevos, sin copia de la conversación, skills desactivadas en hijos, herramientas seleccionadas explícitamente, agentes de lectura separados de escritura y paralelismo nativo. No encontré un mecanismo que envíe todo el historial a cada subagente. Tampoco hace falta añadir un router LLM, más tipos de agente ni memoria vectorial.

Los principales problemas son:

1. **Errores mal señalizados.** El plugin retorna `isError`, pero el host no lo utiliza como indicador de fallo de `execute()`. Puede devolver texto parcial aparentemente normal después de fallar.
2. **Consumo fuera de los totales.** Se registra en `details.results[].usage`, no en el `usage` superior que contabiliza Pi. Los descendientes y la compactación tampoco quedan correctamente agregados por el parser actual.
3. **Delegación demasiado incentivada.** “Más de un archivo”, “tarea no trivial” y “proteger contexto” se convierten en motivos suficientes, aunque el principal ya tenga la información.
4. **Reasoning estático elevado.** Principal por defecto `max`; scout, researcher y worker `high`; planner `xhigh`. No hay routing por tarea ni escalation explícita.
5. **Researcher sin buscador.** Solo dispone de `web_fetch(url)`, pero sus instrucciones exigen búsquedas y múltiples ángulos.
6. **Presupuestos ausentes.** No hay límite de turnos, llamadas, tiempo total o contexto por invocación. Un scout puede convertirse en una investigación de varios minutos.
7. **Salida y documentación redundantes.** Planes muy largos; lectura global de documentación Pi inducida por el prompt base; contratos que no distinguen evidencia nueva de inventarios ya conocidos.

**Recomendación inmediata:** conservar Luna; empezar bajando esfuerzo a `low`/`medium` en tareas acotadas, con `high` explícito para trabajo difícil. Medir antes de sustituirlo por Flash. El catálogo local ni siquiera permite concluir que Flash sea universalmente más barato en todas las dimensiones.

### Evidencia y límites

Se inspeccionaron configuración activa y versionada, las cuatro definiciones de agentes, el plugin completo, safe-bash, plugins locales, prompts/skills de workflow, los cuatro paquetes activos y partes relevantes del runtime instalado. Las copias activas comparadas coinciden con las del repositorio. No se modificaron los cambios preexistentes de settings/modelos ni de Neovim.

Se realizaron:

- Tres investigaciones acotadas con scout, contrastadas posteriormente contra código y SDK.
- Un probe local de `DefaultResourceLoader`, sin llamadas LLM, para verificar carga de recursos.
- Extracción de metadatos de los **60 archivos de sesión modificados más recientemente**, excluyendo esta auditoría: **360 resultados persistidos de subagentes**, fechados entre 2026-07-30 y 2026-09-06.
- Consulta del estado MCP: **0 servidores / 0 herramientas de servidor**.
- Contraste de semántica de herramientas con documentación oficial y código instalado.

La muestra histórica mezcla configuraciones, proyectos, errores de cuota y posibles ramas copiadas. **No es un benchmark, no acredita corrección de tareas y no permite atribuir diferencias a un modelo.** No se ejecutaron A/B, pruebas destructivas ni una auditoría completa de todos los servidores/proveedores externos. Las referencias de skills de dominio que no intervienen en el harness no se cargaron exhaustivamente.

Los JSON adjuntos contienen métricas, no conversaciones ni credenciales:

- `subagent-sample.json`
- `audit-run-metrics.json`

## 2. Flujo actual del harness

```text
settings globales + posibles overrides del proyecto + sesión/CLI
    │
    ├─ selección de modelo y thinking
    ├─ descubrimiento de extensiones, prompts y skills
    └─ prompt base Pi + tool guidelines + APPEND_SYSTEM + contexto proyecto
          + catálogo de skills, no sus cuerpos completos
                  │
                  ▼
         before_agent_start
          ├─ memory: workflow + TASKS.md completo
          └─ Plannotator: framing/checklist si hay fase activa
                  │
                  ▼
             agente principal
          ├─ tools locales / LSP / web / MCP
          └─ subagent(agent, task, cwd?) — decide el propio modelo
                  │
          lookup de agente + semáforo local, máximo 4
                  │
          proceso Pi nuevo: JSON, print, no-session, no-skills
          no-extensions + extensiones explícitas + allowlist de tools
          --models <modelo del agente> --thinking <nivel>
          --append-system-prompt <rol> + Task: <encargo>
                  │
          historial propio de herramientas y respuestas
          ├─ scout/researcher: hojas
          └─ planner/worker: pueden llamar scout/researcher
                  │
          parser de eventos y captura del último texto no vacío
                  │
          content: respuesta al principal
          details: UI, log de herramientas, métricas, descendientes
                  │
          principal verifica lo necesario, integra y responde
```

**Inventario activo:** ocho extensiones locales: `pi-subagents`, `memory`, `context-warning`, `ast-grep`, `web-fetch`, `ask-user-question`, `caffeine`, `herdr-agent-state`; y cuatro paquetes:

| Paquete | Versión instalada | Papel |
|---|---:|---|
| `pi-mcp-adapter` | 2.32.1 | Gateway MCP y scripting; sin servidores en esta sesión |
| `pi-lsp-bridge` | 2.3.0 | Herramientas semánticas e instrucciones globales de uso |
| `pi-gpt-search` | 1.1.0 | `codex-research`, `codex-search`, alias `web` |
| `@plannotator/pi-extension` | 0.27.12 | Revisión/planificación con fases y continuación automática |

`pi-web-access` está instalado, pero no figura entre los paquetes activados. `memory-keeper` aparece en sesiones históricas, **no en las cuatro definiciones actuales**. No deben contarse como agentes/plugins activos por el mero hecho de existir en disco o en logs.

`architect`, `dev` y `ops` son **skills**, no procesos ni llamadas de modelo adicionales por sí mismas.

## 3. Análisis del plugin de subagentes

Referencia principal: `pi/.pi/agent/extensions/pi-subagents/index.ts`.

### 3.1 Decisión de delegación

El plugin no clasifica tareas ni decide cuándo delegar. Registra una herramienta; el principal decide llamarla siguiendo instrucciones globales, skills, templates y la descripción del tool (`:936–968`).

El schema solo acepta `agent`, `task`, `cwd`. No contiene presupuestos, política de validación, contexto conocido, campos de salida, ni override de modelo/thinking. Tampoco expone un catálogo compacto de agentes: `agent` es texto libre y la lista disponible aparece principalmente en el error de nombre desconocido. La descripción de cada `AgentConfig` no se convierte en una interfaz de descubrimiento suficientemente explícita.

**Mejor:** mantener esos tres parámetros y añadir, como mucho, un perfil de esfuerzo y un contrato dentro de `task`. No empezar por diez knobs. Exponer nombres y funciones reales en unas pocas líneas, incluido planner si se conserva.

### 3.2 Contexto real recibido

`buildPiArgs()` (`:339–435`) no usa la conversación del principal, ni `--fork`, `--continue` o `--session`. Un archivo temporal para tareas de más de 8.000 caracteres evita problemas de argv, **no comprime el encargo**: `@task.md` sigue incorporándolo completo.

Los hijos reciben:

- Prompt base de Pi, salvo que exista un `SYSTEM.md` que lo sustituya.
- Prompt del rol mediante `--append-system-prompt`.
- El encargo completo.
- Descripciones de las herramientas permitidas y sus guidelines.
- Archivos `AGENTS.md`/`CLAUDE.md` descubiertos desde su cwd: falta `--no-context-files`.
- Configuración global/proyecto aplicable y entorno de proceso heredado.

**No reciben automáticamente:** historial del principal, sus resultados previos, cuerpos de skills, workflow inyectado por `memory`, ni el `APPEND_SYSTEM.md` global. Este último detalle se verificó en `resource-loader.js:386–397`: un append explícito sustituye el descubrimiento del append global. El probe lo confirmó.

En este cwd no se descubrió ningún archivo de contexto de proyecto. En otros repositorios puede ser distinto.

El aislamiento conversacional es correcto; el aislamiento de filesystem y credenciales **no existe**. Todos operan sobre el mismo árbol. Un cwd diferente no es un sandbox.

### 3.3 Contexto que falta y contexto innecesario

El problema no es solo exceso: worker no hereda automáticamente las reglas globales de validación, changelog, protección de cambios existentes o decisiones del usuario. `--no-skills` también evita el catálogo que permitiría descubrir skills de dominio. Debe recibir explícitamente esas invariantes pertinentes.

Sobran, según tarea:

- Explicaciones generales sobre delegar que ocupan buena parte de worker.
- Instrucciones de Pi/TUI en tareas que solo requieren localizar un símbolo.
- Inventarios que ya dio otro agente.
- Hipótesis descartadas no relacionadas con el encargo.
- Planes completos cuando solo se ejecuta una sección.

No recomendaría añadir `--no-context-files` indiscriminadamente: ahorra ruido, pero también elimina reglas importantes. Primero medir qué archivos carga cada perfil y conservar sus invariantes, sin resumir selectivamente hasta perder restricciones.

### 3.4 Integración de resultados

En cada `message_end`, el parser guarda el último bloque de texto no vacío (`:604–655`). No comprueba que sea una respuesta final válida. Si el hijo termina sin una respuesta final, puede conservar una explicación intermedia. Si hubo error y ya existía texto, `result.output || Error...` conserva ese texto (`:695–700`).

El principal recibe solo `content`, no todo el log de ejecución. `details` guarda tareas, salida, métricas y árbol de progreso para UI/persistencia. La serialización Responses utiliza `msg.content`, no `details` (`openai-responses-shared.js:210–225`).

Por tanto:

- **No hay doble consumo LLM por guardar output en content y details.**
- Sí hay duplicación en disco/memoria/eventos y renderizado.
- Los resultados no tienen contrato verificable de `complete/partial/blocked`.
- No hay verificación automática de evidencia o de aceptación; la realiza el principal.

### 3.5 Errores: defecto prioritario

El retorno actual incluye `...(isError ? { isError: true } : {})` (`:1022–1027`). En Pi 0.85.1 el ejecutor marca una devolución normal como éxito; hay que lanzar una excepción o modificar el estado en el hook de resultado. La documentación oficial confirma la distinción [1].

En la muestra: **120 resultados con exitCode no cero o error interno aparecen exteriormente con `isError: false`**. Esto no significa que todos los usuarios vieran un éxito falso: algunos outputs contienen el error en texto. Sí demuestra que la señal estructural no es fiable.

Recomendación: `status` explícito en content y details; hook `tool_result` para propagar fallo manteniendo evidencia parcial y usage. Para errores de validación antes de arrancar, excepción normal. No solucionar el problema tirando a la basura métricas y resultados parciales de procesos fallidos.

### 3.6 Métricas incompletas

Se suman assistant usage y turnos del hijo (`:604–637`), pero no se devuelve `usage` superior. **Los 360 resultados de la muestra carecen de él.** La UI del plugin y el footer general pueden mostrar contabilidades distintas.

Además:

- No se suman explícitamente llamadas de nietos a los totales del hijo.
- No se contabilizan eventos de compactación/resumen del proceso hijo.
- `durationMs` empieza después de la cola y de preparar argumentos: no mide toda la latencia del tool.
- No se persiste thinking efectivo ni una identidad provider/model inequívoca después de `message.model`.
- El coste actual es un escalar, no el objeto completo `Usage.cost` esperado por el host.

Instrumentar una vez en la frontera de cada invocación: tiempos de cola/arranque/ejecución, usage por categoría, modelo/nivel efectivos, motivo de terminación y parentId. Agregar cada llamada exactamente una vez.

### 3.7 Paralelismo, profundidad y escrituras

El semáforo (`:750–766`) limita a cuatro hijos **por proceso**. Las definiciones actuales permiten profundidad de dos saltos: principal → planner/worker → scout/researcher. No hay recursión infinita en ese grafo actual.

Sin embargo, cuatro workers pueden tener cada uno cuatro scouts simultáneos: hasta 4 hijos + 16 nietos, sin contar el principal. Tampoco hay un límite al número total de invocaciones sucesivas durante una tarea.

No hay detección de investigaciones solapadas ni coordinación de escritura entre procesos. Las colas de mutación en memoria no equivalen a locks entre procesos.

Recomendación: normalmente cero o un hijo; hasta dos investigaciones independientes. Centralizar inicialmente la delegación en el principal y retirar `subagent` de worker/planner simplifica más que construir un semáforo distribuido. Hacerlo después de asegurar que los briefs contienen el mapa ya conocido.

### 3.8 Cancelación y límites

`proc.killed` significa que se envió una señal, no que el proceso haya terminado. La condición del fallback SIGKILL (`:680–686`) es incorrecta. Se señala al proceso directo, no al árbol. La espera de semáforo tampoco es cancelable.

No hay deadline total ni límite de turnos/herramientas. `recentTools`, stderr y una línea JSON incompleta pueden crecer sin límite. `maxConcurrency` no se valida: cero/negativos pueden bloquear.

La salida se recorta solo al superar `DEFAULT_MAX_BYTES` medido con `string.length`, no bytes reales (`:702–710`). Una salida con muchas líneas o Unicode puede eludir el guard inicial. El truncado conserva el principio y descarta el resto sin archivo recuperable.

Arreglar cancelación, validar concurrencia y truncar siempre por bytes/líneas es más valioso que sustituir subprocesses por un sistema más complejo.

## 4. Análisis de cada subagente

| Agente | Configuración actual | Evaluación | Recomendación |
|---|---|---|---|
| scout | Luna/high; read, grep, find, ls | Buen rol read-only. Demasiado incentivo a mapa/arquitectura/snippets incluso para consultas puntuales. Sin budgets ni LSP/AST. | Conservar. Luna/low para localización, medium para trazado. Responder solo a la pregunta, con evidencia. Flash/low como experimento, no migración automática. |
| researcher | Luna/high; solo web_fetch | Contrato de búsqueda imposible de satisfacer de forma directa. Demasiadas facetas/páginas por defecto; lista de fuentes descartadas innecesaria. | Hasta corregir tools, usarlo para síntesis de URLs conocidas. Añadir búsqueda real cuando la tarea la requiera. Luna/low para extracción; medium para síntesis. |
| planner | Luna/xhigh; lectura + subagent | Responsabilidad razonable para planes amplios, pero duplica al principal y architect. Devuelve Tasks, Files to Modify, New Files, resumen: varias representaciones del mismo plan. | Opcional, no paso universal. Medium para plan acotado, high para arquitectura. Un solo checklist con archivos/aceptación embebidos. |
| worker | Luna/high; read/write/edit/safe_bash/web_fetch/subagent | Demasiado general: implementa, investiga y coordina. Su propio prompt recomienda scouts “Cheap (haiku)”, falso actualmente. | Conservar como ejecutor de slice. Medium de base; low en cambios mecánicos validados; high para lógica difícil. Sin delegación anidada inicialmente. |

Fuentes: `pi/.pi/agent/extensions/pi-subagents/agents/*.md`.

**No añadiría más tipos.** Tres roles habituales —scout, researcher, worker— y planner como modo opcional son suficientes. Un reviewer independiente puede ser una tarea read-only con contrato específico, no necesariamente un quinto agente permanente.

### Qué debería recibir siempre

Objetivo; límites; criterios de aceptación; hechos/decisiones ya establecidos; evidencia relevante; cwd; permisos de escritura; estado sucio que debe preservar; validación; condición de parada; formato de salida. Pasar la instrucción original literal solo cuando su redacción sea contractual, no toda la conversación.

### Solo bajo demanda

Fuente completa, documentación larga, historia de decisiones, planes ajenos al slice, logs completos, herramientas externas y skills de dominio. Researcher puede recibir URLs y extractos sin código del repositorio. Worker sí necesita rutas exactas, invariantes y comandos de prueba.

### Delegar o no

**Directo:** lectura de un archivo, búsqueda literal, extracción JSON, comparar hashes, ejecutar un test, edición obvia, aclaración conceptual y diagnóstico que depende de correcciones recientes del usuario.

**Delegable:** exploración ruidosa cuyo producto útil es pequeño; síntesis de varias fuentes aún no leídas; implementación independiente con contrato; revisión read-only de riesgo elevado. Si el principal ya hizo la investigación, no mandar otro agente a descubrirla otra vez.

No usar “cinco archivos” como criterio suficiente: cinco archivos pequeños pueden costar menos que un handoff; un único archivo enorme puede justificar aislamiento.

## 5. Análisis de model routing

### Estado real

- `settings.json:2–5`: `openai-codex/gpt-5.6-luna`, thinking `max`.
- Variables de esta sesión: `openai-codex/gpt-6-astra`, thinking `medium`.
- Los cuatro agentes: `openai-codex/gpt-5.6-luna`.
- `enabledModels`: Flash, Luna, Astra. Es una lista de selección/cycling, **no un router**.
- El README del plugin describe Flash/Kimi/Pro y worker llama Haiku al scout: documentación desactualizada.
- Sin fallback de calidad ni escalation en el plugin. Los retries de Pi tratan fallos transitorios; no son routing cognitivo.

`--models` selecciona correctamente el primer scoped model en una sesión nueva (`model-resolver.js:492–499`). No afirmo que hoy esté lanzando otro modelo. Cambiarlo a `--model` más validación estricta mejora claridad y evita que un scope vacío derive hacia defaults. Registrar el modelo efectivo permite detectar fallbacks.

### Routing mínimo propuesto

| Trabajo | Primera elección concreta | Cuándo escalar | Efecto esperado |
|---|---|---|---|
| Operación determinista | Script/tool local, sin modelo extra | No aplica | Menos latencia y errores de interpretación |
| Recuperación/localización | Principal directo; si hay aislamiento útil, Luna/low | Evidencia contradictoria o trazado no local → medium | Ahorro por esfuerzo/contexto, no necesariamente por tarifa |
| Extracción/síntesis breve | Luna/low | Síntesis con condiciones incompatibles → medium | Calidad similar esperada, pendiente de A/B |
| Implementación contenida | Luna/medium | Repro validado, causa no local → high | Conserva un modelo capaz; evita arranque siempre caro en reasoning |
| Arquitectura/debug difícil/revisión crítica | Principal Luna/high; Astra/medium como alternativa medida | Dificultad demostrada o alto coste de equivocarse | Se acepta coste adicional por fiabilidad |
| Fan-in de resultados | Principal actual, medium si debe resolver contradicciones | High solo por conflicto real | No lanzar otro sintetizador |
| Alternativa económica | Flash/low para scout/edición mecánica | Fallo semántico verificable → Luna/medium | Experimento, no sustitución global |

No hay benchmark local que pruebe que Astra sea superior para esta clase de tareas, ni que Flash cumpla suficiente fiabilidad. “Modelo mínimo” aquí significa **candidato mínimo razonable a validar**, no capacidad demostrada por su nombre.

El catálogo local declara Luna Codex a 0,20 input / 1,20 output / 0,02 cache-read y Flash Go a 0,22 / 0,66 / 0,007 por millón. Son metadatos de cálculo, no facturación comprobada de una suscripción. Astra declara tarifas mucho mayores. Cambiar Luna por Flash puede ahorrar output, pero no es automáticamente mejor en input, latencia, disponibilidad o número de turnos.

### Política de fallback sencilla

1. Error de infraestructura/cuota: no aumentar reasoning. Clasificar y usar solo un proveedor alternativo previamente autorizado o informar del bloqueo.
2. Falta de evidencia: recuperar el fragmento que falta antes de cambiar de modelo.
3. Fallo semántico con test reproducible: una corrección local; si persiste, escalation con repro y delta de evidencia.
4. Alto riesgo conocido desde el inicio: empezar en el perfil robusto, no gastar una llamada débil deliberadamente.
5. No repetir ciegamente todo el trabajo con Astra. Entregar problema, hipótesis descartadas y criterio pendiente.

La clasificación de errores históricos por palabras clave encontró 103 menciones de cuota/rate-limit. Eso desaconseja interpretar las tasas históricas de éxito de proceso como diferencias de inteligencia entre modelos.

### Modelos dentro de herramientas

`pi-gpt-search/src/codex-provider.ts:89–106,168–195` envía `model: "gpt-4o"` al endpoint Codex search. **Es el valor solicitado por el cliente; no prueba el backend efectivo ni un precio por llamada.** Cada acción web es una petición externa adicional; no hereda automáticamente Luna/Astra o su thinking.

MCP adapter puede ejecutar sampling LLM, pero con cero servidores no hay evidencia de sampling activo aquí. Plannotator permite perfiles de modelo/thinking, pero su JSON bundled actual no fija ninguno y no se encontró override local/global en las rutas revisadas: **soporta routing, no lo está ejerciendo con una selección distinta demostrada**.

## 6. Análisis de reasoning effort

No existe relación necesaria “más contexto → más reasoning”. Muchas llamadas largas son repetición de búsqueda/lectura, no decisiones difíciles. Mejorar el contrato reduce ambigüedad antes de aumentar esfuerzo.

| Clase de tarea | Nivel recomendado inicial | Escalation razonable |
|---|---|---|
| Lectura, grep, hash, tests, parseo determinista | Ninguna llamada LLM adicional | No aplica |
| Clasificación/extracción sencilla | off/minimal si el modelo lo soporta; Luna low como opción uniforme | Medium ante ambigüedad relevante |
| Localizar archivos/símbolos | Low | Medium para flujo transversal |
| Edición mecánica | Low, con verificación determinista | Medium si afecta semántica |
| Implementación pequeña | Medium; low si patrón y aceptación son inequívocos | High tras dificultad concreta |
| Implementación compleja | Medium o high según riesgo | High; modelo alternativo solo con motivo |
| Debugging local reproducible | Medium | High si concurrencia, invariantes o causa no local |
| Debugging crítico, seguridad/datos | High | Xhigh solo si el A/B demuestra beneficio |
| Revisión de código acotada | Medium | High para auth, concurrencia y datos |
| Arquitectura y decisiones irreversibles | High | Xhigh ocasional; max no predeterminado |
| Investigación con URLs conocidas | Low | Medium para reconciliar fuentes |
| Investigación contradictoria | Medium | High para evaluación metodológica compleja |
| Plan derivado de contrato cerrado | Medium | High para dependencias/riesgos difíciles |
| Síntesis de agentes | Low si unión literal; medium si hay juicio | High por contradicciones, no por número de agentes |

Los niveles no son comparables entre proveedores. El catálogo local mapea `minimal` a `low` para Luna/Astra; Astra no admite `off`. Flash Go admite `low/high/max`, pero no `medium`; Pro no admite low/medium según ese catálogo. No configurar un nivel no soportado y asumir que se ejecutó: registrar el nivel efectivo tras el clamping.

Cambiaría primero defaults por tarea, manteniendo una salida explícita hacia high. El riesgo de bajar esfuerzo indiscriminadamente en seguridad supera el ahorro. No implementaría un clasificador LLM de reasoning: el principal puede elegir entre dos o tres perfiles con la información que ya tiene.

## 7. Análisis de gestión de contexto

### Qué está bien

- Skills mediante progressive disclosure: catálogo permanente, cuerpos bajo demanda.
- Conversaciones de hijos nuevas; no forks.
- `get_current_plan` y `summarize_worktree` devuelven previews acotados.
- El gauge del subagente utiliza usage de la última respuesta, no suma todos los turnos como si fueran ocupación simultánea.
- Plannotator mantiene framing en conversación en vez de reescribir continuamente el system prompt; en idle fresco no inyecta framing.

### Qué cambiar

**TASKS completo en el system prompt.** `memory.ts:281–317` concatena todas las tareas, incluidas Done. Se reconstruye por prompt del usuario, no una copia nueva por cada tool call. Aunque no sea acumulación infinita, mutar TASKS cambia el prefijo y puede reducir reutilización de caché. Hoy el archivo es pequeño; su impacto actual es bajo, su crecimiento no tiene límite.

Mantener solo ruta del plan, tarea activa y restricciones indispensables. Inbox/Done bajo demanda. No sustituirlo por un resumen LLM generado cada turno.

**Instrucciones superpuestas.** Eliminar duplicidad literal de Editing Discipline en dev. Consolidar reglas de reintento y delegación. Aclarar que el límite de escritura de ops afecta a memoria operativa, no prohíbe todas las ediciones del proyecto. `ops` recomienda worker “forked”, pero el plugin no tiene fork: actualizar documentación.

**Documentación Pi obligatoria completa.** El prompt base (`dist/core/system-prompt.js:99–112`) exige leer archivos `.md` completos y seguir referencias. En auditorías Pi esto provoca lectura repetida de manuales muy grandes entre principal e hijos. Es una fuente real de amplificación, distinta de copiar el prompt global.

Propuesta P1: perfiles de hijos con un prompt explícito mínimo, preservando instrucciones esenciales de tools y reglas del proyecto. Para documentación técnica, comprobar versión y contrato relevante; cargar secciones/ejemplos relacionados, no un recorrido transitivo sin presupuesto. Cambiar esta política requiere una personalización deliberada del prompt base, no un bullet contradictorio añadido al final.

**lean-ctx no activo demostrado.** Existe `pi/.pi/rules/lean-ctx.md` y su copia global, pero el loader inspeccionado no carga ese directorio; no se encontró extensión activa que lo haga y el probe no lo incluyó. `ctx_overview/ctx_compress` tampoco están disponibles. No atribuirle ahorros ni conflictos efectivos actuales. No activarlo: exige tools inexistentes y ≤200 tokens/solo código, incompatible con numerosos trabajos.

### Presupuesto objetivo por capa

Valores iniciales orientativos en tokens; no límites universales ni estimaciones del tokenizer real.

| Capa | Contenido | Presupuesto orientativo |
|---|---|---:|
| Permanente propio | Seguridad, delegación, verificación, estilo | 500–1.000, más base/tools inevitables |
| Proyecto | Reglas pertinentes, comandos y referencias canónicas | 500–2.000; excepciones explícitas |
| Tarea | Objetivo, aceptación, límites, hechos y estado | 300–1.500; más en tareas complejas |
| Recuperado | Fragmentos de código, docs y logs útiles | 2–8k por recuperación; ampliable bajo demanda |
| Encargo de hijo | Contrato compacto + evidencia seleccionada | 300–1.000 normalmente |
| Respuesta scout/researcher | Hallazgos y evidencia nueva | 300–800 normalmente |
| Respuesta worker | Cambios, validación, bloqueo | 200–500 normalmente |
| Plan delegado | Un checklist ejecutable | 800–1.500; no obligar a truncar un plan válido |

Un probe sin extensiones de paquetes ni schemas produjo 12.194 caracteres de prompt para recursos del principal; 2.631 scout; 3.366 researcher; 4.342 planner; 5.098 worker. **Son bases parciales, no el payload real.** Confirman aislamiento y peso relativo de roles, no el coste total. Con `/4`, aproximadamente 3k y 0,7–1,3k tokens respectivamente, con error de estimación.

No fijaría el trabajo al 65% de una ventana enorme. La alerta actual al 65% es una protección, no una estrategia de contexto económico. Pi compacta por defecto cerca del límite (`contextWindow − 16.384`), conserva 20k recientes y utiliza una llamada de resumen. No lo cambiaría primero: reducir entradas y cerrar tareas suele ser mejor que compactar más a menudo.

Un objetivo experimental: scout 8–24k de contexto útil; worker 16–48k; investigación compleja con excepción explícita. Soft budgets y recuperación selectiva primero; no cortar pruebas o evidencia de seguridad para cumplir una cifra.

## 8. Análisis de tools y llamadas

### LSP

Tiene valor real para referencias/tipos, pero sus guidelines globales fuerzan hover/symbols incluso cuando el servidor no funciona. En esta auditoría ambos fallaron por ausencia de TypeScript en el workspace. No conviene instalar TypeScript en dotfiles solo para satisfacer una regla del harness.

Recomendación: comprobar disponibilidad una vez por workspace y desactivar recomendaciones/intentonas tras un error de inicialización. Usar LSP para consultas semánticas; `read` para texto literal; grep/fd para localización. No encadenar workspace_symbol → definition → hover si el primer resultado ya resuelve la pregunta. El scout no tiene LSP; no dárselo universalmente hasta medirlo.

### web_fetch

`web-fetch/index.ts:429–466,574–607` valida Content-Length, lee cuerpo completo y devuelve markdown completo. El preview UI de 500 caracteres no acota lo enviado al modelo. No tiene caché de contenido; envía `Cache-Control: no-cache`. Jina también devuelve texto sin un presupuesto de salida útil.

Añadir límite real al stream, resultado por secciones/offset o límite de caracteres, y archivo recuperable. Caché de sesión por URL + opciones y `refresh` explícito; no reutilizar contenido autenticado entre usuarios ni URLs sensibles sin cuidado. Mantener extracción directa como primer camino; el fallback Jina aumenta latencia y comparte la URL con un tercero.

### Búsqueda

Conservar `codex-research` para búsquedas múltiples/open/find en una misma petición y `codex-search` como wrapper corto si se usa. Ocultar el alias deprecado `web` ahorra superficie sin perder capacidad. No reemplazar ambos por tres agentes de investigación.

El cliente search tiene timeout de 15 s y hasta dos retries HTTP para 502/503/504. Son peticiones externas adicionales, aunque no se registren como respuestas del agente principal. Su backend/modelo efectivo y tokens no están observados. Reportar “no disponible”, no cero.

### MCP

La arquitectura gateway + scripting es adecuada para evitar inyectar todos los schemas. **Aquí no hay servidores; no existe evidencia de un catálogo MCP masivo cargado.** No gastar una refactorización en resolver un problema inexistente.

El adaptador ya tiene caché de metadatos y guard de output de 50 KiB/2.000 líneas, con spill a archivo. Mantenerlo. Si se incorporan servidores, exponer tools directos solo cuando compensen el discovery extra; usar mcpScript para varios pasos con lógica, no para una llamada sencilla. Limitar fan-out por operación si surge carga real.

### ast-grep

Útil para transformaciones estructurales. `limit` limita presentación, no siempre trabajo ni volumen capturado por el CLI; inspect puede devolver toda la salida. Aplicar límite uniforme y guardar resto; previews no son budgets de contexto. Mantener dry-run por defecto. No imponer AST para una búsqueda textual obvia.

### Memoria, preguntas y UI

`memory` evita inventarios completos mediante previews, pero puede hacer git status y log en secuencia: agruparlos ofrece ahorro local pequeño. Una política de preguntas debe estar en un único lugar; Plannotator pide agrupar preguntas mientras ask-user-question exige una por llamada. Conservar preguntas solo ante una decisión real, no puertas de aprobación rutinarias.

`caffeine`, `context-warning` y Herdr no añaden llamadas LLM. No son prioridad de ahorro. safe-bash es un filtro regex, **no un sandbox**; no basar decisiones de riesgo en su nombre. No merece ampliar indefinidamente una blacklist de shell.

## 9. Trabajo redundante detectado

| Patrón | Evidencia | Acción |
|---|---|---|
| Principal traduce → planner planifica → principal reexplica | plan.md y architect skill | Delegar solo si el plan requiere investigación separable; persistir el resultado válido con cambios mínimos |
| Planner → scout → planner relee → worker → scout | Permisos y prompts actuales | Una investigación canónica, reutilizada por referencias |
| Leer archivos que el principal ya conoce | Hijo recibe solo task; no registro explícito de known facts | Añadir `known/evidence/do_not_repeat` al encargo |
| Documentación Pi repetida | Prompt base y lecturas de esta auditoría | Compartir evidencia contractual relevante, no volver a recorrer manuales |
| Plan con varias listas equivalentes | planner.md | Una lista de tareas con archivos, dependencia y aceptación |
| Copias repo/activa abiertas una a una | Investigación de configuración | Comparación hash/diff local antes de releer |
| Resumen de resumen sin decisión nueva | Templates de planificación/finalización | Integrar por delta; resumen humano solo al cierre |

En esta auditoría los tres scouts hicieron **303 tool calls y 70 respuestas de modelo**. Sus outputs finales fueron de aproximadamente 6,0–7,4k caracteres cada uno. En conjunto declararon **495.158 input, 6.620.672 cache-read y 48.036 output**. Los tokens output incluyen lo que informa el proveedor, no solo prosa final.

La delegación fue útil para separar investigaciones y localizar defectos; aun así, es demasiado trabajo para considerar un scout “barato” por defecto. El primero empleó 336 s, y los otros dos 278/461 s ejecutándose en paralelo. La demora de los dos últimos la domina el más lento, no su suma.

Hubo archivos releídos entre principal e hijos y cuatro rutas comunes entre dos scouts; esto no demuestra duplicidad inútil en todos los casos. Verificar el contrato del host ante un bug crítico sí justifica una segunda lectura. Debe eliminarse **redescubrimiento**, no verificación esencial.

También hubo errores en conclusiones preliminares de scouts: el scope exacto sí selecciona el modelo en sesión nueva; el grafo actual sí acota profundidad; lean-ctx no debe darse por activo. Esta corrección es evidencia de que ni high ni un formato estructurado sustituyen el contraste de fuentes.

## 10. Cuellos de botella de latencia

Orden probable:

1. **Número de turnos de los hijos y reasoning por turno.** La etiqueta scout no garantiza brevedad.
2. **Cadenas de planificación/exploración.** Un planner que investiga y luego un worker que redescubre añade camino crítico.
3. **Cuota y fallos transitorios.** Dominan muchos errores históricos; aumentar modelo o razonamiento no los arregla.
4. **Fetch de páginas completas y fallbacks.** Varias fuentes no independientes multiplican trabajo.
5. **Fan-in bloqueado por el hijo más lento.** El principal normalmente continúa tras finalizar el lote; no procesa incrementalmente resultados parciales del lote como decisiones separadas.
6. **Cold start de Pi y recursos por invocación.** Existe, pero no está separado en las métricas: no justificaría una migración SDK/pool sin medirlo.
7. **Tools fallidas por configuración, como LSP.** Pequeñas individualmente, evitables cuando se repiten.

No encontré un scheduling interno que obligue a ejecutar todas las llamadas de subagente secuencialmente. El problema de secuencia viene principalmente del workflow elegido. La barrera antes de editar un archivo cuya implementación depende de evidencia aún no disponible es una dependencia real y debe conservarse.

## 11. Principales fuentes de consumo de tokens

1. Historial propio creciente de cada hijo, reenviado en múltiples turnos, aunque buena parte tenga cache hit.
2. Lectura de docs/archivos completos y búsqueda abierta sin stop por suficiencia.
3. Reasoning/output acumulado de high/xhigh/max y de los intentos adicionales.
4. Planes y briefs que representan varias veces la misma información.
5. Guidelines persistentes de tools y catálogo de skills más amplio que la mayoría de tareas.
6. TASKS completo y datos de proyecto no relacionados, especialmente cuando crecen.
7. Respuestas humanas largas a un consumidor que es otro modelo.

**No confundir métricas:** cache-read consume ventana y atención aunque tenga menor coste; input facturable no es todo el contexto; tamaño final del informe no representa todos los tokens generados; ocultar un bloque en la UI no lo quita del payload; guardar en details no significa enviarlo al modelo.

Muestra histórica de procesos sin señal interna de fallo —no de soluciones correctas—:

| Cohorte | n sin fallo / n resultados | Mediana tiempo sin fallo | Mediana caracteres finales sin fallo |
|---|---:|---:|---:|
| scout Luna | 42 / 43 | 326 s | 5.888 |
| scout Flash | 25 / 94 | 262 s | 7.694 |
| worker Luna | 62 / 67 | 157 s | 548 |
| worker Flash | 68 / 78 | 113 s | 2.470 |
| planner Luna | 11 / 20 | 866 s | 20.886 |

No concluir que Flash sea menos fiable: la muestra está contaminada por cuota, fechas/configuraciones y distinta dificultad. Sí justifica investigar el tamaño de planes y el coste de scouts. No resumiría worker más agresivamente de forma universal: algunos ya devuelven muy poco y podrían necesitar **más evidencia de validación**, no menos texto.

## 12. Problemas que afectan a calidad

- Errores sin señal estructural y texto intermedio presentado como resultado.
- Researcher obligado a buscar sin buscador: riesgo de URLs adivinadas, cobertura incompleta y reintentos improductivos.
- Aislamiento sin handoff de invariantes: worker puede incumplir reglas que nunca recibió.
- Brief “canónico” que reemplaza por completo la petición puede perder matices; preservar restricciones exactas importantes.
- Relectura compulsiva y ruido de manuales: distrae de la evidencia pertinente.
- Model/reasoning fallback no observado: las métricas pueden etiquetar una configuración distinta de la efectiva.
- Truncado sin recuperación que puede descartar advertencias, validación o preguntas al final.
- Ausencia de propiedad de archivos entre writers: riesgo de perder cambios.
- Planes demasiado descompuestos: el máximo fijo de cinco archivos puede fragmentar cambios atómicos y añadir coordinación artificial.
- Gates de architect para especificación, plan y tareas: apropiados para alto riesgo, excesivos para un encargo ya inequívoco.
- Versiones de paquetes no fijadas: un benchmark no es reproducible si cambia el harness entre pasadas.

No se encontró suite de tests dentro del plugin de subagentes. Antes de modificar routing, añadir tests deterministas del protocolo y lifecycle es una inversión mejor que una evaluación subjetiva de prompts.

## 13. Tabla de optimizaciones propuestas

Ahorros: bajo/medio/alto son potenciales, **no medidas causales**. “Condicional” indica que solo se materializan cuando se activa ese camino. Dificultad y riesgo se valoran por separado.

| ID | Actual → cambio recomendado y por qué | Impacto probable | Dificultad | Riesgo | Ahorro latencia | Ahorro tokens | Calidad |
|---|---|---|---|---|---|---|---|
| O1 | isError retornado/último texto → estado explícito y señal host correcta | Alto | Baja-media | Bajo | Medio condicional | Medio condicional | Mejora alta |
| O2 | usage solo details → Usage completo agregado, timings y motivo de salida | Alto para medición | Media | Bajo | Nulo directo | Nulo directo | Mejora diagnóstica |
| O3 | Delegar por archivos/no trivial → delegar por beneficio neto y producto acotado | Alto | Baja | Bajo | Alto | Alto | Igual o mejor |
| O4 | high/xhigh/max fijo → low/medium con high explícito | Alto | Baja | Medio | Medio-alto | Medio-alto | Requiere A/B por riesgo |
| O5 | Researcher sin search → URLs conocidas o buscador real + stop por suficiencia | Alto | Baja-media | Bajo | Alto condicional | Medio | Mejora alta |
| O6 | Sin budgets/cancelación robusta → soft budgets, deadline, cola abortable, terminar árbol | Alto | Media | Medio | Alto en colas extremas | Alto en runaway | Mejora con parciales recuperables |
| O7 | Salida narrativa y truncada → contrato compacto y artifact recuperable | Medio-alto | Media | Bajo-medio | Medio | Medio-alto | Mejora si preserva evidencia |
| O8 | Worker/planner delegan → principal único coordinador por defecto | Medio-alto | Baja-media | Medio | Medio-alto | Medio-alto | Igual si brief suficiente |
| O9 | Docs Pi completas/generic prompt → perfiles mínimos y documentación selectiva | Alto en trabajos Pi | Media | Medio | Medio-alto | Alto condicional | Validar invariantes |
| O10 | TASKS completo → tarea activa + referencias; Done bajo demanda | Bajo hoy, mayor al crecer | Baja | Bajo | Bajo | Bajo-medio | Igual o mejor |
| O11 | LSP siempre recomendado → disponibilidad y fallback por workspace; guidelines compactas | Medio | Media | Bajo | Bajo-medio | Bajo-medio | Mejora |
| O12 | web_fetch completo/no-cache → stream/output acotados y caché de sesión | Medio-alto en investigación | Media | Bajo-medio | Medio | Alto condicional | Igual con refresh y recuperación |
| O13 | Readme/Haiku/forked desactualizados y reglas duplicadas → una política coherente | Medio | Baja | Bajo | Bajo-medio | Bajo | Mejora |
| O14 | Scope sin verificación → modelo explícito y registro de thinking/provider efectivos | Medio | Baja | Bajo | Bajo | Bajo | Mejora predictibilidad |
| O15 | Dos workflows de planning → plan canónico único y Plannotator como revisión opcional | Medio-alto | Baja-media | Bajo | Medio | Medio | Igual o mejor |
| O16 | Paquetes flotantes/sin tests → fijar versiones evaluadas y tests del plugin | Medio | Media | Bajo | Nulo directo | Nulo directo | Mejora consistencia |
| O17 | Luna para todo → probar Flash/low en tareas acotadas y Astra solo donde aporte | Incierto | Media | Medio | Por medir | Por medir | Debe pasar no-inferioridad |
| O18 | Cold start → pool/SDK persistente | No demostrado | Alta | Medio-alto | Desconocido | Bajo directo | Riesgo de contaminación |

Estas mejoras se solapan: no sumar ahorros cualitativos ni porcentajes de distintos experimentos.

## 14. Priorización P0/P1/P2/P3

### P0 — Cambiaría inmediatamente

- O1: señalización de errores y resultados parciales.
- O2: métricas completas; sin ellas se optimiza a ciegas.
- O3: eliminar “allways use subagents” y el disparador “más de un archivo”.
- O5: alinear researcher con herramientas disponibles; inicialmente URLs conocidas si no se añade search todavía.
- Parte segura de O6: validar concurrencia, corregir SIGKILL y cancelar cola; no fijar todavía límites agresivos de razonamiento.
- O13/O14: corregir README/Haiku/forked y verificar modelo efectivo.

Bajar todo el reasoning de forma ciega **no** es P0 de bajo riesgo. Sí lo es dejar de describir high/max como requisito universal.

### P1 — Muy recomendable

- O4: Luna low/medium por clase, con high explícito y regresiones.
- O7/O8: contratos compactos, límites recuperables y coordinación central.
- O9: evitar carga transitiva de manuales y generic prompts en hijos.
- O10/O11/O12: contexto dinámico, LSP disponible y fetch limitado.
- O15/O16: una fuente de planificación, versiones fijadas y tests de lifecycle.

### P2 — Experimentaría

- O17: Flash/low frente a Luna/low; Luna/high frente a Astra/medium.
- Uno frente a dos subagentes simultáneos; tres/cuatro solo para cargas realmente independientes.
- Skills globales de dominio frente a activación por proyecto; medir coste de discoverability.
- Budgets absolutos de contexto y compactación en checkpoints naturales.
- Un pequeño manifest de evidencias por tarea con hash/mtime; no un almacén semántico general.

### P3 — No tocaría por ahora

- Pool persistente/SDK solo por presunto coste de spawn.
- Router LLM, heurísticas extensas, bandas de confianza autodeclarada o bandits.
- Un agente por lenguaje/fase/tool; votación entre varios modelos por defecto.
- Memoria vectorial, resumen LLM automático de cada tool output o caché de decisiones entre proyectos.
- Recursión arbitraria con coordinador distribuido y locks complejos.
- Activar lean-ctx o pi-web-access sin una necesidad no cubierta.
- Reescribir UI, caffeine o Herdr para ahorrar tokens: no son la fuente principal.

## 15. Arquitectura objetivo recomendada

**Mismo plugin de subprocesses, contratos mejores y menos política implícita.**

- **Principal:** entiende intención, mantiene decisiones y evidencia canónica, escoge perfil, coordina y acepta resultados. Luna/medium como base candidata; no impide elegir Astra para trabajo que lo justifique.
- **Subagentes:** cero por defecto; uno para aislamiento útil; máximo habitual dos independientes. Scout y researcher read-only; worker con slice explícito; planner opcional.
- **Delegación:** no anidada por defecto. Si un worker detecta que falta investigación sustancial, devuelve `blocked` y la pregunta exacta; no crea otro árbol.
- **Routing:** dos o tres perfiles estáticos; sin llamada extra para clasificarlos. Una escalation semántica y una política separada para fallos de infraestructura.
- **Contexto:** instrucciones estables al inicio; tarea y evidencia en mensajes; fuentes largas mediante referencias. No forks ni conversación completa.
- **Tools:** locales para tareas mecánicas; lookup semántico cuando LSP funciona; recuperación web por preguntas concretas; MCP discovery cuando exista un servidor necesario.
- **Paralelismo:** ramas con evidencia y archivos no solapados. Validación dependiente después de cambios; no paralelizar escritura y tests que exigen estado estable.
- **Caching:** caché de metadatos MCP existente; cache de URL por sesión; reutilización de evidencias con versión; preservar prefijos estables. Evitar caché general de respuestas de agentes.
- **Persistencia:** plan y evidencia bajo `.ai`; un JSONL de métricas pequeño por invocación; logs completos solo opt-in y con permisos adecuados. No mantener toda la sesión del hijo por defecto.
- **Integración:** el principal consume resultados estructurados, verifica riesgos relevantes y aplica deltas. No vuelve a narrar cada informe.

Criterio económico:

```text
Delegar solo si el coste directo evitado o el aislamiento/independencia útil
supera el coste de handoff + trabajo del hijo + espera + integración.
```

No hace falta estimarlo con precisión: basta reconocer los casos obviamente negativos. Un `read`, un grep o una decisión ya resuelta no justifican otro proceso de razonamiento.

## 16. Ejemplos concretos de cambios en configuración/prompts/código

**Propuestas, no aplicadas.** Los snippets de nuevas interfaces requieren implementación/tests; no son opciones que el plugin ya acepte.

### A. Default conservador: mismo modelo, menos esfuerzo automático

Delta de settings:

```json
{
  "defaultThinkingLevel": "medium"
}
```

Primera configuración candidata de agentes:

```yaml
# scout.md
model: openai-codex/gpt-5.6-luna
thinking: low

# researcher.md: solo tras alinear tools y contrato
model: openai-codex/gpt-5.6-luna
thinking: medium

# worker.md
model: openai-codex/gpt-5.6-luna
thinking: medium

# planner.md: reservado a planes que sí justifican delegación
model: openai-codex/gpt-5.6-luna
thinking: medium
```

Para aplicar high por invocación hay que añadir un perfil explícito al plugin o hacer la tarea en el principal con el nivel apropiado. No fingir que escribir “usa high” dentro de task cambia el parámetro del proveedor.

### B. Política global breve de delegación

```text
Use tools directly for lookups, file reads, deterministic transforms and tests.
Delegate only a bounded investigation or independent implementation whose
isolation or parallelism outweighs handoff and verification costs.
Do not delegate work whose evidence is already available.
Normally use 0–1 subagents, up to 2 for disjoint tasks.
Provide goal, constraints, known evidence, acceptance, validation and stop rules.
Keep final scope and acceptance decisions in the main agent.
```

### C. Contrato de entrada compatible con el task actual

```json
{
  "agent": "worker",
  "task": "Goal: corregir cancelación de procesos. Scope: index.ts, sección runSubagent; no cambios de routing ni UI. Known: proc.killed solo indica envío de señal; conservar el parser JSON. Evidence: .ai/plan/...#cancelacion y archivo:680-686. Constraints: preservar cambios preexistentes; no escrituras fuera del slice; no delegar. Acceptance: cancelación queued no hace spawn; SIGTERM ignorado termina con SIGKILL; no quedan descendientes. Validation: test-first con procesos fixture locales, sin proveedor real. Output: status, changes, checks, unresolved; máximo orientativo 500 tokens. Stop: requisito ambiguo o segundo fallo sin evidencia nueva."
}
```

En un encargo real, sustituir referencias ilustrativas por rutas existentes y comandos de validación reales. Incluir changelog si existe y corresponde.

### D. Salida para otro modelo, no para un lector humano

```json
{
  "status": "complete",
  "findings": [
    {
      "claim": "El retorno isError no marca fallo en execute",
      "evidence": ["index.ts:1022-1027", "host/tools.js:66"],
      "confidence": "high",
      "recommended_action": "Propagar status mediante tool_result"
    }
  ],
  "unresolved_questions": [],
  "artifact": null
}
```

Worker usaría `changes` y `checks: [{command, exit_code, result}]`. Confianza es etiqueta de evidencia, no probabilidad calibrada. YAML o Markdown con esos campos puede ser más corto que JSON; usar JSON si se va a validar automáticamente. La estructura mejora síntesis; no garantiza verdad.

### E. Error y usage preservados

Ejemplo conceptual apoyado en los hooks actuales:

```ts
// execute devuelve content compacto + detalles de estado + Usage completo.
return {
  content: [{ type: "text", text: renderCompactResult(result) }],
  details: { status: result.status, results: [result] },
  usage: aggregateInvocationUsage(result),
};

// El host permite modificar isError en tool_result.
pi.on("tool_result", (event) => {
  if (event.toolName !== "subagent") return;
  const status = (event.details as { status?: string } | undefined)?.status;
  if (status === "failed" || status === "cancelled") {
    return { isError: true };
  }
});
```

`renderCompactResult`, `status` y `aggregateInvocationUsage` son funciones/campos propuestos. `aggregateInvocationUsage` debe preservar el objeto cost, distinguir assistant/tool/compaction y no sumar nietos dos veces. `blocked` puede ser un resultado válido del trabajo, pero nunca debe confundirse con aceptación cumplida.

### F. Hijo y lifecycle

```ts
// Selección explícita y menos recursos de interfaz en el proceso efímero.
args.push("--model", agent.model);
args.push("--thinking", effectiveThinking);
args.push("--no-prompt-templates", "--no-themes");

// Truncar siempre; conservar el resto como artifact recuperable.
const clipped = truncateHead(text, { maxBytes: outputBudget, maxLines: 200 });
```

No activar `--no-context-files` sin proveer invariantes equivalentes. Desactivar templates/themes ahorra sobre todo carga local, no cuerpos permanentes en el prompt. Corregir cancelación usando estado de cierre real y finalización del árbol; limpiar timers/listeners/temporales en `finally`.

Validar `maxConcurrency` como entero positivo y emitir error claro ante config inválida; no aceptar cero/NaN silenciosamente. Para nombres/rutas de agentes y slugs, validar segmentos y contener rutas, sin presentar esto como una barrera de seguridad completa.

### G. Presupuestos iniciales, no features existentes

```text
scout quick: 6–10 tool calls, 3–5 respuestas, salida 400–600 tokens.
scout trace: 15–25 tool calls, 6–10 respuestas, salida 600–1.000 tokens.
worker: presupuesto derivado de slice y tests, no un contador fijo universal.
Al alcanzar soft budget: responder partial/blocked con evidencia y pregunta pendiente.
Deadline duro: separado, configurable y siempre con cleanup.
```

Primero usar límites blandos y registrar excesos. No gastar otra llamada de compresión para cumplir el límite. Si se amplía, pasar evidencia ya recogida; no reiniciar la investigación desde cero.

## 17. Plan de benchmarks para verificar las mejoras

### 17.1 Primero corregir observabilidad y protocolo

Tests sin llamadas a modelos:

1. Hijo éxito con respuesta final.
2. Hijo falla después de texto parcial: error exterior y partial preservado.
3. Error recuperable seguido de éxito: no dejar error pegado.
4. Proceso termina sin respuesta final: no marcar complete.
5. Abort mientras espera semáforo: cero spawn.
6. SIGTERM ignorado: SIGKILL y ausencia de descendientes.
7. Falta de modelo/tool/extensión: fail-fast, sin fallback silencioso.
8. JSON fragmentado, Unicode y stderr grande: buffers acotados.
9. Truncado por líneas/bytes con artifact recuperable.
10. Usage de padre/hijo/nieto/compactación: agregación exacta, sin duplicación.
11. Registro de contexto: no conversación heredada, sí reglas previstas; allowlists aplicadas.
12. Config concurrency inválida y dos writers sobre el mismo archivo: rechazo o política explícita.

Usar fixtures de procesos, no proveedores reales. No confundir pruebas de lifecycle con validación de calidad de modelos.

### 17.2 Dataset inicial

30 tareas congeladas, ampliables:

- 5 localizaciones/extracciones con respuestas comprobables.
- 5 cambios mecánicos/implementaciones pequeñas.
- 5 implementaciones multiarchivo contenidas.
- 5 bugs con tests ocultos, incluidos concurrencia/datos.
- 4 revisiones con defectos sembrados y falsos positivos medibles.
- 3 investigaciones con fuentes/versiones fijadas y una variante web viva separada.
- 3 planes arquitectónicos con rúbrica y restricciones verificables.

Incluir tareas que **no deberían delegarse**, no solo tareas donde subagentes lucen bien. El conjunto debe contener casos conocidos y repositorios desconocidos. Cada corrida empieza en checkout/worktree limpio independiente; fixtures sin producción, secretos ni red no necesaria.

### 17.3 Variantes por etapas

- **A:** configuración actual, solo con métricas/errores corregidos en todas las variantes.
- **B:** A + delegación selectiva y contratos compactos; mismos modelos/thinking.
- **C:** B + reasoning low/medium por clase; mismos modelos.
- **D:** C + contexto/tools selectivos y fetch acotado.
- **E:** D + Flash/low en clases candidatas.
- **F:** Luna/high frente a Astra/medium solo en tareas difíciles.
- Experimento separado: directo vs un hijo vs dos hijos independientes, manteniendo la tarea idéntica.

No cambiar todo a la vez. Hacer tres repeticiones iniciales por tarea; repetir más los casos variables o cercanos al umbral de aceptación. Aleatorizar orden e intercalar A/B para reducir sesgos de carga del proveedor.

### 17.4 Métricas

Por tarea y por árbol de ejecución:

- Tiempo total, tiempo hasta primer resultado útil, p50/p95.
- Cola, arranque, TTFT si observable, ejecución, integración y validación.
- Input nuevo, cache-read, cache-write, output; reasoning separado solo si el proveedor lo entrega.
- Máximo contexto vivo por agente; no suma de ventanas confundida con ocupación.
- Respuestas LLM, intentos HTTP, tool calls, subagent calls y profundidad máxima.
- Bytes por tool, archivos/rangos releídos, artefactos recuperados y exceso de budgets.
- Uso/coste reportados; costes no observables marcados como desconocidos.
- Tests visibles y ocultos; cumplimiento de restricciones; cambios no pedidos.
- Correcciones humanas, reintentos semánticos, errores de infraestructura y abandonos separados.
- Calidad de planes/research: exactitud, cobertura, evidencia, contradicciones y facilidad de ejecución.

Los registros deben incluir versión Pi, versiones/hash de plugins/prompts, modelo efectivo, thinking efectivo, rama/commit y caché fría/caliente. No guardar texto sensible en métricas.

### 17.5 Criterio de aceptación

**Primero calidad, luego complejidad, latencia y tokens.** Rechazar una variante con nuevas regresiones graves aunque ahorre mucho.

- Tareas deterministas: mismos tests y restricciones; ninguna nueva regresión crítica.
- Tareas abiertas: evaluación ciega humana con rúbrica, sin saber variante. Un juez LLM es apoyo opcional, no árbitro único ni agente extra en producción.
- Establecer antes del ensayo el margen de no-inferioridad aceptable. Con 30 tareas no afirmar diferencias pequeñas como concluyentes.
- Separar cold/warm cache; no contar cache hit como reducción de contexto.
- Analizar resultados pareados por tarea y clase, no medias mezcladas.
- Elegir la alternativa más simple que no degrade calidad y mejore el camino crítico o coste por tarea aceptada.

**Métrica final recomendada:** recursos y tiempo por tarea correctamente aceptada, incluyendo correcciones y fallbacks. Optimizar tokens de la primera llamada ignorando la segunda es engañoso.

## 18. Estimación cualitativa del impacto global

| Dimensión | Potencial | Confianza |
|---|---|---|
| Fiabilidad del protocolo/diagnóstico | Alto | Alta: defectos confirmados |
| Simplicidad de coordinación | Alto | Alta: se eliminan rutas y obligaciones |
| Latencia en tareas pequeñas | Alto si hoy delegan | Media-alta; falta A/B |
| Latencia en tareas complejas | Medio | Media; depende de camino crítico y proveedor |
| Tokens en exploración/planificación | Medio-alto | Media; mucha relectura y planes largos |
| Contexto permanente | Bajo-medio inicialmente | Media; no hay historial global duplicado ni MCP masivo |
| Coste monetario | Incierto hasta medir tarifas/cuotas reales | Baja-media |
| Calidad de soluciones | Igual o mejor esperada tras eliminar ruido | Debe demostrarse; bajar reasoning/modelo exige pruebas |

No daría un porcentaje global honesto sin el benchmark. La apuesta más sólida es **mejorar simultáneamente calidad y eficiencia corrigiendo el protocolo, reduciendo redescubrimiento y entregando a cada agente solo el contrato necesario**. La apuesta siguiente es bajar esfuerzo manteniendo Luna. Cambiar modelos llega después.

La arquitectura no necesita reinventarse. Necesita que una llamada a subagente sea una decisión económica y técnica explícita, no una obligación del workflow.

### Fuentes y trazabilidad

**Repositorio** — rutas relativas desde su raíz:

- `pi/.pi/agent/extensions/pi-subagents/index.ts`: descubrimiento `118–226`; proceso/contexto `339–435`; parser/lifecycle `481–712`; semáforo `750–766`; tool/result `936–1027`.
- `pi/.pi/agent/extensions/pi-subagents/agents/{scout,researcher,planner,worker}.md` y `README.md`.
- `pi/.pi/agent/settings.json`, `APPEND_SYSTEM.md`, `lsp.json`.
- `pi/.pi/agent/extensions/{memory.ts,context-warning.ts,ast-grep.ts,ask-user-question.ts,caffeine.ts,herdr-agent-state.ts}`.
- `pi/.pi/agent/extensions/web-fetch/index.ts`, `pi-subagents/tools/safe-bash.ts`.
- `pi/.agents/skills/{ops,architect,dev,grill-with-docs}/SKILL.md`; `pi/.pi/agent/prompts/*.md`; `pi/.pi/rules/lean-ctx.md`.

**Runtime instalado** — base: `/Users/rubensilvarodriguez/.local/share/mise/installs/node/24.13.0/lib/node_modules/@earendil-works/pi-coding-agent/`:

- `dist/core/resource-loader.js:372–397`: contexto y append explícito.
- `dist/core/system-prompt.js`: prompt base y catálogo de skills.
- `dist/core/model-resolver.js:473–528`: precedencia de selección.
- `node_modules/@earendil-works/pi-agent-core/dist/harness/execution/tools.js:66`: ejecución normal como éxito.
- `node_modules/@earendil-works/pi-ai/dist/api/openai-responses-shared.js:210–225`: content frente a details.
- `docs/{extensions,sdk,settings,models,skills,packages,prompt-templates,compaction,tui}.md` y README completos de la versión instalada.

**Paquetes activos** — base: `~/.pi/agent/npm/node_modules/`:

- `pi-gpt-search/src/{index,codex-provider}.ts`.
- `pi-lsp-bridge/dist/{index,tools/*}.js`.
- `pi-mcp-adapter/{index.ts,config.ts,mcp-output-guard.ts,metadata-cache.ts,sampling-handler.ts}`.
- `@plannotator/pi-extension/{index.ts,config.ts,plannotator.json}`.

**Fuente externa:**

[1] https://pi.dev/docs/latest/extensions — contrato de error y contabilización de llamadas anidadas; contrastado con el runtime local, que es la referencia principal para esta auditoría.
