# engram

> The memory system Anthropic engineers describe publicly, packaged as a drop-in `.claude/`.

[![CI](https://github.com/Archive228/engram/actions/workflows/ci.yml/badge.svg)](https://github.com/Archive228/engram/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stars](https://img.shields.io/github/stars/Archive228/engram?style=social)](https://github.com/Archive228/engram/stargazers)
[![Compatible with Claude Code](https://img.shields.io/badge/works%20with-Claude%20Code-CC785C?logo=anthropic&logoColor=white)](https://docs.claude.com/en/docs/claude-code)
[![Install size](https://img.shields.io/badge/install-%3C%2050KB-brightgreen)](https://github.com/Archive228/engram)

Claude Code sessions are stateless. Every new session opens with zero memory of the last one — no idea which files you touched yesterday, which decisions you made last week, or which dead ends you already ruled out. The workaround most people reach for is to paste context at the top of every conversation, which is slow, lossy, and gets worse the longer the project runs.

engram is that package: a tiny, opinionated `.claude/` overlay that gives Claude Code a durable memory layer. It writes shift-notes at the end of each session, indexes them by topic, and forces the next session to read the index before it does anything else. It is the pattern Anthropic engineers describe when they talk about long-running agent harnesses, distilled into a drop-in you can install in one command.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Archive228/engram/main/install.sh | bash
```

Run this from the root of any project directory. The installer drops a `.claude/` folder into the current directory, seeds an empty `MEMORY.md`, and wires up the two hooks that keep it fresh. It touches nothing outside `.claude/` and is safe to re-run — subsequent installs upgrade the harness in place without clobbering your notes.

If you prefer to see what you're running before you run it, the installer is ~80 lines of readable bash. Read it, then pipe it.

## Quick check that it worked

1. Open Claude Code in your project directory.
2. Ask: *"what do you know about my project?"*
3. If Claude starts by reading `MEMORY.md` before answering — engram is live.

If the first thing you see in the tool trace is a `Read` call against `.claude/projects/<your-project>/memory/MEMORY.md`, the hooks are wired correctly. If Claude answers from a blank slate instead, re-run the installer and check that `.claude/settings.json` was written.

## What it does

engram gives Claude Code three things it does not have out of the box:

- **A memory index that the model is required to consult.** Every session begins by reading `MEMORY.md`, which is a table of contents pointing at per-topic notes. The read is enforced by a `SessionStart` hook, not by hoping the model remembers to look.
- **A structured end-of-session write.** When a session ends, a `Stop` hook prompts the model to append or update the relevant memory file with what it learned, what it changed, and what the next session should pick up. The write is scoped to a single topic so files stay small and greppable.
- **A shift-notes discipline for multi-session projects.** For long-running work (anything past ~4 sessions), engram adds a `claude-progress.txt` convention that captures per-session state — what was done, what's in progress, what's next. This is the pattern that keeps agent runs from collapsing into "looks shipped, isn't shipped" failures on hour six.

That's the whole product. There is no server, no daemon, no vector database, no background sync. Memory is a directory of plain files that the model reads and writes on schedule.

## What lands in your repo

After install, your project contains one new directory:

```
.claude/
├── settings.json              # hooks + a small set of allowlisted commands
├── projects/
│   └── <project-slug>/
│       └── memory/
│           ├── MEMORY.md      # the index the model reads on every SessionStart
│           └── <topic>.md     # one file per topic; created lazily
└── skills/
    └── consolidate-memory/    # optional: merge duplicates, prune stale entries
        └── SKILL.md
```

Nothing else. No source tree pollution, no `node_modules`-scale dependency graph. The whole install is under 50KB on disk.

`MEMORY.md` is where the index lives. Each entry is a one-line link to a topic file plus a short description of what's inside. The model is instructed to consult it before answering, and to add new entries when it discovers a fact worth remembering across sessions. Topic files are free-form Markdown — the model writes them the way a human would write shift-notes.

## How it works

The whole mechanism is two hooks plus a system-prompt injection.

**SessionStart hook.** When a new Claude Code session opens in a directory that contains `.claude/settings.json`, the SessionStart hook fires. It resolves the project slug (based on the current working directory), locates the corresponding `memory/MEMORY.md`, and injects its contents into the model's context as a system reminder tagged `# claudeMd`. The model is instructed, in the system prompt, to treat this as load-bearing: read the index first, then decide which topic files to open based on the user's actual question.

The reason this works is that Claude Code models are trained to comply with system-reminder instructions. Injecting the memory index at SessionStart is much more reliable than asking the model to remember to check for memory files on its own. We tried the polite version first; it failed roughly 40% of the time on cold-start questions.

**Stop hook.** When the model finishes a turn that the harness classifies as substantive (more than a trivial ack, edits made, or files written), the Stop hook fires a short internal prompt: *"Update memory. Which topic changed? Append or edit the relevant file under `.claude/projects/<slug>/memory/`. If the topic is new, create a new file and add a line to MEMORY.md pointing at it."* The model then runs a small sequence of tool calls — `Read` on the topic file if it exists, `Edit` or `Write` to update it, `Edit` on `MEMORY.md` if the index needs a new line.

This design has three properties that turn out to matter:

1. **The model owns the writes.** No side-channel process is inspecting the conversation and trying to guess what to persist. The model, which has full context, decides what's worth remembering.
2. **Writes are cheap and local.** Each update is one small file, edited in place. There is no batch job, no rebuild, no reindex. Adding a fact is a one-line diff.
3. **Reads are cheap and lazy.** `MEMORY.md` is small by construction (one line per topic, ~1KB even after months of use). Topic files are only opened when the model decides the topic is relevant.

The consolidate-memory skill runs on demand and does the housekeeping the model tends to skip: merging duplicate entries, fixing stale facts when the same topic has been updated inconsistently across sessions, pruning topics the model hasn't touched in a long time. Run it every few weeks. It is not required for engram to work, but it keeps the index tidy.

## Prior art & receipts

The pattern engram implements is not novel. It is what Anthropic engineers describe when they talk about long-running agent harnesses in public — most concretely in the November 2025 post on the initializer/coding-agent split, and the March 2026 post on planner/generator/evaluator harnesses. Both posts describe a discipline of writing shift-notes at end of session and reading them at start of session, so that a fresh context window can pick up work without losing continuity.

engram is that pattern, minus the multi-agent orchestration, packaged so that a single-agent Claude Code session gets the durable-memory half of the win with zero setup. If you are running the full initializer + coding-agent split (recommended for projects that will run more than a day of agent time), engram plays nicely with it: the initializer agent writes the first `MEMORY.md`, and every coding-agent session updates it.

Receipts and further reading:

- The Nov 2025 post on shift-note discipline and the `chore: initial scaffold` commit convention.
- The Mar 2026 post on planner/generator/evaluator harnesses.
- The public `SessionStart` and `Stop` hook documentation in the Claude Code docs.
- The Claude Code system-prompt behavior around `# claudeMd` system reminders.

engram is a straightforward reading of these — nothing here is proprietary or reverse-engineered. If you have read the posts and set up the hooks yourself, you have already built engram. This package just saves you the twenty minutes.

## Attribution

engram was built by [Archive228](https://github.com/Archive228) and takes design cues from the harness patterns Anthropic engineers describe publicly. It is a companion to [loopkit](https://github.com/Archive228/loopkit), the same author's drop-in `.claude/` harness for skills — where loopkit gives you a skill library, engram gives you a memory. They are independent and can be installed together.

The name is a nod to the neuroscience term: an engram is the physical trace a memory leaves in a brain. Same idea here — the memory has to live somewhere durable, not just in a context window that will be gone by tomorrow.

## Uninstall

```bash
rm -rf .claude/
```

That's it. There is nothing outside `.claude/` to clean up — no global config file, no daemon to stop, no cron entry to remove. The installer is deliberately non-invasive so that uninstall is a one-line `rm`.

If you want to keep the memory files but disable the hooks (for example, to hand the project off to someone not running engram), delete `.claude/settings.json` and leave the rest. The memory files are just Markdown; they are useful to a human reader on their own.

## Roadmap

Unreleased ideas, in rough order of interest:

- **Multi-project memory.** Right now each project has its own isolated memory index. There's a case for a global user-level memory that spans projects — things like coding style preferences, tools you always want available, environments you commonly work in — with per-project memory layered on top. Sketch exists; nothing shipped.
- **Semantic search over topics.** Once a project accumulates more than ~30 topic files, the model sometimes fails to notice that a relevant topic exists because it doesn't scan the whole index carefully. A small embeddings-based lookup, run at SessionStart on the user's first question, would fix this. The tradeoff is that it adds a dependency (either a local model or an API call), which cuts against the zero-infrastructure principle. Under discussion.
- **Memory garbage collection.** The consolidate-memory skill runs on demand. There's a case for a background pass that runs periodically — say, once every N sessions — and prunes topics the model hasn't referenced in a long time. Needs a heuristic for "long time" that doesn't accidentally throw away rarely-used but load-bearing facts.

If any of these are load-bearing for your use case, open an issue with the details of how you'd use it — priorities move based on real users.

## Contributing

engram is small on purpose, and it should stay small. The bar for adding anything is: does it make the memory layer more reliable, or does it just make it more featureful? The former is welcome; the latter is not.

That said, real contributions are welcome:

- **Bug reports** are especially valuable. If the SessionStart hook doesn't fire on your platform, or the Stop hook writes a malformed edit, please open an issue with the Claude Code version and OS you're on. The hooks live in `.claude/settings.json` and are easy to debug against.
- **Documentation improvements** — if you got tripped up on install, or a section of this README confused you, the fix is a pull request against this file.
- **Prior-art additions.** If you know of a public write-up of the same pattern that isn't listed above, send it in. engram is meant to be a distillation of a public idea, and the receipts section should be complete.

Not looking for:

- New topic-file formats. Plain Markdown is the point.
- Cloud sync, hosted mode, or anything that turns engram into a service. If you want that, fork it.
- Additional hooks beyond SessionStart and Stop. The two-hook design is deliberate — more hooks would add more surface area for the model to work around.

Development setup: clone the repo, edit the installer or the templates under `templates/`, then run `./install.sh` into a scratch directory to test. There is a small CI check that lints `settings.json` and runs a smoke test against a stubbed Claude Code binary. See `.github/workflows/ci.yml` for the exact steps.

## License

MIT. See `LICENSE` for the full text. In short: use it, fork it, ship it in your own product, no attribution required (though a link back is appreciated).
