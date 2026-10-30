"""Isolated lifecycle coverage for dev per-project extra background commands.

The fake servers are the only processes started; state, snippets, Caddy and
locks live under a temporary directory. Real ps/lsof are used for process
identity, exactly as the command uses them.
"""
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/.local/bin/dev'
SOURCE = SCRIPT.read_text()
TOOLS_AVAILABLE = (
    all(shutil.which(tool) for tool in ('bash', 'lsof', 'ps', 'python3'))
    and (shutil.which('shasum') or shutil.which('sha256sum'))
)


def wait_until(predicate, timeout=6):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.05)
    return bool(predicate())


def process_alive(pid):
    if not isinstance(pid, int) or pid <= 1:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def state_values(path):
    values = {}
    for line in Path(path).read_text().splitlines():
        if '=' in line:
            key, value = line.split('=', 1)
            values[key] = value
    return values


@unittest.skipUnless(TOOLS_AVAILABLE, 'dev extras lifecycle tests need bash, lsof and ps')
class DevExtrasLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory(prefix='dev-extras-test.')
        self.tmp = Path(self.tempdir.name).resolve()
        self.home = self.tmp / 'home'
        self.fakebin = self.tmp / 'bin'
        self.project = self.tmp / 'project'
        self.home.mkdir()
        self.fakebin.mkdir()
        self.project.mkdir()
        (self.project / '.config').mkdir()
        (self.project / 'artisan').touch()

        self.env = dict(os.environ)
        self.env.update({
            'HOME': str(self.home),
            'PATH': f'{self.fakebin}:{os.environ["PATH"]}',
            'DEV_STATE_PREFIX': str(self.tmp / 'state'),
            'DEV_SITES_DIR': str(self.tmp / 'sites'),
            'DEV_CADDYFILE': str(self.tmp / 'Caddyfile'),
            'DEV_LOCK_DIR': str(self.tmp / 'lock'),
            'DEV_CADDY_ADMIN': 'http://127.0.0.1:1',
            'DEV_DOMAIN_SUFFIX': 'test',
            'FAKE_PHP_PID_FILE': str(self.tmp / 'php.pids'),
            'FAKE_EXTRA_PIDS': str(self.tmp / 'extra.pids'),
            'EXTRA_CWD_FILE': str(self.tmp / 'cwd.txt'),
            'SENTINEL_FILE': str(self.tmp / 'sentinel'),
        })

        self._write_executable('php', '''#!/usr/bin/env python3
import http.server
import os
import socketserver
import sys

port = next(int(arg.split("=", 1)[1]) for arg in sys.argv if arg.startswith("--port="))
with open(os.environ["FAKE_PHP_PID_FILE"], "a") as handle:
    handle.write(f"{os.getpid()}\\n")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):
        pass

with socketserver.TCPServer(("127.0.0.1", port), Handler) as server:
    server.serve_forever()
''')
        self._write_executable('npm', '''#!/usr/bin/env bash
set -u
if [[ "${1:-}" == "run" && "${2:-}" == "api:dev" ]]; then
  echo "api extra started"
  printf '%s\\n' "$PWD" > "$EXTRA_CWD_FILE"
  printf '%s\\n' "$$" >> "$FAKE_EXTRA_PIDS"
  exec sleep 300
fi
if [[ "${1:-}" == "run" && "${2:-}" == "cwd:dev" ]]; then
  printf '%s\\n' "$PWD" > "$EXTRA_CWD_FILE"
  printf '%s\\n' "$$" >> "$FAKE_EXTRA_PIDS"
  exec sleep 300
fi
if [[ "${1:-}" == "run" && "${2:-}" == "sentinel" ]]; then
  : > "$SENTINEL_FILE"
  printf '%s\\n' "$$" >> "$FAKE_EXTRA_PIDS"
  exec sleep 300
fi
if [[ "${1:-}" == "run" && "${2:-}" == "fail:dev" ]]; then
  echo "failing extra"
  printf '%s\\n' "$$" >> "$FAKE_EXTRA_PIDS"
  exit 7
fi
if [[ "${1:-}" == "run" && "${2:-}" == "bg:dev" ]]; then
  sleep 300 &
  echo "$!" >> "$FAKE_EXTRA_PIDS"
  exit 0
fi
if [[ "${1:-}" == "run" && "${2:-}" == "tree:dev" ]]; then
  sleep 300 &
  { echo "$$"; echo "$!"; } >> "$FAKE_EXTRA_PIDS"
  wait "$!"
fi
echo "unexpected npm: $*" >&2
exit 9
''')
        self._write_executable('caddy', '#!/bin/sh\nexit 0\n')
        self._write_executable('curl', '#!/bin/sh\nexit 1\n')

    def tearDown(self):
        # Best effort for failed assertions: the command's own down-all first,
        # then kill only PIDs recorded by the fakes.
        try:
            self.run_dev('down-all', timeout=15)
        except Exception:
            pass
        for name in ('php.pids', 'extra.pids'):
            path = self.tmp / name
            if path.exists():
                for line in path.read_text().splitlines():
                    try:
                        os.kill(int(line), signal.SIGKILL)
                    except (ValueError, ProcessLookupError, PermissionError):
                        pass
        self.tempdir.cleanup()

    def _write_executable(self, name, content):
        path = self.fakebin / name
        path.write_text(content)
        path.chmod(0o755)

    def run_dev(self, *args, timeout=30):
        return subprocess.run(
            [str(SCRIPT), *map(str, args)],
            env=self.env, text=True, capture_output=True, timeout=timeout,
        )

    def write_config(self, *lines):
        (self.project / '.config/caddy').write_text('\n'.join(lines) + '\n')

    def prefix(self):
        return Path(self.env['DEV_STATE_PREFIX'])

    def main_states(self):
        prefix = self.prefix()
        return sorted(prefix.parent.glob(f'{prefix.name}-*.state'))

    def extras_dir(self):
        project_id = hashlib.sha256(str(self.project).encode()).hexdigest()
        return Path(f'{self.prefix()}-{project_id}.extras')

    def extra_states(self):
        return sorted(self.extras_dir().glob('*.state'))

    def start_and_read_extra(self):
        up = self.run_dev('up', self.project)
        self.assertEqual(up.returncode, 0, up.stderr)
        states = self.extra_states()
        self.assertEqual(len(states), 1, up.stdout + up.stderr)
        return state_values(states[0])

    def test_up_status_down_manages_extra_with_project_cwd_and_log(self):
        self.write_config('PORT=8021', 'EXTRAS=npm run api:dev')
        extra = self.start_and_read_extra()
        extra_pid = int(extra['PID'])
        main = state_values(self.main_states()[0])
        main_pid = int(main['PID'])

        self.assertEqual(extra['PGID'], extra['PID'])
        self.assertEqual(extra['WORK_DIR'], str(self.project))
        self.assertTrue(process_alive(extra_pid))
        self.assertEqual(Path(self.env['EXTRA_CWD_FILE']).read_text().strip(), str(self.project))
        self.assertIn('api extra started', Path(extra['LOG_FILE']).read_text())

        status = self.run_dev('status', self.project)
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertIn('Extra 1: npm run api:dev', status.stdout)
        self.assertIn(f'activo (PID {extra_pid})', status.stdout)
        self.assertIn(str(extra['LOG_FILE']), status.stdout)

        down = self.run_dev('down', self.project)
        self.assertEqual(down.returncode, 0, down.stderr)
        self.assertTrue(wait_until(lambda: not process_alive(extra_pid)))
        self.assertTrue(wait_until(lambda: not process_alive(main_pid)))
        self.assertEqual(self.extra_states(), [])
        self.assertEqual(self.main_states(), [])

    def test_failed_extra_rolls_back_main_and_earlier_extras(self):
        self.write_config('EXTRAS=npm run api:dev', 'EXTRAS=npm run fail:dev')
        up = self.run_dev('up', self.project)
        self.assertNotEqual(up.returncode, 0)
        self.assertIn('terminó inmediatamente', up.stderr)
        self.assertIn('npm run fail:dev', up.stderr)

        extra_pids = [
            int(line) for line in (self.tmp / 'extra.pids').read_text().splitlines() if line
        ]
        self.assertTrue(extra_pids)
        main_pids = [
            int(line) for line in (self.tmp / 'php.pids').read_text().splitlines() if line
        ]
        self.assertTrue(main_pids)
        for pid in extra_pids + main_pids:
            self.assertTrue(wait_until(lambda pid=pid: not process_alive(pid)), pid)
        self.assertEqual(self.main_states(), [])
        self.assertEqual(self.extra_states(), [])
        self.assertEqual(list((self.tmp / 'sites').glob('*.caddy')), [])

    def test_down_uses_recorded_extra_after_config_changes(self):
        self.write_config('EXTRAS=npm run api:dev')
        extra = self.start_and_read_extra()
        extra_pid = int(extra['PID'])

        self.write_config('EXTRAS=npm run sentinel')
        status = self.run_dev('status', self.project)
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertIn('npm run api:dev', status.stdout)
        self.assertIn('Configurado ahora: npm run sentinel', status.stdout)
        self.assertFalse((self.tmp / 'sentinel').exists())

        down = self.run_dev('down', self.project)
        self.assertEqual(down.returncode, 0, down.stderr)
        self.assertTrue(wait_until(lambda: not process_alive(extra_pid)))
        self.assertFalse((self.tmp / 'sentinel').exists())
        self.assertEqual(self.extra_states(), [])

    def test_status_lists_configured_extra_without_running_it(self):
        self.write_config('EXTRAS=npm run sentinel')
        status = self.run_dev('status', self.project)
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertIn('npm run sentinel (configurado; no iniciado)', status.stdout)
        self.assertFalse((self.tmp / 'sentinel').exists())
        self.assertEqual(self.extra_states(), [])
        self.assertEqual(self.main_states(), [])

    def test_reload_replaces_recorded_extra_from_new_config(self):
        self.write_config('EXTRAS=npm run api:dev')
        old_extra = self.start_and_read_extra()
        old_pid = int(old_extra['PID'])

        self.write_config('EXTRAS=npm run cwd:dev')
        reload = self.run_dev('reload', self.project)
        self.assertEqual(reload.returncode, 0, reload.stderr)
        self.assertTrue(wait_until(lambda: not process_alive(old_pid)))

        states = self.extra_states()
        self.assertEqual(len(states), 1)
        new_extra = state_values(states[0])
        self.assertEqual(new_extra['COMMAND'], 'npm run cwd:dev')
        self.assertTrue(process_alive(int(new_extra['PID'])))
        self.assertEqual(Path(self.env['EXTRA_CWD_FILE']).read_text().strip(), str(self.project))

    def test_background_descendant_is_cleaned_up_on_startup_rollback(self):
        self.write_config('EXTRAS=npm run bg:dev')
        up = self.run_dev('up', self.project)
        self.assertNotEqual(up.returncode, 0)
        background_pids = [
            int(line) for line in (self.tmp / 'extra.pids').read_text().splitlines() if line
        ]
        self.assertTrue(background_pids)
        for pid in background_pids:
            self.assertTrue(wait_until(lambda pid=pid: not process_alive(pid)), pid)
        self.assertEqual(self.main_states(), [])
        self.assertEqual(self.extra_states(), [])

    def test_down_stops_nested_descendants_of_an_extra(self):
        self.write_config('EXTRAS=npm run tree:dev')
        up = self.run_dev('up', self.project)
        self.assertEqual(up.returncode, 0, up.stderr)
        pids = [
            int(line) for line in (self.tmp / 'extra.pids').read_text().splitlines() if line
        ]
        self.assertEqual(len(pids), 2, pids)
        self.assertTrue(all(process_alive(pid) for pid in pids))

        down = self.run_dev('down', self.project)
        self.assertEqual(down.returncode, 0, down.stderr)
        for pid in pids:
            self.assertTrue(wait_until(lambda pid=pid: not process_alive(pid)), pid)

    def test_down_all_stops_main_and_all_extras(self):
        self.write_config('EXTRAS=npm run api:dev', 'EXTRAS=npm run cwd:dev')
        up = self.run_dev('up', self.project)
        self.assertEqual(up.returncode, 0, up.stderr)
        states = self.extra_states()
        self.assertEqual(len(states), 2)
        pids = [int(state_values(state)['PID']) for state in states]
        pids.append(int(state_values(self.main_states()[0])['PID']))

        down = self.run_dev('down-all')
        self.assertEqual(down.returncode, 0, down.stderr)
        for pid in pids:
            self.assertTrue(wait_until(lambda pid=pid: not process_alive(pid)), pid)
        self.assertEqual(self.extra_states(), [])
        self.assertEqual(self.main_states(), [])

    def test_down_does_not_stop_extra_whose_start_time_is_stale(self):
        marker = f'dev-extra-supervisor:{hashlib.sha256(str(self.project).encode()).hexdigest()}:1'
        unrelated = subprocess.Popen(
            ['bash', '-c', 'sleep 300; :', 'dev-extra-supervisor', marker],
            cwd=self.project, start_new_session=True,
        )
        try:
            extras = self.extras_dir()
            extras.mkdir(parents=True)
            (extras / '1.state').write_text(
                'KIND=extra\n'
                f'PROJECT_DIR={self.project}\n'
                'INDEX=1\n'
                'COMMAND=npm run unrelated\n'
                f'PID={unrelated.pid}\n'
                'PID_START=stale-start-time\n'
                f'PGID={unrelated.pid}\n'
                f'WORK_DIR={self.project}\n'
                f'MARKER={marker}\n'
                f'LOG_FILE={extras / "1.log"}\n'
            )

            down = self.run_dev('down', self.project)
            self.assertNotEqual(down.returncode, 0)
            self.assertIn('no corresponde a este proyecto', down.stderr)
            self.assertTrue(process_alive(unrelated.pid))
            self.assertEqual(self.extra_states(), [])
        finally:
            # The fixture is a process-group leader (start_new_session), so the
            # shell and its `sleep` child must be reaped together.
            try:
                os.killpg(unrelated.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            unrelated.wait(timeout=5)


class DevExtrasConfigTests(unittest.TestCase):
    def test_config_parsing_keeps_commands_literal_and_never_sources(self):
        with tempfile.TemporaryDirectory(prefix='dev-extras-config.') as tmp:
            tmp = Path(tmp)
            sentinel = tmp / 'sourced'
            config = tmp / 'caddy'
            config.write_text(
                'PORT=8021\n'
                'EXTRAS=echo one\n'
                'EXTRAS=echo two # dropped by the shell, not by parsing\n'
                'EXTRAS=\n'
                f'EVIL=$(touch {sentinel})\n'
            )
            prefix = SOURCE.split('\ncase "${cmd}" in\n')[0]
            body = (
                f'CONFIG_FILE={shlex.quote(str(config))}\n'
                'DOMAIN=project.test\n'
                'load_project_config\n'
                'printf "%s\\n" "${EXTRA_COMMANDS[@]}"\n'
                f'test ! -e {shlex.quote(str(sentinel))}\n'
            )
            result = subprocess.run(
                ['bash', '-c', prefix + '\n' + body, 'dev'],
                env=dict(os.environ, HOME=tmp), text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                result.stdout.splitlines(),
                ['echo one', 'echo two # dropped by the shell, not by parsing'],
            )
            self.assertFalse(sentinel.exists())


if __name__ == '__main__':
    unittest.main()
