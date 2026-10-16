# Contributing to Mandate

> 🇧🇷 Português: [CONTRIBUTING.pt-BR.md](CONTRIBUTING.pt-BR.md)

Thanks for considering a contribution. Mandate governs itself with Mandate, so contributing here is
also a quick tour of the method.

## Before you start

- **Bugs and small fixes** — open an issue (or go straight to a PR for typos).
- **New rules, skills, agents or changes to the method** — open an issue first. The decider (the
  maintainer) approves changes to the method, just as `docs/rfc/` describes for any project.
- **Roadmap items** — pick an `MF-NNN` from [`ROADMAP.md`](ROADMAP.md) and say in the issue that you're
  taking it, so two people don't build the same thing.

## How to send a change

1. Fork, then branch from `develop`: `feat/MF-NNN-short-slug` (or `fix/…`, `docs/…`).
2. Install the hooks once: `git config core.hooksPath scripts/guardrails/git-hooks`.
3. Every commit ends with a footer that references the work: `Refs: MF-NNN` (a roadmap story) or
   `Refs: RFC-NNN`. The `commit-msg` hook enforces it.
4. Run the single verification command — it is exactly what CI runs:
   ```bash
   ./scripts/guardrails/verify-all.sh
   ```
   A check that couldn't run prints `not verified` and fails. Don't hide it; say why in the PR.
5. Open the PR against **`develop`**, never `main`. `main` only moves by fast-forward through
   `scripts/promote-develop.sh`.

## What a good change looks like

- **A new rule ships with its script and its test.** Pillar **N**: a rule without a script is a wish.
  Every guardrail has a test proving one passing and one failing case.
- **Stack-, domain- and tool-agnostic.** Nothing that only makes sense for one language, cloud or
  business domain. Project specifics belong in `governance.env` or in the adopter's own files.
- **Bilingual docs stay in sync.** Method docs exist in EN (canonical) and PT-BR; change both, keeping
  numbered headings identical. Executable artifacts (skills, agents, scripts) are EN only.
- **Small.** One story per PR, sized like RULE-TASK-01 (≤ 5 acceptance criteria, ≤ 8 files).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
