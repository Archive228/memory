# Contributing

## Welcome

This project is a memory pattern for Claude Code, not a framework. It is a small, opinionated set of files (skills, agents, install script) you drop into a `.claude/` directory to give long-running Claude sessions durable shift-notes and shared conventions. Contributions that keep it small and legible are welcome; contributions that turn it into a framework are not. If you are unsure which side of that line your idea sits on, open an issue before writing code.

## How to report a bug

Use the bug issue template: [.github/ISSUE_TEMPLATE/bug.md](.github/ISSUE_TEMPLATE/bug.md).

Every bug report must include:

- **Expected behavior** — what you thought would happen.
- **Actual behavior** — what actually happened, including exact error output.
- **Reproduction steps** — a numbered list starting from a clean clone. If we cannot reproduce, we cannot fix.
- **Environment** — OS + version, shell (bash/zsh + version), Claude Code version, and any relevant plugin versions.

Bugs without reproduction steps will be closed with a request for more information.

## How to propose a feature

Use the feature issue template: [.github/ISSUE_TEMPLATE/feature.md](.github/ISSUE_TEMPLATE/feature.md).

Before you write the proposal, run the scope check:

- Does this belong in the memory pattern, or is it a personal workflow that should live in your own `.claude/`?
- Would this force downstream users to learn a new abstraction?
- Can the same result be achieved by editing an existing skill?

If any of the first two are yes, or the third is yes, the feature probably does not belong here.

## Code style

- **Shell scripts** must be shellcheck-clean (`shellcheck -x install.sh`). CI runs this and blocks merges on failure.
- **POSIX-conservative where feasible.** Prefer `sh`-compatible constructs in `install.sh` so it runs on stock macOS and Linux without a bash upgrade. Bashisms are allowed in scripts that are explicitly shebang'd `#!/usr/bin/env bash`.
- **YAML frontmatter** is required at the top of every `SKILL.md` and `agent.md`. Minimum keys: `name`, `description`. See existing skills for the full schema.
- Two-space indentation in YAML. Tabs are a bug.
- No trailing whitespace. `.editorconfig` enforces this.

## Testing

There is no test framework — the tests are manual and boring on purpose:

1. Run `./install.sh` in a scratch directory (`mktemp -d`). Confirm it exits 0 and creates the expected `.claude/` tree.
2. Run `./install.sh` **again** in the same directory. It must be idempotent — no errors, no duplicated entries, no clobbered user edits.
3. Push your branch and wait for CI. CI runs shellcheck and the install-in-scratch-dir check. Do not merge until CI is green.

If you add a new skill, add a one-line smoke check to `test/smoke.sh` that confirms the skill loads.

## Attribution

If you lift a pattern, prompt, or non-trivial snippet from another repository:

- Add an entry to `NOTICE` describing what was borrowed and from where.
- Drop the upstream license file into `LICENSES/<project-name>.txt`.
- Link the upstream commit SHA in your PR description so reviewers can verify.

This is not optional. Attribution is how we keep the pattern shareable.

## PR checklist

Copy this into your PR description and tick each box before requesting review:

- [ ] `shellcheck` passes on all changed shell scripts.
- [ ] `./install.sh` is idempotent — running it twice in a scratch dir produces the same tree.
- [ ] `README.md` updated if the change is user-facing (new skill, new flag, changed default).
- [ ] `NOTICE` and `LICENSES/` updated if the change lifts anything from another repo.
- [ ] Frontmatter present on any new `SKILL.md` or `agent.md`.

## Communication

If your change is more than roughly 20 lines of diff, open an issue first and get a thumbs-up before you write the code. This is not gatekeeping — it is saving you from writing a PR we cannot merge because the direction is wrong. Small fixes (typos, shellcheck warnings, doc clarifications) can go straight to a PR.

For questions that are not bugs or features, use GitHub Discussions rather than opening an issue.
