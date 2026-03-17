import type { Plugin } from "@opencode-ai/plugin";

const PROTECTED_BRANCHES = new Set(["main", "master", "develop", "production"]);

const CONVENTIONAL_COMMIT_REGEX =
  /^(feat|fix|refactor|chore|docs|test|build|ci|perf|revert)(\([a-z0-9._\-\/]+\))?!?: .+$/i;

function hasStagedChanges(lines: string[]) {
  return lines.some(
    (line) => line.length >= 1 && line[0] !== " " && line[0] !== "?",
  );
}

function hasUnstagedChanges(lines: string[]) {
  return lines.some((line) => line.length >= 2 && line[1] !== " ");
}

function extractCommitMessage(command: string): string | null {
  const match = command.match(
    /\bgit\s+commit\b.*?(?:-m|--message)\s+["']([^"']+)["']/,
  );
  return match?.[1]?.trim() ?? null;
}

export const ProtectGitPlugin: Plugin = async ({ $, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return;

      const command = String(output.args.command || "");
      const isCommit = /\bgit\s+commit\b/.test(command);
      const isPush = /\bgit\s+push\b/.test(command);

      if (!isCommit && !isPush) return;

      const branch = (
        await $`git -C ${worktree} branch --show-current`.text()
      ).trim();

      if (PROTECTED_BRANCHES.has(branch)) {
        throw new Error(
          `Bloqueado: intento de ${isCommit ? "commit" : "push"} en rama protegida "${branch}".`,
        );
      }

      if (isCommit) {
        const porcelain = (
          await $`git -C ${worktree} status --porcelain`.text()
        ).trim();
        const lines = porcelain ? porcelain.split("\n") : [];

        const staged = hasStagedChanges(lines);
        const unstaged = hasUnstagedChanges(lines);

        if (!staged) {
          throw new Error("Bloqueado: no hay cambios staged para commitear.");
        }

        if (staged && unstaged) {
          throw new Error(
            "Bloqueado: hay mezcla de cambios staged y unstaged. Ejecuta /checkpoint y separa el commit.",
          );
        }

        const message = extractCommitMessage(command);

        if (!message) {
          throw new Error(
            "Bloqueado: el commit debe incluir mensaje explícito en formato Conventional Commit.",
          );
        }

        if (!CONVENTIONAL_COMMIT_REGEX.test(message)) {
          throw new Error(
            `Bloqueado: el mensaje "${message}" no cumple Conventional Commits. Usa algo como "feat(auth): add login rate limiting".`,
          );
        }

        const changelogStatus = (
          await $`bash -lc 'git -C "${worktree}" diff --cached --name-only | grep "^changelogs/" || true'`.text()
        ).trim();

        if (!changelogStatus) {
          throw new Error(
            "Bloqueado: falta una entrada staged en changelogs/ para este commit.",
          );
        }
      }
    },
  };
};
