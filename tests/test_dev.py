"""Pruebas aisladas para bin/.local/bin/dev.

No tocan /tmp/dev real, Caddy, sudo, PHP ni proyectos del usuario: todas las
rutas se redirigen a un directorio temporal mediante las variables DEV_* del
propio script, y los comandos externos (curl, caddy, sudo, lsof, ps, php) se
sustituyen por dobles falsos. El único proceso real que se señaliza es un
`sleep` creado por la propia prueba.

Ejecución: PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_dev.py'
"""

import hashlib
import os
import shutil
import signal
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / "bin" / ".local" / "bin" / "dev"


class DevTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="dev-test-"))
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

        self.sites = self.tmp / "sites"
        self.run_dir = self.tmp / "run"
        self.state_prefix = str(self.run_dir / "dev")
        self.fakebin = self.tmp / "fakebin"
        self.fakebin.mkdir()
        self.psdata = self.tmp / "psdata"
        self.calls = self.tmp / "calls.log"
        self.caddyfile = self.tmp / "Caddyfile"
        self.caddyfile.write_text("# Caddyfile de prueba\n")

        self.project = self.tmp / "proyecto"
        self.project.mkdir()
        self.project_real = Path(os.path.realpath(self.project))

        self._write_fake("curl", f'''#!/bin/sh
printf 'curl %s\\n' "$*" >> "{self.calls}"
[ -f "{self.tmp}/caddy-running" ]
''')
        self._write_fake("caddy", f'''#!/bin/sh
printf 'caddy %s\\n' "$*" >> "{self.calls}"
[ -f "{self.tmp}/caddy-ok" ]
''')
        self._write_fake("sudo", f'''#!/bin/sh
printf 'sudo %s\\n' "$*" >> "{self.calls}"
exit 1
''')
        # Devuelve "libre" hasta DEV_FAKE_LSOF_LISTEN_FROM llamadas y "ocupado"
        # después; por defecto nunca está ocupado.
        self._write_fake("lsof", f'''#!/bin/sh
printf 'lsof %s\\n' "$*" >> "{self.calls}"
count=$(cat "{self.tmp}/lsof-count" 2>/dev/null || echo 0)
count=$((count + 1))
printf '%s\\n' "$count" > "{self.tmp}/lsof-count"
if [ "$count" -ge "${{DEV_FAKE_LSOF_LISTEN_FROM:-1000000}}" ] && printf '%s' "$*" | grep -q -- ' -t '; then
  tail -n 1 "{self.tmp}/fakephp.pids" 2>/dev/null || true
fi
[ "$count" -ge "${{DEV_FAKE_LSOF_LISTEN_FROM:-1000000}}" ]
''')
        self._write_fake("ps", '''#!/bin/sh
dir="$FAKE_PS_DIR"
[ -n "$dir" ] || exit 1
pid=""
what=""
while [ $# -gt 0 ]; do
  case "$1" in
    -p) pid="$2"; shift 2 ;;
    -o) what="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$pid" ] || exit 1
case "$what" in
  command=) cat "$dir/$pid.cmd" 2>/dev/null || exit 1 ;;
  lstart=) cat "$dir/$pid.lstart" 2>/dev/null || exit 1 ;;
  state=) /bin/ps -ww -p "$pid" -o state= 2>/dev/null || exit 1 ;;
  ppid=) cat "$dir/$pid.ppid" 2>/dev/null || exit 1 ;;
  *) exit 1 ;;
esac
''')
        # El doble de kill elimina la identidad sintética al señalizar un PID;
        # así la prueba no confunde un zombie hijo del propio test con un proceso vivo.
        self._write_fake("kill", f'''#!/bin/sh
if [ "${{1:-}}" = "-0" ]; then
  exec /bin/kill "$@"
fi
case "${{1:-}}" in
  -*) pid="${{2:-}}" ;;
  *) pid="${{1:-}}" ;;
esac
case "$pid" in *[!0-9]*|'') ;; *) rm -f "$FAKE_PS_DIR/$pid.cmd" "$FAKE_PS_DIR/$pid.lstart" ;; esac
exec /bin/kill "$@"
''')
        # php falso: registra su comando/hora para el doble de ps y sigue vivo.
        self._write_fake("php", f'''#!/bin/sh
dir="$FAKE_PS_DIR"
if [ -n "$dir" ]; then
  mkdir -p "$dir"
  port=""
  for arg in "$@"; do
    case "$arg" in --port=*) port="${{arg#--port=}}" ;; esac
  done
  printf 'php artisan serve --host=127.0.0.1 --port=%s\\n' "$port" > "$dir/$$.cmd"
  printf 'FAKE-START\\n' > "$dir/$$.lstart"
  printf '%s\\n' "$$" >> "{self.tmp}/fakephp.pids"
fi
exec sleep 300
''')

        self.addCleanup(self._kill_fake_php)

    # -- utilidades ---------------------------------------------------------

    def _write_fake(self, name, body):
        path = self.fakebin / name
        path.write_text(body)
        path.chmod(0o755)

    def _kill_fake_php(self):
        marker = self.tmp / "fakephp.pids"
        if not marker.exists():
            return
        for line in marker.read_text().split():
            try:
                os.kill(int(line), signal.SIGKILL)
            except (ProcessLookupError, ValueError):
                pass

    def run_dev(self, *args, cwd=None, env_extra=None):
        env = os.environ.copy()
        env["PATH"] = f"{self.fakebin}{os.pathsep}{env['PATH']}"
        env["DEV_SITES_DIR"] = str(self.sites)
        env["DEV_STATE_PREFIX"] = self.state_prefix
        env["DEV_CADDYFILE"] = str(self.caddyfile)
        env["DEV_CADDY_ADMIN"] = "http://127.0.0.1:20199"
        env["FAKE_PS_DIR"] = str(self.psdata)
        if env_extra:
            env.update(env_extra)
        return subprocess.run(
            [str(DEV), *args],
            cwd=str(cwd if cwd is not None else self.project),
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )

    def mark_caddy_running(self):
        (self.tmp / "caddy-running").touch()

    def mark_caddy_ok(self):
        (self.tmp / "caddy-ok").touch()

    def write_snippet(self, name, port):
        path = self.sites / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            f"{name[:-len('.caddy')]}.test {{\n"
            f"reverse_proxy 127.0.0.1:{port} {{\n"
            "}\n}\n"
        )
        return path

    def state_file_for(self, project_dir):
        sha = hashlib.sha256(str(project_dir).encode()).hexdigest()
        return self.run_dir / f"dev-{sha}.state"

    def write_state(self, project_dir, pid, port, pid_start=""):
        self.run_dir.mkdir(parents=True, exist_ok=True)
        domain = Path(project_dir).name + ".test"
        path = self.state_file_for(project_dir)
        path.write_text(
            f"PROJECT_DIR={project_dir}\n"
            f"DOMAIN={domain}\n"
            f"HOSTS={domain}\n"
            f"PORT={port}\n"
            f"PID={pid}\n"
            f"PID_START={pid_start}\n"
        )
        return path

    def dead_pid(self):
        proc = subprocess.Popen(["/bin/sleep", "0"])
        proc.wait()
        return proc.pid

    def spawn_sleep(self, seconds=300):
        proc = subprocess.Popen(["/bin/sleep", str(seconds)])

        def cleanup():
            if proc.poll() is None:
                proc.kill()
            proc.wait()

        self.addCleanup(cleanup)
        return proc

    def set_ps_identity(self, pid, command, start=None):
        self.psdata.mkdir(parents=True, exist_ok=True)
        (self.psdata / f"{pid}.cmd").write_text(command + "\n")
        if start is not None:
            (self.psdata / f"{pid}.lstart").write_text(start + "\n")

    def wait_dead(self, proc, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                return True
            time.sleep(0.05)
        return False

    def fake_php_pids(self):
        marker = self.tmp / "fakephp.pids"
        if not marker.exists():
            return []
        return [int(line) for line in marker.read_text().split() if line]

    def wait_pid_gone(self, pid, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                return True
            time.sleep(0.05)
        return False

    def caddy_calls(self):
        if not self.calls.exists():
            return []
        return [line for line in self.calls.read_text().splitlines()
                if line.startswith("caddy ")]

    # -- pruebas ------------------------------------------------------------

    def test_bash_syntax_ok(self):
        result = subprocess.run(["bash", "-n", str(DEV)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_down_removes_snippet_and_reloads_caddy(self):
        self.mark_caddy_running()
        self.mark_caddy_ok()
        state = self.write_state(self.project_real, pid=self.dead_pid(), port=8123)
        snippet = self.write_snippet("proyecto.caddy", 8123)
        other = self.write_snippet("otro.caddy", 9999)

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK: parado proyecto.test", result.stdout)
        self.assertIn("Snippet retirado", result.stderr)
        self.assertFalse(snippet.exists())
        self.assertTrue(other.exists(), "no debe tocar snippets de otros puertos")
        self.assertFalse(state.exists(), "estado obsoleto retirado")
        caddy_calls = self.caddy_calls()
        self.assertEqual(len(caddy_calls), 1, caddy_calls)
        self.assertIn("reload", caddy_calls[0])
        self.assertIn(str(self.caddyfile), caddy_calls[0])

    def test_down_without_caddy_reports_warning(self):
        state = self.write_state(self.project_real, pid=self.dead_pid(), port=8123)
        snippet = self.write_snippet("proyecto.caddy", 8123)

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK: parado proyecto.test", result.stdout)
        self.assertIn("Caddy no está en ejecución", result.stderr)
        self.assertFalse(snippet.exists())
        self.assertFalse(state.exists())
        self.assertEqual(self.caddy_calls(), [], "no debe invocar caddy si no corre")

    def test_down_reports_error_when_caddy_reload_fails(self):
        self.mark_caddy_running()  # caddy corre pero el reload falla (sin caddy-ok)
        state = self.write_state(self.project_real, pid=self.dead_pid(), port=8123)
        snippet = self.write_snippet("proyecto.caddy", 8123)

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("no pude ejecutar 'caddy reload'", result.stderr)
        self.assertFalse(snippet.exists(), "el snippet se retira aunque el reload falle")
        self.assertFalse(state.exists())
        self.assertIn("no pude detener", result.stderr)

    def test_down_does_not_kill_unverified_process(self):
        proc = self.spawn_sleep()
        self.set_ps_identity(proc.pid, "vim notas.txt")
        self.write_state(self.project_real, pid=proc.pid, port=8123)

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("no corresponde a un servidor PHP", result.stderr)
        self.assertIsNone(proc.poll(), "no debe señalizar un PID no verificado")
        self.assertFalse(self.state_file_for(self.project_real).exists())

    def test_down_kills_verified_artisan_server(self):
        proc = self.spawn_sleep()
        self.set_ps_identity(
            proc.pid,
            "php artisan serve --host=127.0.0.1 --port=8123",
            start="FAKE-START",
        )
        self.write_state(self.project_real, pid=proc.pid, port=8123, pid_start="FAKE-START")

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.wait_dead(proc), "el servidor verificado debe recibir la señal")
        self.assertFalse(self.state_file_for(self.project_real).exists())

    def test_down_rejects_reused_pid(self):
        proc = self.spawn_sleep()
        # El comando coincidiría, pero la hora de arranque guardada no: PID reciclado.
        self.set_ps_identity(
            proc.pid,
            "php artisan serve --host=127.0.0.1 --port=8123",
            start="FAKE-START",
        )
        self.write_state(self.project_real, pid=proc.pid, port=8123, pid_start="OTRA-HORA")

        result = self.run_dev("down")

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("no corresponde a un servidor PHP", result.stderr)
        self.assertIsNone(proc.poll(), "un PID reciclado no debe recibir señales")
        self.assertFalse(self.state_file_for(self.project_real).exists())

    def test_down_all_stops_all_projects_with_single_reload(self):
        self.mark_caddy_running()
        self.mark_caddy_ok()
        project2 = self.tmp / "proyecto2"
        project2.mkdir()
        project2_real = Path(os.path.realpath(project2))

        state1 = self.write_state(self.project_real, pid=self.dead_pid(), port=8123)
        state2 = self.write_state(project2_real, pid=self.dead_pid(), port=8124)
        snippet1 = self.write_snippet("proyecto.caddy", 8123)
        snippet2 = self.write_snippet("proyecto2.caddy", 8124)
        other = self.write_snippet("otro.caddy", 9999)

        result = self.run_dev("down-all")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK: todos los servidores PHP detenidos", result.stdout)
        self.assertFalse(snippet1.exists())
        self.assertFalse(snippet2.exists())
        self.assertTrue(other.exists())
        self.assertFalse(state1.exists())
        self.assertFalse(state2.exists())
        self.assertEqual(len(self.caddy_calls()), 1, "debe recargar Caddy una sola vez")

    def test_status_reports_active_verified_server(self):
        proc = self.spawn_sleep()
        self.set_ps_identity(
            proc.pid,
            "php artisan serve --host=127.0.0.1 --port=8123",
            start="FAKE-START",
        )
        self.write_state(self.project_real, pid=proc.pid, port=8123, pid_start="FAKE-START")

        result = self.run_dev("status")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Puerto: 8123", result.stdout)
        self.assertIn("Servidor PHP: activo en 127.0.0.1:8123", result.stdout)

    def test_up_writes_state_and_snippet(self):
        self.mark_caddy_running()
        self.mark_caddy_ok()
        (self.project / "artisan").write_text("")
        env_extra = {"DEV_FAKE_LSOF_LISTEN_FROM": "3"}

        result = self.run_dev("up", env_extra=env_extra)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK: https://proyecto.test", result.stdout)
        self.assertIn("127.0.0.1:8000", result.stdout)

        snippet = self.sites / "proyecto.caddy"
        self.assertTrue(snippet.exists())
        content = snippet.read_text()
        self.assertIn("proyecto.test {", content)
        self.assertIn("reverse_proxy 127.0.0.1:8000", content)

        state = self.state_file_for(self.project_real)
        self.assertTrue(state.exists())
        values = dict(
            line.split("=", 1) for line in state.read_text().splitlines() if "=" in line
        )
        self.assertEqual(values["PORT"], "8000")
        self.assertEqual(values["PID_START"], "FAKE-START")
        self.assertEqual(int(values["PID"]), self.fake_php_pids()[0])
        self.assertEqual(list(self.run_dir.glob("*.tmp.*")), [], "sin archivos temporales")

        caddy_calls = self.caddy_calls()
        self.assertNotIn("caddy start", " | ".join(caddy_calls),
                         "con el endpoint admin activo no debe arrancar Caddy")
        self.assertTrue(any("reload" in call for call in caddy_calls))

    def test_up_failure_removes_snippet_and_state(self):
        # Caddy no está en ejecución y el arranque falla: no debe quedar ni el
        # snippet ni el estado, y el servidor falso debe quedar detenido.
        (self.project / "artisan").write_text("")
        env_extra = {"DEV_FAKE_LSOF_LISTEN_FROM": "3"}

        result = self.run_dev("up", env_extra=env_extra)

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("no pude recargar Caddy", result.stderr)
        self.assertFalse((self.sites / "proyecto.caddy").exists())
        self.assertFalse(self.state_file_for(self.project_real).exists())
        self.assertTrue(any("caddy start" in call for call in self.caddy_calls()))
        for pid in self.fake_php_pids():
            self.assertTrue(self.wait_pid_gone(pid), "el servidor debe quedar detenido")


if __name__ == "__main__":
    unittest.main()
