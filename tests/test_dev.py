"""Isolated argument/launcher checks; never touch real dev state or Caddy."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/.local/bin/dev'
SOURCE = SCRIPT.read_text()


class DevOptionsTests(unittest.TestCase):
    def run_fragment(self, args, body, definitions=False):
        prefix = SOURCE.split('\ncase "${cmd}" in\n')[0] if definitions else SOURCE.split('\ntrim() {')[0]
        with tempfile.TemporaryDirectory() as tmp:
            env = dict(os.environ, HOME=tmp, DEV_STATE_PREFIX=f'{tmp}/state',
                       DEV_SITES_DIR=f'{tmp}/sites', DEV_CADDYFILE=f'{tmp}/Caddyfile',
                       DEV_LOCK_DIR=f'{tmp}/lock', DEV_CADDY_ADMIN='http://127.0.0.1:1',
                       DEV_DOMAIN_SUFFIX='test')
            return subprocess.run(['bash', '-c', prefix + '\n' + body, 'dev', *args],
                                  env=env, text=True, capture_output=True)

    def test_default_keeps_reload(self):
        result = self.run_fragment(['up'], 'printf "%s|%s" "$name" "$NO_RELOAD"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '|0')

    def test_explicit_option_in_either_position(self):
        for command in ('up', 'reload'):
            for args in ([command, 'my project', '--no-reload'],
                         [command, '--no-reload', 'my project']):
                with self.subTest(args=args):
                    result = self.run_fragment(args, 'printf "%s|%s" "$name" "$NO_RELOAD"')
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout, 'my project|1')

    def test_invalid_arguments_fail(self):
        for args in (['status', '--no-reload'], ['down', '--no-reload'],
                     ['up', '--unknown'], ['up', 'one', 'two']):
            with self.subTest(args=args):
                self.assertNotEqual(self.run_fragment(args, ':').returncode, 0)

    def test_php_server_identity_accepts_versioned_executables(self):
        for executable in ('php', '/usr/bin/php', '/usr/bin/php7.4', '/opt/php8.4/bin/php'):
            with self.subTest(executable=executable):
                result = self.run_fragment(['status'],
                    f'php_command_matches "{executable} -S 127.0.0.1:8123 -t /project/public" 8123',
                    definitions=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_php_server_identity_rejects_unrelated_commands_and_ports(self):
        for command in ('/usr/bin/php7.4 -S 127.0.0.1:8124',
                        '/usr/bin/notphp7.4 -S 127.0.0.1:8123',
                        'echo php -S 127.0.0.1:8123',
                        '/usr/bin/php7.4 script.php'):
            with self.subTest(command=command):
                result = self.run_fragment(['status'],
                    f'php_command_matches "{command}" 8123', definitions=True)
                self.assertNotEqual(result.returncode, 0)

    def test_laravel_command_only_gets_flag_when_requested(self):
        for args, expected in ((['up'], False), (['up', '--no-reload'], True)):
            with self.subTest(args=args):
                result = self.run_fragment(args, '''
PROJECT_DIR="$HOME"
LOG_FILE="$HOME/server.log"
STATE_FILE="$HOME/server.state"
SERVER_TYPE=laravel
PORT=8123
nohup() { printf '%s\\n' "$@"; }
write_server_state() { wait "$1"; }
start_server
while IFS= read -r line; do printf '%s\\n' "$line"; done < "$LOG_FILE"
''', definitions=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = result.stdout.splitlines()
                self.assertEqual(argv[:5], ['php', 'artisan', 'serve', '--host=127.0.0.1', '--port=8123'])
                self.assertEqual('--no-reload' in argv, expected)


if __name__ == '__main__':
    unittest.main()
