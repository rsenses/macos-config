# Selective pstack adaptation

Source: [backnotprop/pstack](https://github.com/backnotprop/pstack), revision
[`f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37`](https://github.com/backnotprop/pstack/commit/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37).
GitHub's commit API identifies this revision; its `MIRROR.md` describes the repository
as a mirror of `cursor/plugins/pstack` with local README and harness-neutral edits.
This records the consulted mirror, not a claim that its files match Cursor upstream.
All source links below are pinned to that revision.

## Sources and local choices

- [in-your-own-words](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/in-your-own-words/SKILL.md)
  asks the agent to restate the user's goals and problem. Locally, ops section 6
  uses a short interpretation only for material ambiguity, including preserved
  behavior and open decisions; it adds neither a command nor an approval.
- [sharpen](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/sharpen/SKILL.md)
  deepens a task through professional practice, raw sources, methods/tools, and
  independent evidence, then rewrites it while leaving user choices open.
  Our manual prompt uses the existing ops brief, limits local discovery, separates
  optional improvements, and explicitly forbids implementation and planning.
- [blast-radius](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/blast-radius/SKILL.md)
  follows downstream effects and the fact on which safety depends, demanding real
  execution evidence and optionally multi-model review. The local `code-reviewer`
  adapts the affected-flow, relevant-consumer, and safety-guarantee lens within
  read-only tools. Checks needing execution are returned to the coordinator with
  confirming/refuting outcomes. The agent is exclusively manual: there is no
  pre-final-validation integration. Execution/arena instructions were not imported.
- [interrogate](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/interrogate/SKILL.md),
  especially [lead judgment](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/interrogate/references/lead-judgment.md)
  and the [reviewer prompt](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/skills/interrogate/references/reviewer-prompt.md),
  separates findings from automatic fixes and filters speculative concerns and
  preferences. Ops section 3 adapts that judgment to supported defects, pending
  hypotheses, optional improvements, and justified dismissals. No multi-model
  consensus, panel, fallback, or new review invocation is adopted. Local
  `laravel-simplicity` remains authoritative; single-consumer/class-count and
  file-size heuristics or broad restructuring pressure are not imported.

These are selective, locally rewritten instructions, not reproductions of the
original workflows. No pstack suite or agent, external permission policy, model
fallback, cache mechanism, automatic plan synchronization, application verification
skill, or evaluation platform is included. The local manual `code-reviewer` uses
Pi's existing launcher and its own explicitly configured model and read-only tools. poteto-mode, arena, no-comments, and external
autonomy/fallback rules are excluded.

## License of the consulted material

The source revision's [LICENSE](https://github.com/backnotprop/pstack/blob/f51fdeba3d803ef90e4eaa4a95ffb4e76008ab37/LICENSE)
is reproduced below for attribution and retention of its permission notice.

MIT License

Copyright (c) 2026 Lauren Tan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
