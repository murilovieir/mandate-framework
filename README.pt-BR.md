# Mandate Framework

> **Governança spec-driven para agentes de IA.** 🇺🇸 English: [README.md](README.md)

O Mandate é um framework pronto para clonar que dá a um agente de código (Claude Code como executor
principal; Codex/Copilot como revisores) um **mandato**: uma constituição lida em toda sessão,
decisões que ele não pode reabrir, um backlog executado story a story, uma pequena org virtual de
agentes com limites explícitos e guardrails determinísticos com um único comando de verificação que
roda igual localmente e no CI.

A regra de ouro é o próprio nome: **o agente age dentro do seu mandato; o que passa dele vira RFC, e
só o decisor amplia um mandato.**

## Os sete pilares — M.A.N.D.A.T.E.

| | Pilar | Neste repositório |
|---|---|---|
| **M** | **Markdown as source of truth** | escopo, ACs e decisões em markdown versionado; Issues espelham num sentido só |
| **A** | **Architecture by ADR** | `docs/rfc/` → `docs/adr/`, aprovadas pelo decisor; decisão travada não se reabre |
| **N** | **Named rules, enforced by script** | `RULE-*` com 🔒 no `CLAUDE.md`, `scripts/guardrails/` como hook + CI |
| **D** | **Decision Log** | `DECISIONS.md` — todo fork vira PD; default sensível nunca fecha em silêncio |
| **A** | **Agents with bounded mandates** | `.claude/agents/` — todo papel termina com os "limites do mandato" |
| **T** | **Tested before asserted** | RULE-QA-01 + `verify-all.sh`, a autoridade única de verificação |
| **E** | **Executable backlog** | Initiative → Unit of Work → Story, com gates de saída executáveis (`uow-gate.sh`) |

Guia do método — o *porquê* de cada arquivo: [`docs/reference/governance-template.pt-BR.md`](docs/reference/governance-template.pt-BR.md)
· [EN](docs/reference/governance-template.md). Agnóstico de stack, domínio e ferramenta.

> Os artefatos executáveis (`CLAUDE.md`-modelo, skills, agentes, scripts) estão em inglês, um único
> conjunto para manter. A documentação de método (este README e o template) existe nos dois idiomas.

## Início rápido

```bash
git clone https://github.com/murilovieir/mandate-framework meu-projeto && cd meu-projeto
rm -rf .git && git init -b main            # comece o seu próprio histórico
./scripts/init.sh                          # pergunta nome do projeto, decisor, fase… preenche todo {{PLACEHOLDER}}
git config core.hooksPath scripts/guardrails/git-hooks
./scripts/guardrails/verify-all.sh         # precisa terminar com "VERIFY-ALL: OK"
git add -A && git commit -m "chore: bootstrap governance" -m "Refs: T-001"
git branch develop
```

Depois, nesta ordem (template §18):

1. Preencha o `CLAUDE.md` §1–§2 e §6 — contexto, tabela de stack, fases. Escreva uma ADR por linha da
   stack (`docs/adr/README.md` tem o template).
2. Ajuste o `governance.env` — seus **domínios sensíveis** e **paths sensíveis**. É a única coisa que
   não dá para retrofitar depois que um default silencioso foi para produção.
3. Grave o orçamento de instruções: `./scripts/guardrails/instruction-budget.sh --record`.
4. Escreva seu primeiro guardrail de domínio para a sua primeira survival condition
   (`scripts/guardrails/README.md`).
5. Planeje a Unit of Work 01 (`docs/backlog/uow-01/_index.md`) e execute a primeira story:
   *"execute T-001"*.

## O que tem dentro

| Caminho | O quê |
|---|---|
| `CLAUDE.md` | Constituição (tier 1) — regras normativas com `{{PLACEHOLDER}}`s |
| `AGENTS.md` | Contrato para ferramentas revisoras |
| `DECISIONS.md` / `DECISIONS_ARCHIVE.md` | Decision Log (vivas + fechadas) com índice gerado |
| `governance.env` | Ajustes do projeto: domínios/paths sensíveis, arquivos do orçamento, branches, decisor |
| `docs/adr/`, `docs/rfc/` | Eixo de decisão: propostas → decisões travadas |
| `docs/initiatives/`, `docs/backlog/` | Eixo de entrega: Initiative → Unit of Work → User Story |
| `docs/reference/learned-rules.md` | Tier 2 — o *porquê* de cada regra (`LR-NNN`) |
| `docs/office/`, `docs/reports/` | Memória institucional dos agentes · relatórios datados + trilha de auditoria |
| `.claude/skills/` | `backlog-executor`, `decision-log`, `review-gate`, `analyze`, `next-tasks`, `decision-brief`, `review-task`, `branch-cleanup`, `agents-census` |
| `.claude/agents/` | `architect`, `product-owner`, `qa-engineer`, `release-manager`, `tpm`, `chief-of-staff` |
| `scripts/guardrails/` | `verify-all.sh` (a definição de verde) + guardrails + testes + git hooks |
| `scripts/planning/` | `decision-index.py`, `next-tasks.py`, `sync-github-issues.sh` |
| `scripts/promote-develop.sh` | `develop → main`, só fast-forward |
| `.github/` | `governance.yml` (o CI chama o `verify-all.sh` e nada mais), `CODEOWNERS`, template de PR |
| `docs/reference/mandate-vs-ai-dlc.pt-BR.md` | Como o Mandate se compara ao AI-DLC da AWS, e o modelo de PODs para vários times |
| `ROADMAP.pt-BR.md` | Como o framework evolui: autonomia conquistada, vários humanos + IAs em paralelo, CLI, operação |

## Princípios num fôlego

Markdown no repo é a fonte de verdade · toda story tem spec · um decisor aprova RFCs · todo fork vai
para o Decision Log · entrega e decisão são eixos separados · **regra sem script é desejo** — então
toda regra checável tem um, rodando como hook de aviso localmente e como check merge-blocking no CI, a
partir da mesma fonte.

## Requisitos

`bash`, `git`, `python3` (≥ 3.9, só biblioteca padrão), `jq` (para os hooks do Claude Code).
Opcional: `gh` para espelhar Issues.

## Autor

Criado e mantido por **Murilo Vieira** ([@murilovieir](https://github.com/murilovieir)).

O Mandate foi desenhado e evoluído usando-o todos os dias e transformando cada correção em regra — e,
sempre que possível, em script. O método cresceu nesta ordem:

1. Constituição lida pelo agente em toda sessão; stories spec-driven (Implementation Contract); ADRs como decisões travadas.
2. Fluxo de RFC gated pelo decisor — o agente propõe, nunca decide.
3. Vocabulário Spec-Driven Development; gate de consistência `/analyze`; espelhamento unidirecional em GitHub Issues.
4. Org virtual de agentes com mandato delimitado; Decision Log v2 (escalação de default sensível, ratificação em lote); escada de rigor N0–N3; fan-out paralelo.
5. *Executar antes de afirmar* — o review gate.
6. Guardrails determinísticos (hook + CI, uma fonte); conhecimento em dois níveis; dimensionamento *bolt*; evals de agente; status de decisão legível por máquina; `verify-all.sh` como autoridade única; fluxo em dois saltos; gates de prontidão para escala.
7. **Mandate Framework v1.0.0** — os sete pilares, empacotados como framework.

O que vem a seguir: [`ROADMAP.pt-BR.md`](ROADMAP.pt-BR.md). Contribuições: [`CONTRIBUTING.pt-BR.md`](CONTRIBUTING.pt-BR.md).

## Licença

[MIT](LICENSE) © 2026 Murilo Vieira. Projetos inicializados com `scripts/init.sh` mantêm uma cópia da
licença em `docs/guides/MANDATE_LICENSE`, o que cumpre a exigência de manter o aviso.

> O Mandate é um projeto independente. Não é afiliado, endossado nem patrocinado pela Anthropic
> (Claude Code), Amazon Web Services (AI-DLC), OpenAI (Codex) ou GitHub (Copilot); esses nomes aparecem
> só para descrever compatibilidade e comparação. No `.github/CODEOWNERS`, o `@{{DECIDER_GITHUB}}` é
> proposital: o `init.sh` substitui no seu projeto.
