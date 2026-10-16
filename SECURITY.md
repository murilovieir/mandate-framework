# Security policy

Mandate is a governance framework: markdown, shell and Python scripts that run in **your** repository
and CI. A security issue here usually means a script that can be tricked into executing something it
shouldn't (for example a guardrail, `verify-all.sh`, `init.sh` or `decision-index.py`), leaking data,
or silently passing a check it should fail ("fail-open").

## Reporting a vulnerability

**Please do not open a public issue.** Use GitHub's private vulnerability reporting:
**Security → Report a vulnerability** on this repository.

Include what you can: the affected file and version, a minimal reproduction, and the impact you see.
You'll get an acknowledgement as soon as possible; fixes are released as a patch version and noted
in the CHANGELOG.

## Supported versions

Only the latest released version receives security fixes.

## Scope notes

- `Reopen-trigger: cmd: …` entries in `DECISIONS.md` are executed by `decision-index.py` by design —
  they are repository content with the same trust as your scripts. Review them like code.
- Guardrails must **fail closed**: a check that cannot run reports `not verified` and fails. A path
  where a check reports OK without having checked is a bug worth reporting.
