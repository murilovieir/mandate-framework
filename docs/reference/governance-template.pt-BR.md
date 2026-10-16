# Mandate — Governança Spec-Driven para Agentes de IA

*Guia do método do **Mandate Framework** (antes "Governança de Projeto Assistida por IA — Template de Bootstrap").*

Criado por **Murilo Vieira** (@murilovieir).

> 🇺🇸 English version (canônica): [`governance-template.md`](governance-template.md).
> Este arquivo é espelho; em divergência, a versão em inglês prevalece.

> **Propósito.** Template autocontido e agnóstico de stack para reproduzir, num projeto novo, uma
> organização de engenharia spec-driven e assistida por IA: a constituição lida pelo agente de código,
> conhecimento em dois níveis, Architecture Decision Records (ADRs), propostas de decisão (RFCs), um
> Decision Log, um backlog executável (Initiative → Unit of Work → User Story), skills de agente,
> guardrails determinísticos com uma autoridade única de verificação, uma escada de rigor, uma org
> virtual de agentes por papel, espelhamento em issue tracker, fluxo de branches em dois saltos, evals
> de agente e um módulo opcional de prontidão para escala.
>
> **Como usar.** O caminho mais rápido é o framework executável — **Mandate** (`mandate-framework`) — um
> repositório que já materializa todos os artefatos abaixo, com `{{PLACEHOLDER}}`s e um bootstrap
> `scripts/init.sh`. Clone, rode o bootstrap e use este documento como o *porquê* de cada arquivo. Para
> montar à mão: copie este arquivo para o repositório novo, substitua cada `{PLACEHOLDER}`, apague as
> seções que não for adotar e materialize cada artefato como descrito. Nada aqui assume linguagem,
> framework, nuvem ou domínio de negócio específicos.
>
> **Changelog.**
> **v2.0** — Vocabulário convergido com o AI-DLC: `Tide`→`Initiative`, `Wave`→`Unit of Work`,
> task = *User Story* (§7). Novo: conhecimento em dois níveis e orçamento de instruções (§3); status de
> decisão legível por máquina (§4–§5); gatilhos de reverificação estruturados, `Scope` e ratificação por
> papel no Decision Log (§6); stories e Units of Work no tamanho de um *bolt*, gates de saída executáveis
> (§7); a fase `Operation` como slot registrado (§8); a escada de rigor e "executar antes de afirmar"
> (§9); quatro skills novas (§10); fluxo de branches em dois saltos (§11); guardrails determinísticos com
> autoridade única de verificação (§12); review automático de PR com fallback obrigatório (§13); evals de
> agente (§14.4); trilha de auditoria (§15); módulo de prontidão para escala — cinco gates de handoff,
> `CODEOWNERS`, federação de ratificação (§16). A §13 que faltava na v1.x acabou: numeração contínua.
> **v1.1** — Decision Log (`DECISIONS.md`) e a org virtual. **v1.0** — primeira versão.

### Os sete pilares — M.A.N.D.A.T.E.

| | Pilar | Onde |
|---|---|---|
| **M** | **Markdown as source of truth** — escopo, ACs e decisões em markdown versionado; trackers são espelho | §1, §11 |
| **A** | **Architecture by ADR** — RFC → ADR aprovada pelo decisor; decisão travada não se reabre | §4, §5 |
| **N** | **Named rules, enforced by script** — `RULE-*` com 🔒, guardrails como hook + CI | §3, §12 |
| **D** | **Decision Log** — todo fork vira PD; default sensível nunca fecha em silêncio | §6 |
| **A** | **Agents with bounded mandates** — org virtual em que todo papel tem limites explícitos | §14 |
| **T** | **Tested before asserted** — nenhuma AC sem execução que a prove; uma autoridade de verificação | §9, §12 |
| **E** | **Executable backlog** — Initiative → Unit of Work → Story, com gates de saída executáveis | §7, §16 |

O nome é a regra de ouro do método: o executor age **dentro do seu mandato**; o que passa dele vira
RFC, e só o decisor amplia um mandato.

---

## 1. Filosofia — os seis princípios

1. **Markdown no repositório é a fonte de verdade.** Escopo, critérios de aceite, decisões de
   arquitetura e regras de negócio vivem em markdown versionado — diffável, auditável por PR. Issue
   trackers, boards e binários exportados são *espelhos ou exports*, nunca canônicos.
2. **Spec-Driven Development (SDD).** O agente nunca implementa por intuição: toda story tem spec
   escrita (contexto, escopo IN/OUT, critérios de aceite) referenciando decisões travadas. O trabalho
   dele é executar o contrato, não reabri-lo.
3. **Governança de decisor único.** Uma pessoa (o *decisor* — founder, tech lead, dono) aprova ou
   rejeita toda proposta arquitetural. Propostas são RFCs; aprovadas, viram ADRs. Não há rodada de
   comitê — "RFC" fica só por ser o nome padrão de mercado (semântica mais próxima do RFD da Oxide ou do
   Pitch do Shape Up). A §16 mostra como federar isso depois sem migrar nada.
4. **Decisões nunca se perdem no contexto.** Todo fork descoberto durante a implementação vai para o
   Decision Log (`DECISIONS.md`) — nunca só num arquivo de task, num comentário de código ou no
   histórico do chat. Agentes recomendam; o decisor decide (semântica RAPID).
5. **Dois eixos de governança ortogonais.** *Entrega* (o que construir, quando) e *decisão* (o que foi
   decidido, por quê) são independentes. Uma ADR atravessa várias Units of Work; uma Unit of Work
   referencia várias ADRs. Nunca funda os dois numa hierarquia só.
6. **Regra sem script é desejo.** Toda regra que *pode* ser checada mecanicamente ganha um guardrail
   executável que roda como hook local e como check de CI merge-blocking, a partir de uma fonte só
   (§12). Prosa fica reservada ao que de fato exige julgamento. Corolário: *formato sem consumidor
   apodrece* — todo campo estruturado novo precisa de um script que o leia.

```
EIXO ENTREGA                                 EIXO DECISÃO (governança)
"o que construir / quando"                   "o que decidir / por quê"

  Initiative (INI-NNN) ← topo, opcional        Proposta (RFC-NNN)
        ↓                                            ↓  decisor aprova
  Unit of Work   (= Epic)                       ADR-NNN (accepted)
        ↓                                            └─ referenciada por stories/UoWs
  User Story T-NNN (= Story)                            (atravessa várias UoWs)
        ↓
  Acceptance Criteria (= sub-tarefas)

EIXO TEMPO:  Decisão (RFC→ADR)  →  Build (Initiative→UoW→Story)  →  Operation (§8, slot com gatilho)
```

---

## 2. Layout do repositório para artefatos de governança

```
{raiz-do-repo}/
├── CLAUDE.md                       # Constituição, tier 1 — só imperativo normativo (§3)
├── AGENTS.md                       # Contrato para ferramentas secundárias (papel de revisor, §14.2)
├── DECISIONS.md                    # Decision Log — decisões vivas + índice gerado (§6)
├── DECISIONS_ARCHIVE.md            # Decisões fechadas — guardadas para sempre
├── .claude/
│   ├── settings.json               # Hooks locais que rodam os guardrails em modo aviso (§12)
│   ├── agents/                     # Org virtual — um papel por arquivo (§14.1)
│   ├── skills/                     # Os processos que os papéis executam (§10)
│   └── evals/                      # Evals mutation-style de invariantes do agente (§14.4)
├── .github/
│   ├── CODEOWNERS                  # Mapa path → dono, antes de haver a quem atribuir (§16)
│   ├── pull_request_template.md
│   └── workflows/governance.yml    # O CI chama a autoridade de verificação — e só ela (§12)
├── scripts/
│   ├── guardrails/                 # Regras determinísticas: hook + CI de uma fonte só (§12)
│   │   ├── verify-all.sh           #   A definição de "verde" — neutra de runtime
│   │   ├── git-hooks/commit-msg    #   hook nativo do git (o PreToolUse nunca vê `git commit`)
│   │   ├── allowlists/             #   exceções explícitas e comentadas
│   │   └── tests/                  #   um teste por guardrail, golden + mutated
│   ├── planning/                   # decision-index.py, next-tasks.py, sync-github-issues.sh
│   └── promote-develop.sh          # develop → main, só fast-forward (§11)
├── docs/
│   ├── adr/                        # 1 arquivo por ADR (MADR) + índice README.md (§4)
│   ├── rfc/                        # Propostas aguardando o decisor + README.md (§5)
│   ├── initiatives/                # Camada opcional de resultado de negócio (§7)
│   ├── backlog/                    # README.md, TEMPLATE.md, pastas uow-NN/ (§7)
│   ├── office/{papel}/             # Memória institucional da org virtual (§14.1)
│   ├── reference/
│   │   ├── learned-rules.md        # Tier 2 — o *porquê* de cada regra, LR-NNN (§3)
│   │   └── ai-dlc-rosetta.md       # Equivalência de vocabulário (§8)
│   ├── reports/                    # Relatórios datados somente-leitura + process-metrics.jsonl (§15)
│   ├── design/                     # Opcional — artefatos do especialista de design (§14.3)
│   ├── guides/                     # How-tos (setup de dev, runbooks)
│   └── versions/                   # Plano de negócios corrente + archive/ de snapshots (§17)
└── {área}/CLAUDE.md                # Constituições por área, opcionais (backend/, frontend/, …)
```

Nomenclatura — sequencial e global salvo indicação, **nunca reutilizar**:

| Prefixo | Artefato | Onde vive |
|---|---|---|
| `ADR-NNN` | Decisão de arquitetura travada | `docs/adr/ADR-NNN-slug.md` |
| `RFC-NNN` | Proposta de decisão (gated pelo decisor) | `docs/rfc/RFC-NNN-slug.md` |
| `T-NNN` | User Story (unidade executável) | `docs/backlog/uow-NN/T-NNN-slug.md` |
| `UOW-NN` / `uow-NN` | Unit of Work | `docs/backlog/uow-NN/_index.md` |
| `INI-NNN` | Initiative — resultado de negócio (opcional) | `docs/initiatives/INI-NNN-slug.md` |
| `PD-{escopo}-NN` | Project Decision (§6) | `DECISIONS.md` / `DECISIONS_ARCHIVE.md` |
| `LR-NNN` | Regra aprendida — o *porquê* de uma correção (§3) | `docs/reference/learned-rules.md` |
| `DD-NNN` | Decisão de design (opcional) | `docs/design/DESIGN_DECISIONS.md` |
| `BLOCKER-NNN` | Bloqueio externo duro (não é fork) | tabela condicional de `docs/backlog/README.md` |
| `RULE-{ÁREA}-NN` | Regra nomeada e grepável da constituição | `CLAUDE.md` |

> **Confira unicidade em todas as branches, não só na atual** (`git ls-tree` sobre todas as branches
> remotas) antes de cunhar qualquer ID. Uma spec que só existe numa branch não mergeada é invisível de
> onde você está.

---

## 3. A Constituição — `CLAUDE.md` — e conhecimento em dois níveis

O `CLAUDE.md` da raiz é lido automaticamente no início de toda sessão. É a **constituição de
processo**: em conflito de processo, prevalece sobre tudo; em conflito de arquitetura, as ADRs
prevalecem.

### 3.1 Conhecimento em dois níveis (two-tier knowledge)

Toda correção de comportamento do agente costuma chegar com a história do incidente junto ("naquele
dia o revisor executou uma skill somente-leitura, então…"). Deixadas inline, essas histórias
fazem a constituição crescer sem limite e diluem os imperativos. Separe:

| Tier | Arquivo | Contém | Carregado |
|---|---|---|---|
| **1** | `CLAUDE.md`, `AGENTS.md`, `{área}/CLAUDE.md` | **O quê** — só imperativo normativo | toda sessão |
| **2** | `docs/reference/learned-rules.md` | **Por quê** — uma entrada `LR-NNN` por correção | sob demanda, pelas skills que precisam |

Formato da entrada tier 2: `LR-NNN · gatilho observável → regra · origem (T-NNN/RFC-NNN/incidente) ·
data`, mais uma tabela-índice `LR-NNN → regra que sustenta → skill que carrega`. O tier 1 cita o id
(`→ LR-006`) em vez de contar a história. O tier 2 é markdown puro, sem mecânica de ferramenta, para
que qualquer runtime de agente consiga lê-lo.

### 3.2 Orçamento de instruções

Meça os arquivos normativos (linhas não-brancas) e mantenha um **ratchet descendente** por arquivo
numa allowlist: `<arquivo> <teto> <alvo>`. O guardrail (`instruction-budget.sh`) reprova o CI quando
um arquivo passa do teto; `--record` só pode **baixar** o teto, nunca subir — subir exige edição manual
citando uma PD. O *alvo* é decisão do decisor, nunca medição; a distância teto↔alvo aparece em toda
execução. Sem a regra "só desce", o mecanismo acaba *registrando* o crescimento em vez de contê-lo.

### 3.3 Esqueleto de seções

```markdown
# {Projeto} — Guia de Colaboração com IA
> Tier 1 — só normativo. O porquê de cada regra vive em docs/reference/learned-rules.md (LR-NNN).

## 0. Uso multi-agente
   Executor principal; ferramentas revisoras (→ AGENTS.md, implementam só sob pedido explícito);
   RULE-REVIEW-01 — review automático de PR e seu fallback obrigatório (§13 do template).
## 1. Contexto do projeto — um parágrafo, links para o plano, índice de ADRs, versão, fase.
## 2. Stack — NÃO NEGOCIÁVEL
   Tabela: camada | decisão | ADR | alternativas proibidas.
   Regra de ouro: tecnologia fora da tabela e sem ADR → sinalizar a lacuna, propor RFC.
## 2-B..2-x. Blocos de regra de domínio — RULE-{ÁREA}-NN, cada um com Correto:/Proibido: e, quando um
   script a aplica, um marcador 🔒 apontando para scripts/guardrails/<regra>.sh.
## 3. Estrutura do repositório — uma linha + link para docs/reference/repo-structure.md.
## 4. Tipos canônicos / convenções centrais — link para o CLAUDE.md da área; só regras SEMPRE-válidas.
## 5. Fluxo — RFC vs. implementação direta; mapa SDD; os dois eixos; RULE-TASK-01 / RULE-UOW-01;
   o slot da fase Operation e seu gatilho de ativação.
## 6. Fases do produto — EM ESCOPO / EM ESCOPO sem prioridade / BACKLOG (não implementar nem sugerir).
## 7. Qualidade de código — legenda do 🔒; regras por linguagem; RULE-QA-01 (executar antes de
   afirmar); RULE-QA-02 (achado de review vira registro); survival conditions.
## 8. Guardrails de negócio — o que é existencial (billing, pricing); "nunca mudar sem aprovação".
## 9–10. Links de referência — dev local, dados de mercado → docs/reference/*.
## 11. Issue tracker e branches — RULE-PM-01..05 (§11 do template).
## 12. O que NUNCA fazer — lista ❌ plana; 🔒 onde um script aplica.
## 13. Versionamento de documentação (§17 do template).
*Conflito → este arquivo vence em processo; docs/adr/ vence em arquitetura.*
```

**Constituições por área** (`backend/CLAUDE.md`, `frontend/CLAUDE.md`) guardam convenções que só
importam dentro da área; carregam automaticamente quando o agente trabalha ali e contam no orçamento
de instruções.

**A convenção 🔒.** Quando uma regra tem script, a constituição diz isso e o script vira a autoridade:
*"🔒 = aplicado por `scripts/guardrails/`. O script é a autoridade; este texto é o índice."* Isso diz a
todo leitor quais regras são checadas e quais ainda dependem de atenção.

---

## 4. ADRs — Architecture Decision Records (`docs/adr/`)

- **Um arquivo por ADR**, estilo MADR, `ADR-NNN-slug.md`; `docs/adr/README.md` é o índice por domínio.
- ADRs são **referências imutáveis**: o agente nunca reabre decisão travada. Evolução = editar in-place
  com nota de versão, ou uma ADR nova que supersede a antiga.
- ADRs novas **nunca são criadas direto pelo agente** — sempre via RFC antes.

**Status legível por máquina (vocabulário fechado).** Ponha o estado em front matter YAML com
vocabulário fixo, para que scripts não precisem de caso especial por grafia:

```yaml
---
id: ADR-NNN
status: proposed | refining | accepted | deprecated | superseded | rejected
superseded_by: ADR-MMM        # só quando status = superseded
date: YYYY-MM-DD
domain: {ex.: cache / security / billing}
---
```

Um guardrail de consistência (`decision-status-consistency.sh`) checa se front matter, corpo e índice
do README **concordam** — checa coerência entre registros, nunca o mérito da decisão. Faça-o
**fail-closed**: crash ou varredura vazia é erro, nunca "OK". Modos de falha que ele pega: corpo
e índice certos mas o campo desatualizado; valor fora do vocabulário; "pendente" escrito de cinco
jeitos em dois idiomas; ADR listada duas vezes no índice com status diferentes.

```markdown
# ADR-NNN — {Título curto da decisão}
## Context      {por que é preciso decidir — restrições, SLAs, licença, precedentes}
## Decision     {afirmativa; tabelas para contratos-chave são bem-vindas}
## Consequences {o que vira proibido/obrigatório, follow-ups, dívidas, refs a ADRs/PDs}
```

---

## 5. RFCs — propostas de decisão (`docs/rfc/`)

Uma RFC é uma **proposta que o decisor aprova ou rejeita**, não uma rodada aberta de comentários. O
agente escreve uma sempre que o trabalho entra em território sem ADR, e **não implementa nada até um
GO explícito**.

1. O agente identifica uma decisão fora do escopo de implementação direta (§3.3 bloco 5: dependência
   nova, ADR nova necessária, mudança de comportamento de SLA/billing/segurança, API pública, modelo de
   negócio).
2. Escreve `docs/rfc/RFC-NNN-slug.md` e para.
3. O decisor registra a decisão **tanto** no front matter **quanto** no bloco `## Status`.
4. Aprovada → promovida a (ou incorporada em) uma ADR e decomposta em stories; a RFC fica como registro.

```markdown
---
id: RFC-NNN
title: {título curto}
status: awaiting | approved | rejected | superseded | partially-approved
---
# RFC-NNN — {Título curto}
**Data** · **Área** · **Impacto** baixo/médio/alto · **ADR relacionada** (ou "nova ADR necessária")
## Problema identificado
## Solução proposta
## Alternativas consideradas
## Trade-offs
## Estimativa de esforço
## Decomposição proposta   {stories por fase, cada uma com branch/PR/CI própria}
## Status
- [ ] Aguardando aprovação
- [ ] Aprovado — implementar (decisor, AAAA-MM-DD)
- [ ] Rejeitado — motivo: ___
```

> **Armadilha de leitura.** O bloco `## Status` lista a opção *não marcada* primeiro. Um `grep -A2` lê
> "Aguardando aprovação" e perde a linha marcada logo abaixo — leia até o próximo heading, ou melhor,
> leia o front matter. Esse erro transforma itens decididos em falsos achados de "pendente".

**Errata em vez de silêncio.** Quando o review acha defeito numa RFC já escrita, corrija o corpo e
acrescente uma tabela `## Errata` (achado · veredito · correção) em vez de reescrever a história em
silêncio.

---

## 6. Decision Log — `DECISIONS.md`

O registro das **decisões emergentes** — os forks que aparecem quando o código encontra a realidade,
*dentro* de escopo aprovado. Funcionalidade/tecnologia nova vai para RFC; decisões travadas vivem em
ADRs. Equivalente de mercado: Decision Log / Decision Register (PMBOK/PRINCE2); recomendar↔ratificar
segue a semântica RAPID.

> **Lição de nome.** Não chame de `PENDING_DECISIONS.md`: com o tempo quase toda entrada está fechada,
> e a trilha de auditoria fechada é o valor real do artefato. Chame de `DECISIONS.md` desde o primeiro
> dia; leia `PD-` como **"Project Decision"**.

| Artefato | Quando |
|---|---|
| `DECISIONS.md` | Fork durante a implementação — escolha entre alternativas viáveis dentro do escopo |
| `docs/rfc/` | Funcionalidade nova, tecnologia nova, mudança arquitetural que exige aprovação |
| `docs/adr/` | Decisão travada — nunca reabrir |
| "Notas de execução" da story | Achados de review (§9 RULE-QA-02) — não são decisões |

**Registre quando:** afeta mais de um módulo/story; escolhe entre ≥2 alternativas viáveis; impacta
modelo de dados, contrato de API, segurança ou infraestrutura; é um item "default proposto"/"em aberto"
numa spec; ou surpreenderia outro dev se achado enterrado.

**Status:** `OPEN` · `NEEDS_VALIDATION` · `DEFAULT_APPLIED` · `DEFERRED` ·
`RESOLVED (quem, AAAA-MM-DD)` · `BLOCKER_RESOLVED`.

**IDs semânticos com escopo** (passadas ~20–30 entradas): `PD-T{story}-NN` (fork dentro de uma story —
o caso dominante), `PD-RFC{rfc}-NN` (fork ao decompor uma RFC), `PD-{TEMA}-NN` (assunto transversal),
`PD-T{story}-RESCOPE`, `PD-{TEMA}-TRIAGE`. Grepáveis de volta à origem. Confira unicidade **nos dois
arquivos e em todas as branches**.

### 6.1 Formato da entrada (v3)

```markdown
## PD-{escopo}-{NN} — {título curto}

- **Status:** `OPEN` | `NEEDS_VALIDATION` | `DEFAULT_APPLIED` | `DEFERRED` | `RESOLVED (quem, AAAA-MM-DD)`
- **Impact:** `architectural` | `operational` | `business`
- **Proposed-by:** {papel que recomendou: architect | product-owner | sessão-principal | decisor | …}
- **Reversibility:** `two-way` | `one-way`
- **Sensitivity:** `internal` | {seus domínios sensíveis, ex.: `tenant-isolation` | `security` |
  `billing` | `privacy` | `public-api` | `schema`}
- **Scope:** `local` | `org`                         ← v3 (§16 F4)
- **Ratified-by:** — | decisor (AAAA-MM-DD, digest | direto | auto, decurso) | owner:{área} (AAAA-MM-DD)
- **Story(s):** T-NNN · **ADR(s):** ADR-NNN
- **Context:** {1–2 frases}
- **Alternatives:**
  - A: {opção} — {trade-off}
  - B: {opção} — {trade-off}
- **Proposed default:** {qual e por quê}
- **Reopen-trigger:** {condição verificável — ver 6.3} _(quando DEFERRED)_
- **Resolved:** {data} — {decisão final + justificativa}
```

`Proposed-by`/`Ratified-by` separam quem recomendou de quem ratificou; `Reversibility` é a porta de mão
única/dupla do Bezos; `Scope` diz se a decisão prende outros times; `Ratified-by` aceitar um **papel**
(`owner:billing`) é o que transforma federação em configuração em vez de migração. Ao adotar uma versão
nova do template num registro existente: defina uma **data de corte** e nunca reprocesse as antigas.

### 6.2 Comportamento do agente (aplicado pela skill `decision-log`)

1. **Antes de uma story** — varra a spec por decisões embutidas ("decidir", "default proposto", "TBD",
   "decisões em aberto"); registre cada uma, com referência cruzada de volta.
2. **Antes de agir sobre uma PD existente — reconfira as premissas contra o código**, não contra a
   prosa. Afirma que algo não existe? grep. Afirma que uma dependência não está pronta? leia o status.
   Premissa vencida é corrigida na PD, no mesmo commit, com evidência. (Não tente detectar premissa
   vencida com heurística de texto sobre a prosa da PD — dá quase só falso-positivo; as premissas que
   importam só são refutáveis lendo o código.)
3. **Durante a implementação** — em qualquer fork: PARE, registre com `Proposed-by`, `Reversibility`,
   `Sensitivity` e `Scope`.
   - **Escalação de default sensível (inegociável):** default em domínio sensível **nunca** fecha como
     `DEFAULT_APPLIED`. Marque `NEEDS_VALIDATION` e leve ao decisor antes de seguir.
   - Operacional (`internal`, two-way, sem impacto cruzado): aplique o default, marque
     `DEFAULT_APPLIED`, anote na story; entra na fila de ratificação e não bloqueia nada.
4. **Na resolução** — `RESOLVED (quem, data)`, preencha `Resolved:`, ligue a ADR, mova o bloco para o
   archive, regenere o índice.

### 6.3 Premissas verificáveis vão em campo estruturado, nunca em prosa

`Reopen-trigger:` funciona porque um script o lê. Premissa enterrada na prosa do `Context:` não é
alcançada por nada — nem script, nem leitura casual. Ao escrever um gatilho:

- **Prefira condição de dado a status de story.** "T-NNN done" dispara vazio quando a story mergeou mas
  o dado nunca existiu; escreva o que precisa ser verdade ("≥30 observações por rota, janela ≥14 dias").
- Cite `T-NNN` **quando o gatilho for de fato status de story** — é isso que o torna mecânico.
- Premissa sobre código? Nomeie o arquivo/símbolo.
- **Garanta que algo resolva o campo** (§16 F5): gatilho que o script de índice nunca avalia — ou que o
  caminho de CI pula — é prosa fantasiada de campo estruturado.

### 6.4 Cadência de ratificação

`DEFAULT_APPLIED` fecha o loop de implementação, não o de governança. Semanalmente o decisor recebe um
**digest** dos defaults novos — uma tabela, ratificada em lote (~5 min), registrada em `Ratified-by`.
**Regra de decurso de prazo** (opcional): defaults de baixo risco (`internal`) sem objeção por 14 dias
são ratificados por decurso — registrado como `Ratified-by: decisor (auto, decurso, AAAA-MM-DD)`.
**Defaults sensíveis nunca são elegíveis.** Racional: baixo risco nunca compete por atenção com itens
sensíveis, então sem decurso a fila de baixo risco é sinalizada para sempre.

### 6.5 Índice gerado e gate duro

Mantenha o índice entre os marcadores `<!-- DECISION-INDEX:BEGIN -->`/`END`, **regenerado por script**
(`scripts/planning/decision-index.py [--check]`), nunca à mão (índice mantido à mão diverge: a contagem
do cabeçalho, as linhas do índice e os corpos reais acabam discordando). O script reporta duplicatas entre arquivos, PDs fechadas no arquivo de
vivas, status ausente, defaults sensíveis não ratificados e `Reopen-trigger`s disparados — e aplica um
**gate duro**: PD sensível fechada como `DEFAULT_APPLIED` sem ratificação **reprova o script** nos dois
modos. `--check` roda no CI (§12).

**Anti-padrões:** decisão só numa story/comentário/chat; default sensível fechado em silêncio; decisão
do decisor registrada como `DEFAULT_APPLIED`; índice editado à mão; ID cunhado sem checar os dois
arquivos e todas as branches; agir sobre PD antiga confiando na prosa; premissa reverificável em prosa;
confundir PD com RFC, com questão aberta interna de uma ADR, ou com `BLOCKER-NNN` (bloqueio externo
duro, sem nada entre o que escolher).

---

## 7. Backlog — Initiatives, Units of Work, User Stories

### 7.1 Hierarquia

`Initiative → Unit of Work (= Epic) → User Story T-NNN (= Story) → Acceptance Criteria`

- **Unit of Work** (`docs/backlog/uow-NN/_index.md`) — incremento de entrega com **gate de saída** e
  ordenação sequencial. ID numérico para toda UoW nova (pastas nomeadas não ordenam e quebram cortes de
  label). Carrega o que "Epic" não tem: um gate e uma ordem.
- **User Story `T-NNN`** — a unidade que o agente executa. Um arquivo markdown, formato Implementation
  Contract. O ID mantém o prefixo `T-` por histórico, ainda que o substantivo seja "story".
- **Initiative `INI-NNN`** — camada *opcional* de resultado de negócio, amarrando várias UoWs a um
  resultado do plano de negócios. A ausência nunca bloqueia execução; UoWs transversais (infra,
  governança) normalmente não têm. No board: label de tema `initiative:INI-NNN`.

> **Nota de migração.** Versões anteriores deste template chamavam esses níveis de `Tide` e `Wave`. O
> rename convergiu para o termo literal do AI-DLC no nível do meio e abandonou uma metáfora que o resto
> do vocabulário não compartilhava mais. Escolha nomes por **colisão medida** (`grep` no repositório) —
> um nome que já significa algo no seu domínio produz busca suja e agente confuso.

### 7.2 Tamanho de *bolt* — RULE-TASK-01 e RULE-UOW-01

**RULE-TASK-01 (story nova):** cabe numa sessão de execução, sem handoff de contexto; **≤ 5 ACs**;
**≤ 8 arquivos esperados** (um bullet por arquivo — o guardrail conta bullets); produz incremento útil
sozinha; fica em **um só nível de rigor** (§9) — spec que atravessa níveis é dividida. Estimativa `L`
exige seção "Justificativa de indivisibilidade"; `XL` não existe.
**RULE-UOW-01 (UoW nova):** alvo 3–5 stories, **teto 8**.
As duas são checadas por `task-spec-shape.sh` (hook na criação de spec + CI no diff) e **não
retroagem** — o modo CI só avalia specs e pastas de UoW novas no diff.

### 7.3 Status e o gate de saída

Status de story: `todo` · `in-progress` · `blocked` · `in-review` · `done` · `deferred`.
`in-review` exige algo revisável existindo (branch publicada, PR aberta). **PR mergeada + todas as ACs
marcadas → `done` no mesmo commit**, sem perguntar caso a caso — exceto quando a própria spec declara
ACs bloqueadas por dependência externa (`[⛔]`): essas ficam `in-review` e o decisor decide.

**Gate de saída executável (§16 G5).** Gate em prosa é desejo. Ponha-o no front matter da UoW como
condição que um script consegue avaliar, e faça o `uow-gate.sh` recusar declarar a UoW fechada caso
contrário — inclusive recusando condição que ele não consegue avaliar:

```yaml
---
id: UOW-NN
title: {nome}
initiative: INI-NNN            # opcional
exit_gate:
  stories_done: [T-101, T-102, T-103]
  commands:                    # cada um precisa sair 0
    - ./scripts/guardrails/verify-all.sh --fast
---
```

### 7.4 Template de spec de story (`docs/backlog/TEMPLATE.md`)

```markdown
---
id: T-NNN
title: <curto e acionável>
uow: <NN>
status: todo
type: story            # story | task | spike | chore
adrs: [ADR-NNN]
depends_on: []
blocks: []
estimate: S            # S <1d · M 1–3d · L 3–7d (exige justificativa de indivisibilidade)
skill: backlog-executor
---
# <título>
## Context            <1–3 parágrafos ligando a story às ADRs e ao objetivo da UoW>
## Implementation Contract
### Scope (IN)
### Out of scope (OUT)
### Indivisibility rationale (só se estimate: L)
### Expected files (≤ 8 — um bullet por arquivo)
- `path/to/file` — <descrição>
### Locked technical decisions
### Decisions left open   <cada uma com default proposto>
## Acceptance Criteria (≤ 5 linhas AC-N)
- [ ] AC-1: <dado / quando / então — verificável objetivamente>
## Definition of Done
## Execution notes        <o que rodou, desvios, PDs, achados de review (RULE-QA-02)>
```

**Sinal de retrabalho.** Se o Context de uma story nomeia uma story `done` anterior como o bug que ela
corrige, o executor emite um evento `rework_observed` (§15) — é assim que a taxa de retrabalho é medida.

### 7.5 Template de Initiative

```markdown
---
id: INI-NNN
status: active | done | paused
uows: [NN, NN]
plan: "<âncora no plano de negócios>"
---
# INI-NNN — {Resultado de negócio}
## Resultado de negócio · ## Por que agora · ## Como medimos · ## Units of Work que entregam · ## Fora de escopo
```

---

## 8. Vocabulário — mapa SDD, equivalência AI-DLC e o slot `Operation`

| Fase SDD | Artefato |
|---|---|
| Constitution | `CLAUDE.md` |
| Specify | spec da story `docs/backlog/uow-NN/T-NNN-*.md` |
| Plan | plan mode do agente + ADRs |
| Tasks | decomposição da UoW (espelhada no board) |
| Implement | skill `backlog-executor` |
| Analyze | skill `/analyze` — gate de consistência |

Mantenha um `docs/reference/ai-dlc-rosetta.md` curto (referência, não normativo — fora do orçamento)
mapeando seus termos para o AI-DLC da AWS: Intent ↔ Initiative; Unit of Work ↔ Unit of Work; User Story
↔ `T-NNN`; Bolt ↔ a story do tamanho de uma sessão (adotado como dimensionamento, não como nível); depth
levels ↔ escada de rigor N0–N3 (a sua é derivada de paths, a deles é escolhida à mão); method memory ↔
`docs/office/` + Decision Log; audit trail ↔ `process-metrics.jsonl`; domain experts e quality reviewers
↔ a org virtual. Registre **não-adoções como decisões** (ex.: os 33 stages do AI-DLC, artefato de
logical architecture, mob elaboration) para que não sejam re-propostas como lacunas.

**A fase `Operation` — slot registrado, não fase construída.** Enquanto nenhum usuário real depende do
sistema não há agente de plantão, runbook nem loop de incidente — corretamente. Registre o slot mesmo
assim, para que a ausência seja um gate visível em vez de um penhasco silencioso: uma seção da
constituição nomeando o **gatilho observável de ativação** (ex.: "primeiro tenant pagante em
homologação") e apontando para uma RFC dormente que já lista o roster e o checklist de operação.
Escreva o gatilho como **consulta de dado** que algo consegue executar (§16 F5), não como prosa.

---

## 9. Disciplina de execução — escada de rigor e "executar antes de afirmar"

### 9.1 Escada de rigor (N0–N3)

Classifique cada story **mecanicamente pelos paths que o diff toca**, nunca por julgamento, e aplique os
gates como defaults escritos — o decisor não deveria re-especificar branch/PR/CI/review por story.

| Nível | Gatilho mecânico | Gates |
|---|---|---|
| **N0** | docs, renumeração, comentários, chores de backlog; nenhum código de produto | Loop de execução + rodapé `Refs:` |
| **N1** | código de produto fora de paths sensíveis | N0 + checklist de auto-revisão + branch `task/T-NNN` + PR + CI verde; especialista só em caso de dúvida; ~1 em 5 recebe auditoria de calibração de QA |
| **N2** | diff toca **path sensível** (migrations, políticas de isolamento, auth, billing, privacidade, specs de API pública) | N1 + três pareceres de passada única **antes do merge**: `architect`, `qa-engineer` (100%, nunca amostrado, com evidência de survival condition), `release-manager`. PDs que surgem são `NEEDS_VALIDATION`, nunca default |
| **N3** | pareceres N2 divergem, ou porta de mão única, ou muda comportamento de billing/segurança/SLA | N2 + parecer de desempate + ratificação explícita do decisor |

Regras fixas: survival conditions nunca ficam abaixo de N2; **auto-merge não existe** — o merge é gate
do decisor em todo nível, salvo delegação explícita caso a caso.

**Checklist de auto-revisão N1** (antes de abrir a PR): toda AC `[x]` foi executada (diga como); testes
de fato rodaram (cole a contagem); guardrails de linguagem limpos; rodapé `Refs:`, branch `task/T-NNN`,
título `[T-NNN]`; decisões novas registradas; **código novo com um irmão estruturalmente parecido no
mesmo módulo espelha os padrões defensivos do irmão** (guardas de abort, de bubbling, validação de
forma, a11y) — é a classe de achado de review mais frequente em código novo; e **helper
novo que reimplementa um parse/format que outro arquivo já faz** reusa ou extrai em vez disso (duas
cópias divergem em silêncio).

### 9.2 RULE-QA-01 — executar antes de afirmar

**Nenhuma AC é marcada sem execução que a prove. "Compila" não é execução.** O gate é a **suíte
completa de todo módulo que o diff toca** — derivada do `git diff`, nunca de lista manual — não só os
testes que o executor escreveu (os vizinhos que um contrato novo invalida são justamente os que você
não escreveu). Quando o ambiente impede a suíte completa, rode as classes afetadas isoladamente e
registre **quais e por quê**: resultado parcial declarado é aceitável; AC marcada por inferência não é.

Operacionalizada pela skill `review-gate` (§10): roda o `verify-all.sh`, aciona o `qa-engineer` a frio
sobre diff × spec ("os testes *provam* as ACs ou só passam?") e cruza cada AC `[x]` com o teste que a
prova — AC sem teste que a prove é achado. **A regra vale sem a skill.**

### 9.3 RULE-QA-02 — achado de review vira registro

Achados do gate de review, de um `/code-review` nativo ou dos bots de PR vão para as **notas de execução
da story, no mesmo commit da correção**. Sem arquivo novo: o rastro fica onde a story vive.

---

## 10. Skills de agente (`.claude/skills/`)

Cada skill é um `SKILL.md` com front matter YAML (`name`, `description` com frases-gatilho) e um
procedimento. **Skills somente-leitura dizem isso na primeira linha**, de um jeito que vale mesmo quando
o arquivo é colado numa ferramenta sem isolamento de skill (senão uma ferramenta revisora pode ler uma skill de
"listar tasks prontas" como ordem de implementação).

| Skill | Gatilho | O que faz | Muta? |
|---|---|---|---|
| `backlog-executor` | "execute T-NNN" | O loop: ler story → ler **antes** toda ADR referenciada → commit de `in-progress` → implementar dentro do escopo → validar ACs (RULE-QA-01) → atualizar spec → commit com `Refs:` → sincronizar issue → emitir eventos de auditoria → checar fila de ratificação. Aplica a escada de rigor. | sim |
| `decision-log` | automático, antes/depois de toda story | §6 — varrer, reconferir premissas, parar no fork, escalação sensível, fechar o loop, regenerar índice, checklist pós-story | sim (PDs) |
| `review-gate` | "/review-gate", antes de marcar AC, antes de PR | §9.2 — roda `verify-all.sh`, aciona `qa-engineer`, cruza ACs × execução; recomenda `/code-review` (não consegue dispará-lo) | não |
| `analyze` | "/analyze", antes de fechar uma UoW | Gate de consistência D1–D6 (§15); relatório datado; **ler o bloco, nunca o campo** | não (relatório) |
| `next-tasks` | "/next", "o que dá pra fazer agora" | Stories prontas (todas as `depends_on` done), alavancagem (`+READY`), modelo recomendado, lotes paralelizáveis por colisão de arquivo | não |
| `decision-brief` | "/decision-brief PD-X", "como resolvo…" | Uma PD: reconferir premissas no código → opções (matar as mortas, acrescentar as que faltaram, custo real, custo de não decidir) → **uma** recomendação + o que a mudaria. Sem argumento: tria a fila | não |
| `review-task` | "/review-task T-NNN" | Relatório de entrega: arquivos, testes, configuração, desvios, pendências, tabela de aderência às ADRs | não |
| `branch-cleanup` | "/branch-cleanup" | Varre branches remotas: MERGED (exclui, com guarda), DISJOINT/REVIEW (parecer do architect, decisor exclui); **branches à frente da main que nunca tiveram PR** aparecem como trabalho sem revisão, fail-closed se o estado de PR não puder ser lido | só MERGED |
| `agents-census` | "/agents-census" | Roster × último parecer em `docs/office/` × uso local de tokens | não |

---

## 11. Issue tracker e branches

**Modelo:** tracker + board são a camada operacional/Kanban; o markdown do repo é a fonte de verdade do
escopo. O espelhamento é um **script idempotente** (`sync-github-issues.sh`): markdown → issues, labels
(`status:*`, `type:*`, `uow:*`, `initiative:*`), milestone por UoW, um board. Rode-o pelo CI quando o
backlog mudar, não de memória — board que depende de alguém lembrar **mente por omissão**.

- **RULE-PM-01 — Fonte de verdade por tipo de informação.** Escopo/ACs/decisões/ADRs → repo. Status/
  prioridade/dono/prazo → tracker. Decisões emergentes → `DECISIONS.md`. Propostas → `docs/rfc/`.
- **RULE-PM-02 — Commits e PRs referenciam o trabalho.** Rodapé `Refs: T-NNN[, ADR-NNN]` — ou `RFC-NNN`
  quando a mudança nasce de uma RFC que ainda não tem story (uma RFC é escrita *antes* da decomposição,
  então exigir `T-NNN` ali a reprova por construção). Rodapé só com `ADR-NNN` reprova: ADR é a decisão,
  não o trabalho. Título de PR `[T-NNN] Descrição imperativa`; branch `task/T-NNN-slug`.
  🔒 `commit-refs-footer.sh` como hook nativo `commit-msg` e no CI.
- **RULE-PM-03 — Sync unidirecional (repo → tracker).** Escopo/ACs nunca são editados numa issue.
- **RULE-PM-04 — Board é ao vivo, front matter é formal.** Divergência de status é tolerável; de
  escopo/ACs não.
- **RULE-PM-05 — PR mergeada fecha a story** (`in-review` → `done`, issue fechada, mesmo commit), exceto
  ACs declaradas bloqueadas pela spec.

**Fluxo em dois saltos.**

```
task/T-NNN-slug  ──PR (squash, review, CI rápido)──▶  develop  ──só fast-forward──▶  main  ──▶ deploy
```

PR para a `develop` é obrigatória — nunca push direto (a PR é o único lugar onde o review automático
acontece, §13). A promoção `develop → main` acontece **só** pelo `promote-develop.sh`, que recusa
qualquer coisa que não seja fast-forward. Por que FF e não squash: squash da `develop` na `main` cria um
commit que não é ancestral da `develop`, a merge base nunca avança, cada promoção rearrasta tudo e o
`git bisect run verify-all.sh` sobre o histórico promovido quebra. Com FF, as duas branches ficam
idênticas após cada promoção. A `main` nunca pode receber commit direto — se receber, o script recusa e
diz como recuperar; nunca "conserta" com merge ou reset. A verificação pesada roda sobre a combinação
exata que está sendo promovida. Um detector de **branches à frente da `main` sem PR** pega trabalho que
pulou o fluxo inteiro — commits sem nenhuma camada de revisão, que de outro modo só aparecem quando
alguém por acaso cita a branch.

---

## 12. Guardrails determinísticos e autoridade única de verificação

### 12.1 Uma fonte, dois consumidores

Cada guardrail é um script shell com dois modos:

| Modo | Chamado por | Lê | Saída | Propósito |
|---|---|---|---|---|
| `--hook` | `PreToolUse` (Edit/Write) do `.claude/settings.json` | só o conteúdo prestes a ser escrito | **sempre 0** (aviso) | feedback cedo; nunca bloqueia uma edição |
| CI (padrão / `--ci-range base...head`) | `verify-all.sh` | arquivos rastreados, ou só o que é novo no diff | **1 em violação** | a autoridade — bloqueia o merge |

Exceções vão em `scripts/guardrails/allowlists/<regra>.txt`, uma linha exata por entrada com o motivo.
Regras de hora do commit usam um **hook nativo `commit-msg` do git** (`git config core.hooksPath
scripts/guardrails/git-hooks`), porque o hook de ferramenta do agente nunca vê `git commit`.
Propriedades agregadas (orçamento de instruções, consistência entre registros) são **só de CI**: uma
escrita isolada não enxerga o outro lado do par.

### 12.2 Conjunto inicial (agnóstico de stack)

| Guardrail | Regra |
|---|---|
| `commit-refs-footer.sh` | RULE-PM-02 (`Refs: T-NNN` ou `RFC-NNN`; merge commits pulados) |
| `instruction-budget.sh` | §3.2 ratchet descendente |
| `task-spec-shape.sh` | RULE-TASK-01 / RULE-UOW-01, só o novo no diff |
| `decision-status-consistency.sh` | §4 coerência de status, fail-closed |
| `uow-gate.sh` | §7.3 gate de saída executável (§16 G5) |
| `decision-index.py --check` | §6.5 índice + gate duro sensível |

Guardrails de domínio são onde está a maior parte do valor — escreva os seus para as suas survival
conditions: "dinheiro nunca é float", "nenhum SDK de fornecedor em código de domínio", "namespace de
cache X só via serviço Y", "sem field injection". Cada um tem ~30 linhas: um grep nos arquivos
rastreados da extensão certa, uma allowlist, um caminho `--hook`. **Todo guardrail tem teste que prova
um caso que passa e um que falha** — teste que só exercita o caminho feliz (ou um fixture sintético
que o script nunca lê de fato) continua verde com o bug reintroduzido.

### 12.3 `verify-all.sh` — a definição de "verde"

A lista do que precisa passar vive **num script só**, neutro de runtime (humano, Claude Code, Codex,
Copilot), e não dentro do YAML do CI. O workflow só o chama:

```bash
./scripts/guardrails/verify-all.sh            # completo, range main...HEAD
./scripts/guardrails/verify-all.sh --fast     # só o que não precisa de toolchain de build
./scripts/guardrails/verify-all.sh --list     # o que rodaria, sem rodar
./scripts/guardrails/verify-all.sh --only guardrails,planning
```

Três propriedades fazem dele uma autoridade e não uma conveniência:

1. **Deriva os módulos do diff** — nunca uma tabela path→comando mantida à mão (lista manual é como módulos
   inteiros ficam fora do CI e testes quebrados passam despercebidos).
2. **Check que não pode rodar é declarado, e reprova**: `not verified: <id> — <motivo>`, saída ≠ 0.
   "Não consegui checar" nunca se parece com "limpo". `--allow-missing-tools` degrada conscientemente.
3. **Anti-drift**: reprova quando o workflow ganha um job merge-blocking sem contrapartida no script, ou
   vice-versa — para que os dois não divirjam em silêncio. (Se o provedor de CI cai, um
   repositório cujas regras só vivem no YAML do CI fica com zero enforcement. Um script que roda em
   qualquer lugar é o seguro.)

Rodar localmente é feedback, não o gate — recibo de execução local auto-atestado é rejeitado; o gate é a
execução no CI.

---

## 13. Review automático de PR e seu fallback obrigatório — RULE-REVIEW-01

Toda PR dispara os bots de review configurados no repositório (Codex, Copilot, …). Os achados são
tratados como review real: investigar; corrigir se pequeno e não-ambíguo; perguntar ao decisor se
ambíguo ou arquitetural; marcar como não-acionável se falso-positivo. Achados vão para as notas de
execução da story (RULE-QA-02).

**Prova de que o review rodou:** um comentário do bot (achado) **ou** uma reação 👍 na PR (sem achados).
Três modos de falha contam todos como "não aconteceu":

| Modo | Aparece como |
|---|---|
| Erro do bot | "…encountered an error and was unable to review" |
| Cota esgotada | "You have reached your … usage limits for code reviews" |
| Silêncio | nem comentário nem 👍 dentro da janela normal de acompanhamento |

Os dois primeiros são piores que o silêncio porque *parecem* atividade. Avisar não basta — avisar e
seguir deixa a PR mergear com **zero camadas de revisão**. Em qualquer falha, o executor deve, na mesma
mensagem, **sugerir uma camada local de review**: o `/code-review` nativo (disparado e cobrado pelo
usuário — o agente sugere, nunca dispara) e/ou o dispatch do `qa-engineer` (que o agente pode rodar
direto). Calibre por tamanho e sensibilidade: uma PR pequena só de docs não precisa; um diff grande
de produto, ou qualquer coisa N2, não deveria mergear sem nenhuma. Se o decisor mergear mesmo
assim, fica registrado, não por omissão.

---

## 14. Papéis multi-agente — a org virtual

| Papel | Mecanismo | Governado por | Implementa? | Produz |
|---|---|---|---|---|
| **Executor** | sessão principal do agente | `CLAUDE.md` | sim | código, specs, rascunhos de RFC, PDs |
| **Agentes de papel** | `.claude/agents/*.md` | o próprio arquivo + `CLAUDE.md` | não | pareceres em `docs/office/`, specs, digests |
| **Revisor** | segunda ferramenta de código | `AGENTS.md` | só sob pedido explícito | achados, baterias de teste focadas, auditorias |
| **Especialista de design** | ferramenta de design separada | brief + `DESIGN_DECISIONS.md` | não | `DD-NNN` + assets aprovados |
| **Housekeeping** | execução agendada, sem operador | a skill que roda | nunca | relatórios datados (§15) |

### 14.1 Agentes de papel — `.claude/agents/` + `docs/office/`

| Mecanismo | Papel na org | Onde |
|---|---|---|
| Subagentes | os *papéis* — cada arquivo é uma carta de contratação | `.claude/agents/{papel}.md` |
| Skills | os *processos* que os papéis executam | `.claude/skills/` |
| Routines / cron | a *recorrência* | agendador do ambiente do agente |
| `docs/office/` | a *memória institucional* | `docs/office/{papel}/AAAA-MM-DD-assunto.md` |

**Consolide funções, não replique um organograma aspiracional.** Crie um papel só contra dor concreta.
Núcleo provado (vai no Mandate): `architect`, `product-owner`, `qa-engineer`, `release-manager`, `tpm`,
`chief-of-staff`. Opcionais, quando a dor aparecer: `devops` (específico de stack), `cfo` (pricing/unit
economics), `pmm` (posicionamento/copy), `cofounder` (sparring estratégico com **contraditório
obrigatório**: steelman → caso contra → pré-mortem → posição própria), `coo` (ponto de entrada único que
despacha e registra — só compensa quando já existem vários papéis).

| Agente | Faz | Nunca |
|---|---|---|
| `architect` | revisa diffs/RFCs contra ADRs e regras nomeadas; veredito aprovar / com ressalvas / rejeitar / exige RFC | implementar; criar ADRs |
| `product-owner` | ideia → spec de story dentro da RULE-TASK-01; checa colisão de ID em todas as branches | aprovar escopo; mexer em billing |
| `qa-engineer` | entregável × ACs; os testes *provam*? roda a suíte; testes obrigatórios | corrigir código ou escrever testes (independência) |
| `release-manager` | checklist de saída com evidência; GO / NO-GO | dar waiver em survival condition; mergear |
| `tpm` | mapa de dependências, sequenciamento, risco de programa, sync do board, bookkeeping de ratificação | editar escopo numa issue; decidir prioridade |
| `chief-of-staff` | briefing semanal de uma página: top 3, decisões esperando, digest de ratificação, sinais amarelos, pulso de execução | decidir |

**Formato do arquivo de agente:** front matter (`name`, `description` com gatilhos, `tools` limitadas ao
mandato, `model` dimensionado ao papel) + mandato, o que ler antes, checklist mínimo de guardrails,
formato de saída e uma seção explícita de **limites do mandato** terminando com *"o decisor é o único
tomador de decisão; decisões passam por RFC."*

**Despache em primeiro plano.** Um agente coordenador que despacha sub-agentes em background e encerra
o turno "aguardando notificações" entrega um turno vazio — encerrar o turno *é* devolver o controle;
não existe espera passiva. Se o toolset dele não consegue coletar resultado de background, despacho em
primeiro plano é fato de capacidade, não preferência de estilo. Entrega parcial honesta vence turno vazio.

**`docs/office/`** — imutável após a data, nunca apagado; não é fonte de decisão (memo que contradiz uma
ADR está errado por definição); não é documentação de produto. Quando contratar uma pessoa para o papel,
o arquivo do agente + o histórico em office *é* o onboarding.

### 14.2 Revisor — `AGENTS.md`

Resume o contrato para uma ferramenta secundária: ordem de leitura (`CLAUDE.md` → constituições de área
→ ADRs → `learned-rules.md`), papel de revisor (implementa só sob pedido explícito), a regra **nunca
escorregar de listar para executar** em skills somente-leitura, o fluxo em dois saltos (base de PR é a
`develop`), o comando único de verificação e um checklist de alta severidade espelhando a §12 da
constituição para as regras sem script. Nunca sobrepõe o `CLAUDE.md`. Registre reversões de papel como
regra aprendida, para que um experimento já tentado e revertido não seja re-proposto de memória.

### 14.3 Especialista de design — `docs/design/`

Handoff unidirecional para ferramentas de design fora do loop do repo: **brief** (o executor escreve
`docs/design/briefs/{superfície}-brief.md` — contrato de dados, componentes, restrições do design system,
decisões em aberto) → **sessão** (uma pessoa conduz na ferramenta de design, um componente por conversa)
→ **sync** (só output aprovado entra em `docs/design/assets/`, decisão registrada como `DD-NNN`).
Stories de implementação consomem só arquivos que já estão em `assets/`.

### 14.4 Evals de agente — testando a superfície normativa

Skills, agentes e a constituição são versionados e, por padrão, **não testados**: editar `CLAUDE.md` é
deploy sem regressão. Comece com evals mutation-style das 2–3 invariantes de maior custo histórico (ex.:
"o executor para diante de decisão travada", "default sensível nunca fecha em silêncio", "skill
somente-leitura nunca executa"):

- `.claude/evals/invariants/inv-NN-*.yaml`: invariante, arquivos `spec_under_test`, uma trajetória
  **golden** que precisa passar e uma **mutated** (mesmo cenário, violado de propósito) que precisa
  falhar — isso prova que o *checker* pega a violação, não só que o caminho feliz passa.
- `spec_pinned_sha`: o SHA de **blob** (`git rev-parse HEAD:<path>`, conteúdo — não o do commit, que
  quebra com clone raso e squash merge) de cada spec contra a qual as trajetórias foram escritas;
  `--check-staleness` reprova quando o texto normativo mudou e o fixture não foi reconferido.
- Roda no CI **não-bloqueante** primeiro; promove a merge-blocking depois de uma janela ininterrupta sem
  falha de infraestrutura — qualquer falha reinicia o relógio.

Seja explícito sobre o limite: fixtures são gravados à mão; isto é teste de regressão do checker, não
monitor ao vivo do comportamento do agente.

---

## 15. Rotinas de housekeeping e trilha de auditoria — `docs/reports/`

Passadas somente-leitura cuja única saída é um relatório datado: `{tipo}-AAAA-MM-DD.md`, histórico
append-only, cada um declarando logo no início que não alterou nada. Rotinas iniciais:

1. **Gate de consistência (`/analyze`)** — D1 decisão implementada mas não promovida · D2 stack
   divergente · D3 gate/descrição divergente · D4 status divergente (tolerável) · D5 refs órfãs /
   colisão de IDs · D6 decisão não registrada. Cada achado: `id · severidade · categoria · evidência
   (arquivo:linha) · recomendação · dono`. **Regra de método — ler o bloco, nunca o campo:** antes de
   afirmar que algo está pendente, abra o arquivo (a opção de status não marcada vem primeiro; nome de
   classe não é escopo; grep vazio de um símbolo não prova ausência de comportamento; a ressalva pode
   estar no corpo e no índice, e não no campo). Falso "pendente" é pior que silêncio: convida a
   re-decidir o que já foi decidido.
2. **Saúde do Decision Log** — 🔴 sensível sem resolução / não ratificado · 🟡 aberto comum · 🟢 pronto
   para fechar (story de origem `done`, PD ainda aberta).
3. **Trilha de auditoria — `process-metrics.jsonl`.** O executor acrescenta uma linha por fechamento de
   story — a exceção a "um arquivo datado por execução": append-only e **não reproduzível**, então nunca
   podado:

```json
{"ts":"<UTC>","event":"story_closed","story":"T-NNN","rigor":"N0|N1|N2|N3","model":"<id>","token_cost":null,"acs_failed_at_gate":0,"findings_by_agent":{}}
{"ts":"<UTC>","event":"rework_observed","story":"T-NNN","origin_story":"T-MMM","cause":"<curta>","pr":null}
```

`token_cost: null` quando não mensurável — nunca pule o evento por falta do número. A **chave de
correlação do retrabalho é `origin_story`**, cruzada com o fechamento da story que entregou o defeito; a
taxa é derivada depois, nunca declarada no fechamento. Um script agregador alimenta o "pulso de
execução" semanal do `chief-of-staff` — é isso que calibra a escada de rigor com dado.

---

## 16. Módulo de prontidão para escala (opcional) — cinco gates, não trinta e três

Adote quando um segundo time, um segundo decisor ou um segundo repositório estiver no horizonte. A maior
parte se paga mesmo com um executor só, porque os defeitos que corrige existem hoje. A pergunta de
desenho é *o que quebra quando o decisor deixa de ser único?*

| Gate | Momento | Mecanismo |
|---|---|---|
| **G1 — Intent aceito** | Initiative → UoW | toda UoW **de produto** nova nasce com Initiative pai (sem retroagir; UoWs transversais isentas) |
| **G2 — Escopo aceito pela contraparte** | spec pronta, antes de executar | quando a story toca path de outro dono no `CODEOWNERS`, o `Out of scope` exige aceite registrado desse dono — **condicionado a existir um segundo dono** (aceite sem contraparte é formulário vazio) |
| **G3 — Rigor classificado** | início da execução | §9.1 — mecânico por path |
| **G4 — Pronto para merge** | fim da execução | §9.1 checklist N1 / três pareceres N2 |
| **G5 — UoW fechada** | gate de saída | §7.3 `exit_gate` + `uow-gate.sh`; converta toda UoW **aberta**, não "nenhuma" — gate que só vale para UoW futura deixa intactos os gates em prosa de hoje |

Fases de sustentação:

- **F1 — Ligar os gates mecânicos que estão fora do CI** (`decision-index.py --check`, validadores de
  contrato de agente). Linhas de YAML — mas dependem de um CI que de fato rode; destravar a execução do
  CI é pré-requisito, não parte da fase.
- **F2 — `CODEOWNERS` agora, com um dono só.** O valor é o mapa existir, ser diffável e estar correto
  *antes* de haver a quem atribuir. Pré-requisito do G2 e do roteamento.
- **F4 — `Scope: local | org` e `Ratified-by` por papel** (§6.1). `Sensitivity` vira chave de roteamento
  no dia em que houver mais de um ratificador. Isto prepara a federação como configuração; não federa.
- **F5 — Gatilho de `Operation` resolvível por máquina.** Mover o gatilho da prosa para um campo
  `Reopen-trigger` não basta se o script de índice só resolve `T-NNN done` e o caminho `--check` retorna
  antes de avaliar gatilhos. Entregue: (a) a condição como **consulta de dado**, (b) um check que a
  execute, (c) o wiring onde ele de fato roda.
- **F8 — Coordenação, paralelismo, onboarding.** Sync de issues automático; detecção de colisão de
  arquivo derivada do **diff real** em vez de "arquivos esperados" declarados; um job de bootstrap que
  roda o guia de setup de dev do zero. E preserve a **fronteira do método**: nada novo em
  `scripts/guardrails/` ganha path de produto hardcoded sem override por env var — é isso que mantém a
  camada de governança extraível (o repositório do Mandate é a prova).

**PODs — a unidade que escala.** A unidade operacional para vários times é o **POD**: um time pequeno e
estável de humanos e agentes (tipicamente 1–3 pessoas mais os seus agentes de papel) dono de uma fatia
do sistema de ponta a ponta — os seus paths no `CODEOWNERS`, as suas Units of Work, um decisor para os
seus domínios (`Ratified-by: owner:<pod>`, roteado por `Sensitivity`) e um nível de autonomia
conquistado pela própria trilha de auditoria. PODs se coordenam só por contratos que já existem: G2
(aceite de escopo pela contraparte), G5 (gates de saída executáveis) e decisões `Scope: org`. Um POD é
dono de resultados, não de camadas; o decisor da org fica só com `Scope: org` e os desempates entre
PODs. Escala-se acrescentando PODs, não processo. A comparação completa com o AI-DLC da AWS — veredito,
adoções, rejeições, lacunas — e o modelo de PODs ficam no repositório do Mandate, em
`docs/reference/mandate-vs-ai-dlc.pt-BR.md`.

**Rejeitado, de propósito:** adotar um processo completo de 33 stages com 14 agentes (stages existem
para coordenar quem não compartilha contexto; mapeie seus pontos reais de handoff — cinco gates
costumam cobrir); externalizar o método para uma plataforma fora do repo (quebra a atomicidade decisão + código
num mesmo diff revisável). **Risco principal:** `exit_gate` virar prosa dentro de um campo estruturado.
Mitigação obrigatória: o script recusa qualquer condição que não consiga avaliar.

---

## 17. Versionamento de documentação

Markdown no git é a fonte; `.docx`/`.pdf`/`.html` são exports. Snapshots superados vivem em
`docs/versions/archive/`, nunca apagados. **Editar in-place** por padrão (ADRs, plano corrente); snapshot
só para congelar um marco (release externo, corte histórico).

| Dígito | Incrementar quando | Exemplo |
|---|---|---|
| **Major** | troca de stack, pivot de modelo de negócio, reescrita fundamental | trocar o runtime central |
| **Minor** | um conjunto de ADRs vira `accepted`, OU uma UoW chega a produção, OU o modelo de receita muda | UoW em prod → vX.(Y+1).0 |
| **Patch** | tudo que não muda decisões existentes: specs, RFCs, PDs, refinamentos, notas | specs novas → vX.Y.(Z+1) |

Regra de ouro: reversível sem impactar produção → patch; travou uma decisão irreversível → minor.

---

## 18. Checklist de bootstrap

**Caminho rápido:** clone o `mandate-framework`, rode `scripts/init.sh` (preenche todo
`{{PLACEHOLDER}}`), `git config core.hooksPath scripts/guardrails/git-hooks`, rode
`./scripts/guardrails/verify-all.sh` e continue a partir do passo 3 abaixo.

1. **Constituição** (§3): contexto, tabela de stack com uma ADR por linha, regras nomeadas com marcador
   🔒, fronteira RFC × implementação, fases, lista do que nunca fazer, RULE-PM/TASK/QA/REVIEW,
   versionamento. Grave o teto do orçamento de instruções no primeiro dia (`--record`) — dali só desce.
2. **Diretórios** (§2): `docs/adr|rfc|backlog|initiatives|reference|reports|office`, `DECISIONS.md` com
   os marcadores de índice, `learned-rules.md` (vazio serve), `AGENTS.md` se uma segunda ferramenta for
   tocar o repo.
3. **ADRs-semente** — uma por linha da stack, `accepted`, datadas, com front matter legível por máquina.
4. **Domínios sensíveis** — liste-os na constituição *e* no `decision-index.py` e nos padrões de path da
   escada de rigor. É a única peça que não dá para retrofitar depois que um default silencioso já foi
   para produção.
5. **UoW 01** — fundação, 3–5 stories, `exit_gate` executável ("repo builda + CI verde + deploy
   hello-world").
6. **Guardrails** — o conjunto inicial + o seu primeiro guardrail de domínio para a sua primeira
   survival condition; `verify-all.sh` como única coisa que o CI chama; `CODEOWNERS`.
7. **Branches** — `develop` + `main`, proteção de branch: PR obrigatória para a `develop`, só FF para a
   `main` via `promote-develop.sh`.
8. **Espelhamento de issues** — script de sync, labels, milestones por UoW, board; rode pelo CI.
9. **Bots de review** — ative pelo menos um; adote a RULE-REVIEW-01 com seu fallback.
10. **Org virtual** — papel por papel, contra dor concreta; `architect` e `product-owner` costumam se
    pagar primeiro; papéis de coordenação e cadência só quando já existirem vários.
11. **Depois, quando os registros crescerem:** `/analyze` antes de fechar uma UoW; health check do
    Decision Log passadas ~50 PDs; evals de agente para as invariantes que já custaram caro uma vez; o
    módulo da §16 quando um segundo time estiver à vista.
12. **Dry run** — execute a primeira story de ponta a ponta e verifique: ADRs lidas antes, escopo OUT
    respeitado, PDs registradas, ACs provadas por execução, rodapé `Refs:`, status atualizado, linha de
    auditoria gravada. Corrija a constituição onde o agente desviou — a constituição é código; depure-a.

---

*Este template é intencionalmente agnóstico de stack, domínio e ferramenta. Tudo que é específico de um
projeto pertence aos artefatos que este template manda criar — não a este arquivo.*
