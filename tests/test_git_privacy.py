"""Regression checks for the dotfiles repository's Git privacy boundaries.

Run: python3 -m unittest discover -s tests -p 'test_git_privacy.py'
Only synthetic paths are passed to check-ignore; no private file is read.
"""

import os
import shlex
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENV = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
ENV.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")


def ignored(cwd, paths, excludes=os.devnull):
    result = subprocess.run(
        ["git", "-c", f"core.excludesFile={excludes}", "check-ignore",
         "--no-index", "--stdin", "-z"],
        cwd=cwd, env=ENV, input="\0".join(paths) + "\0",
        text=True, capture_output=True,
    )
    if result.returncode not in (0, 1):
        raise AssertionError(result.stderr)
    return set(filter(None, result.stdout.split("\0")))


class RepositoryPrivacyTests(unittest.TestCase):
    def test_private_and_generated_paths_are_ignored(self):
        paths = [
            ".ai/TASKS.md", ".ai/plan/example.md", ".ai/audits/report.md",
            "intelephense/licence.txt", ".gitconfig.local", "git/.gitconfig.local",
            "project-databases.sql.gz", "database.sql", "database.dump",
            "zsh/.config/zsh/.zshvars", "zsh/.config/zsh/.env.local",
            "pi/.pi/new-runtime-file.json", "pi/.pi/agent/new-runtime-file.json",
            "pi/.pi/agent/models-store.json", "pi/.pi/agent/models.json",
            "pi/.pi/agent/auth.json", "pi/.pi/agent/trust.json",
            "pi/.pi/agent/mcp.json", "pi/.pi/agent/mcp-onboarding.json",
            "pi/.pi/agent/mcp-npx-cache.json", "pi/.pi/agent/mcp-cache.json",
            "pi/.pi/agent/sessions/example.jsonl",
            "pi/.pi/agent/usage-data/session-meta/example.json",
            "pi/.pi/agent/git/downloaded-package/index.ts",
            "pi/.pi/agent/npm/downloaded-package/index.ts",
            "pi/.agents/.skill-lock.json",
            "pi/.pi/agent/extensions/example/.env",
            "pi/.pi/agent/extensions/example/node_modules/index.js",
            "pi/.pi/agent/extensions/example/.cache/state.json",
            "pi/.pi/agent/extensions/example/session.json",
            "pi/.pi/agent/extensions/example/debug.log",
            "pi/.pi/agent/extensions/example/state.sqlite-wal",
            "pi/.pi/rules/lean-ctx.md.bak",
            "herdr/.config/herdr/plugins.json",
            "herdr/.config/herdr/release-notes.json",
            "herdr/.config/herdr/.plugins.lock",
            "herdr/.config/herdr/herdr.sock",
            "herdr/.config/herdr/new-runtime-file.json",
            "herdr/.config/herdr/plugins/github/example",
            "worktrunk/.config/worktrunk/approvals.toml",
            "worktrunk/.config/worktrunk/approvals.toml.lock",
            "worktrunk/.config/worktrunk/config.toml.lock",
            "worktrunk/.config/worktrunk/new-runtime-file.json",
        ]
        self.assertEqual(ignored(ROOT, paths), set(paths))

    def test_declarative_config_and_dependency_locks_remain_visible(self):
        paths = [
            ".gitignore", "git/.gitconfig", "git/.gitignore",
            "zsh/.zshrc", "tests/test_git_privacy.py", "docs/git-privacy.md",
            "nvim/.config/nvim/nvim-pack-lock.json",
            "pi/.pi/agent/settings.json", "pi/.pi/agent/APPEND_SYSTEM.md",
            "pi/.pi/agent/auto-compact.json", "pi/.pi/agent/lsp.json",
            "pi/.pi/agent/extensions/ask-user-question.ts",
            "pi/.pi/agent/extensions/pi-subagents/agents/scout.md",
            "pi/.pi/agent/extensions/web-fetch/package-lock.json",
            "pi/.pi/agent/prompts/plan.md", "pi/.pi/agent/themes/example.json",
            "pi/.pi/agent/skills/dev/SKILL.md", "pi/.agents/skills/dev/SKILL.md",
            "pi/.pi/rules/lean-ctx.md",
            "herdr/.config/herdr/config.toml",
            "herdr/.config/herdr/plugins/config/example/config.toml",
            "worktrunk/.config/worktrunk/config.toml",
            "example/.env.example", "example/.env.sample", "example/.env.template",
        ]
        self.assertEqual(ignored(ROOT, paths), set())

    def test_private_paths_are_not_tracked(self):
        result = subprocess.run(
            ["git", "ls-files", "-z"], cwd=ROOT, env=ENV,
            capture_output=True, text=True, check=True,
        )
        paths = list(filter(None, result.stdout.split("\0")))
        remaining = sorted(ignored(ROOT, paths))
        self.assertEqual(remaining, [], "Ignored paths still tracked: " + repr(remaining[:8]))


class GitConfigurationTests(unittest.TestCase):
    def get_config(self, key):
        return subprocess.run(
            ["git", "config", "--file", str(ROOT / "git/.gitconfig"), "--get", key],
            env=ENV, capture_output=True, text=True,
        )

    def test_machine_identifier_is_local_only(self):
        self.assertEqual(self.get_config("coderabbit.machineId").returncode, 1)
        self.assertEqual(self.get_config("include.path").stdout.strip(), "~/.gitconfig.local")

    def test_neovim_pager_receives_plain_git_output(self):
        pager = self.get_config("core.pager")
        self.assertEqual(pager.returncode, 0)
        self.assertEqual(
            shlex.split(pager.stdout.strip()),
            ["nvim", "-R", "-c", "setlocal filetype=git", "-"],
        )
        self.assertEqual(self.get_config("color.pager").stdout.strip(), "false")


class GlobalPrivacyTests(unittest.TestCase):
    def test_global_rules_protect_credentials_but_keep_examples(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-privacy-test-") as directory:
            subprocess.run(
                ["git", "-c", "init.templateDir=", "init", "-q", directory],
                env=ENV, check=True, capture_output=True,
            )
            private = [
                ".env", ".env.local", "nested/.env.production", ".zshvars",
                "auth.json", "credentials.json", ".gitconfig.local",
                "id_rsa", "nested/id_ed25519", "private.key", "identity.p12",
            ]
            examples = [
                ".env.example", ".env.sample", ".env.template",
                "nested/.env.example", "id_ed25519.pub", "package-lock.json",
                "migrations/schema.sql",
            ]
            self.assertEqual(
                ignored(directory, private + examples, ROOT / "git/.gitignore"),
                set(private),
            )


if __name__ == "__main__":
    unittest.main()
