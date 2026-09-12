"""Regression tests for the Herdr worktree selector.

The helper commands are synthetic; no real Herdr workspace is created.
Run: PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_herdr_sessionizer.py'
"""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "bin/.local/bin/herdr-sessionizer"


class HerdrSessionizerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="herdr-sessionizer-test-"))
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.fakebin = self.tmp / "bin"
        self.fakebin.mkdir()
        self.calls = self.tmp / "calls"
        self.project = self.tmp / "repo"
        self.project.mkdir()
        self.main = self.tmp / "repo-main"
        self.feature = self.tmp / "repo-feature"
        self.main.mkdir()
        self.feature.mkdir()

    def fake(self, name, body):
        path = self.fakebin / name
        path.write_text(body)
        path.chmod(0o755)

    def run_script(self, worktrees):
        self.fake("zoxide", f"""#!/bin/sh
printf '%s\\n' '{self.project}'
""")
        self.fake("git", f"""#!/bin/sh
case "$*" in
  *'rev-parse --is-inside-work-tree'*) printf 'true\\n' ;;
  *'worktree list --porcelain'*)
    printf 'worktree {self.main}\\nworktree {self.feature}\\n'
    ;;
  *) exit 1 ;;
esac
""")
        self.fake("fzf", f"""#!/bin/sh
count_file='{self.tmp}/fzf-count'
count=$(cat "$count_file" 2>/dev/null || printf 0)
count=$((count + 1))
printf '%s\\n' "$count" > "$count_file"
if [ "$count" -eq 1 ]; then
  printf '%s\\n' '{self.project}'
elif [ "{worktrees}" = "all" ]; then
  # Select the main checkout from the second picker. The important assertion
  # is that this path is present in its input; selecting it exercises parsing.
  input=$(cat)
  printf '%s\\n' "$input" > '{self.tmp}/worktree-options'
  printf '%s\\n' "$input" | grep -F '{self.main}' | head -n 1
else
  exit 1
fi
""")
        self.fake("herdr", f"""#!/bin/sh
if [ "${{1:-}}" = "worktree" ] && [ "${{2:-}}" = "list" ]; then
  printf '%s\\n' '{{"result":{{"source":{{"repo_root":"{self.main}","repo_name":"repo","source_workspace_id":"ws-root"}}}}}}'
  exit 0
fi
printf '%s\\n' "$@" > '{self.calls}'
""")
        env = os.environ.copy()
        env["PATH"] = f"{self.fakebin}{os.pathsep}{env['PATH']}"
        return subprocess.run(
            [str(SCRIPT)], cwd=self.tmp, env=env,
            capture_output=True, text=True, timeout=10,
        )

    def test_main_checkout_is_available_when_extra_worktrees_exist(self):
        result = self.run_script("all")
        self.assertEqual(result.returncode, 0, result.stderr)
        options = (self.tmp / "worktree-options").read_text()
        self.assertIn(str(self.main), options)
        self.assertIn(str(self.feature), options)
        self.assertIn("repo-main\t", options)
        self.assertIn("repo-feature\t", options)
        calls = self.calls.read_text().splitlines()
        self.assertEqual(calls[:2], ["worktree", "open"])
        self.assertIn("--cwd", calls)
        self.assertIn(str(self.main.resolve()), calls)
        self.assertIn("--path", calls)
        self.assertIn("--focus", calls)
        self.assertIn("--json", calls)


if __name__ == "__main__":
    unittest.main()
