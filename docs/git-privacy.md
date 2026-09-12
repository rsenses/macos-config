# Git: configuración compartida y estado privado

Los dotfiles versionan configuración reproducible, no el historial de uso de esta máquina. Las exclusiones están en `.gitignore`; `git/.gitignore` añade protección global para credenciales comunes.

## Qué se conserva en Git

- Configuración de zsh, Git y Neovim, incluido `nvim-pack-lock.json`.
- Pi: `settings.json`, `APPEND_SYSTEM.md`, `auto-compact.json`, `lsp.json`, extensiones, skills, prompts, temas y reglas.
- Herdr: `config.toml` y configuración declarativa de plugins/plantillas.
- Worktrunk: `config.toml`.
- Lockfiles de dependencias de las extensiones, como `package-lock.json`.

## Qué permanece solamente en disco

- Todo `.ai/`: tareas, planes, informes, notas y resultados de sesiones.
- Pi: sesiones, estadísticas/resúmenes de uso, confianza, onboarding, catálogo local de modelos, cachés MCP, credenciales e instalaciones de paquetes.
- Herdr: registro de plugins instalados, enlaces a instalaciones, locks, sockets y estado de versiones vistas.
- Worktrunk: aprobaciones por repositorio y locks de ejecución.
- Licencia de Intelephense, exports SQL en la raíz, copias de respaldo y logs.
- `~/.gitconfig.local`: ajustes privados de Git. El identificador de máquina de CodeRabbit se mantiene aquí, no en el archivo compartido.

Git admite que el include `~/.gitconfig.local` no exista en otra máquina. El fichero local de esta instalación tiene permisos `0600`. No copiarlo al repositorio ni publicar sus valores.

La identidad de autor de Git y las rutas de las plantillas declarativas siguen siendo configuración compartida: no se anonimiza toda la configuración. Revisar siempre los diffs antes de publicar. Una configuración permitida también puede contener secretos si se escriben dentro de ella.

## Pi: exclusión por defecto

Los archivos nuevos en la raíz de `pi/.pi/` o `pi/.pi/agent/` quedan ignorados por defecto. Así, un archivo de estado nuevo creado por Pi o una extensión no se añade accidentalmente al repositorio.

Para versionar una nueva configuración declarativa:

1. Comprobar que no contiene tokens, credenciales, conversaciones ni estado específico de la máquina.
2. Añadir una excepción exacta en la lista de permitidos de `.gitignore`.
3. Añadir un caso a `tests/test_git_privacy.py`.

`models.json` y `mcp.json` no se publican automáticamente porque pueden mezclar configuración con claves o valores privados. Las carpetas permitidas de extensiones/skills/prompts/temas siguen admitiendo código nuevo; las reglas de logs, backups, cachés y secretos comunes también se aplican dentro de ellas. Esto reduce accidentes, pero no sustituye una revisión de contenido.

Herdr y Worktrunk usan la misma idea para su raíz de configuración. Las instalaciones locales no constituyen una receta de bootstrap: en una máquina nueva deben instalarse los plugins/paquetes correspondientes.

## Verificación

Desde la raíz del repositorio:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_git_privacy.py'
git ls-files -ci --exclude-standard
git check-ignore -v --no-index ruta/al/archivo
```

El segundo comando no debe listar archivos. Las pruebas comprueban rutas sintéticas privadas, configuración permitida y ausencia de archivos ignorados todavía versionados. No leen contenidos privados.

## Retirar del índice no borra del disco ni del historial

`git rm --cached -- ruta` deja el archivo local intacto y prepara su retirada del próximo commit. No usar `git rm` sin `--cached` para esta limpieza. Evitar `git clean -fdx`: eliminaría precisamente los archivos privados que se han conservado.

Si un archivo sensible ya apareció en commits anteriores, sigue en el historial y en clones/remotos que lo recibieron. Si había credenciales válidas, revocarlas o rotarlas; limpiar el historial es una operación aparte que requiere coordinación y autorización. Añadir reglas a `.gitignore` no sanea commits anteriores.
