# Security Policy

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this project, please report it privately by email rather than opening a public GitHub issue.

- **Email:** geeklin36@gmail.com
- **Preferred subject line format:** `[SECURITY] <short description>` (for example, `[SECURITY] install.sh privilege escalation`)

Please include a clear description of the issue, the affected component, steps to reproduce, and any proof-of-concept material you have. If the report is sensitive, you may request a PGP key in your first message.

## Supported Versions

Only the `0.1.x` release line is currently supported with security fixes. Older or forked versions will not receive patches; please upgrade to the latest `0.1.x` release before reporting.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | Yes                |
| < 0.1   | No                 |

## Scope

The following components are in scope for security reports:

- **`install.sh`** — the bash execution surface. Anything that allows unintended command execution, path traversal, or tampering with files outside the intended install target during installation.
- **Hook scripts** — these have access to the Claude Code transcript. Reports involving unintended transcript exfiltration, disclosure of transcript contents, or hook-driven command execution based on attacker-controlled transcript content are in scope.
- **Agent bodies (system prompts and instructions)** — the LLM prompt-injection surface. Reports involving injection paths that cause the shipped agents to leak data, bypass declared restrictions, or take unsafe actions on a user's machine are in scope.

## Out of Scope

The following are **not** covered by this policy:

- **Upstream Claude Code** — please report those to Anthropic directly.
- **Upstream MCP servers** — please report those to the maintainers of the individual server.
- **Third-party skills that users add** to their own `.claude/` directory. Skills authored outside this repository are the responsibility of their authors.

Denial-of-service against a user's own local machine via resource exhaustion in a locally-invoked script is generally out of scope unless it enables further compromise.

## Response Time

Reports are handled on a best-effort basis by a small maintainer team. We aim to acknowledge new reports within **72 hours** of receipt. Triage, fix development, and release timing depend on severity and complexity, and will be communicated in the acknowledgement thread.

## Disclosure

Disclosure is **coordinated with the reporter**. Once a fix is available, we will agree on a disclosure date and, where appropriate, credit the reporter in the release notes. Please do not publicly disclose the issue before a fix has been released and the coordinated date has been reached.
