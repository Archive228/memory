# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-02

Initial release.

### Added
- Four-section `MEMORY.md` schema: What's done / In progress / What's next / Notes for next session.
- `consolidator` subagent for session-end memory merging and pruning.
- `dreamer` subagent for overnight abstraction promotion.
- `remember` skill: read persistent memory before touching code.
- `recall-graph` skill: entity + relation graph store for large projects.
- `SessionStart` hook: injects `MEMORY.md` at session open.
- `Stop` hook: fires the consolidator and warns on uncommitted memory changes.
- `PreCompact` hook: snapshots state before context compaction.
- `install.sh`: idempotent one-command bootstrap with `.claude/` backup.
- `dreaming.sh`: manual dreamer trigger plus a suggested crontab entry.
- Attribution to [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) (Apache-2.0), [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) (MIT), and [anthropics/skills](https://github.com/anthropics/skills) (concept).

[Unreleased]: https://github.com/Archive228/memory/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Archive228/memory/releases/tag/v0.1.0
