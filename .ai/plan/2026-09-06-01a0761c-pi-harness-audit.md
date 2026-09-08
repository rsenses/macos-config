# Plan: pi-harness-audit
- Status: completed (audit + authorized implementation)
- Created: 2026-09-06
- Session ID: 01a0761c

## Goal
Auditoría profunda de Pi, sin modificar configuración, priorizando calidad y eficiencia distribuida.

## Current Step
Implementación finalizada; configuración/decisiones/resultados en `.ai/audits/2026-09-06-pi-harness/IMPLEMENTATION.md`. Principal Luna/max preservado. Benchmark: 10 completions; Flash bloqueado por saldo insuficiente, sin reintentos ni cambios de pagos.

## Spec / Contract

## Tasks
- [x] Comparar configuración versionada y activa; inventariar recursos.
- [x] Seguir subprocess, contexto, modelos, reasoning, eventos y tools.
- [x] Delegar tres investigaciones acotadas y contrastar sus conclusiones.
- [x] Inspeccionar SDK/docs instalados 0.85.1 y ejecutar probe de carga sin llamadas LLM.
- [x] Extraer métricas de 60 sesiones recientes (360 resultados; muestra heterogénea, no benchmark).
- [x] Redactar informe de 18 secciones, propuestas y benchmarks.

## Implementation
- [x] Plugin: errores/usage, cola y lifecycle, límites y pruebas deterministas.
- [x] Prompts: delegación selectiva, contratos compactos y menos repetición.
- [x] Memory y web_fetch: contexto acotado, streaming/caché/artifacts.
- [x] Revisar integración, habilitar tools por rol y validar carga real sin proveedor.
- [x] Benchmark Luna low/medium/max y tentativa Flash; high queda elegido por riesgo, no medido. 10 completions de 12 autorizadas; Flash bloqueado por saldo.
- [x] Investigación Go, selección final y documentación de resultados/límites.
- [x] Regresiones: 22 tests, type-check estricto, npm audit limpio y diff-check.

## Stop Rules

## Validation Policy

## Implementation validation
- Las carreras de reserva y cancelación se probaron con fixtures sincronizados; se corrigió también una espera indefinida cuando el padre terminaba antes del descendiente.
- Benchmark: dos casos sin ambigüedad correctos en los tres perfiles Luna. Booleano ambiguo de la revisión excluido de conclusiones; grader original preservado.
- Sin cambios en facturación ni proveedor/default thinking del principal. Versiones de paquetes fijadas y Readability 0.6.0 corrige advisory verificado.
- Recargar Pi para cargar el nuevo código/prompt del principal. No se interrumpió la sesión activa.

## Audit validation (historical, before implementation)
- LSP falla por ausencia de TypeScript en workspace; no repetir, usar fuente local.
- Probe ResourceLoader: hijos no cargan APPEND_SYSTEM global; no skills ni contexto de conversación. AGENTS sí se descubre (ninguno en este cwd).
- `lean-ctx.md` no aparece en recursos cargados ni tiene loader localizado: no considerarlo activo.
- Fallos y usage requieren contraste SDK: `execute` retorna isError ignorado por host; falta usage superior.
- No benchmark A/B ni pruebas de proveedores realizados. No atribuir calidad/ahorro causal a estadísticas históricas.
- Verificación final: 18 secciones ordenadas; 30 archivos activos/versionados idénticos por SHA-256; cifras del informe contrastadas con JSON.
- MCP actual: 0 servidores/0 tools de servidor. No atribuirle una explosión de contexto inexistente.
- Solo se escribieron informe, metadatos y este plan en `.ai`; configuración intacta. Sin CHANGELOG.md raíz.
