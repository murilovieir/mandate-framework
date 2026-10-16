# Mandate e AI-DLC — o que temos, o que adotamos, o que rejeitamos, o que falta

> 🇺🇸 English: [mandate-vs-ai-dlc.md](mandate-vs-ai-dlc.md) · Autor: **Murilo Vieira**
> Referência, não normativo — fora do orçamento de instruções. Tabela curta de equivalência: [`ai-dlc-rosetta.md`](ai-dlc-rosetta.md).

O **AI-DLC** (AI-Driven Development Lifecycle, `awslabs/aidlc-workflows`) é o método da AWS para
desenvolvimento de software com IA no centro: fases (Ideation · Inception · Construction · Operation),
trabalho organizado em **Units of Work** e iterações curtas chamadas **bolts**, 33 *stages* cada um com
dono e gate de aprovação, *depth levels* escolhidos à mão, um roster de 14 agentes, sessões síncronas de
**mob elaboration**, trilha de auditoria e conhecimento em dois níveis.

O Mandate foi avaliado contra o AI-DLC duas vezes ao longo da sua evolução. Este
documento registra o resultado: o veredito, o que convergiu, o que foi rejeitado de propósito e o que
continua em aberto.

---

## 1. O veredito

O Mandate saiu **no decil superior no eixo de decisão** — spec como contrato, RFC → ADR gated pelo
decisor, Decision Log com reversibilidade, sensibilidade e ratificação, escada de rigor derivada
mecanicamente dos paths — e **abaixo da média num eixo só: impedir por máquina em vez de pedir por
texto.** O AI-DLC é mais fraco onde o Mandate é mais forte (não tem decision log) e mais forte onde o
Mandate era mais fraco (enforcement, dimensionamento, medição, operação).

Por isso a decisão foi **convergir, não adotar**: importar cinco conceitos e dois nomes, manter o método.

## 2. As lacunas encontradas — e como cada uma foi fechada

| # | Lacuna (como encontrada) | Como o Mandate fechou | Pilar |
|---|---|---|---|
| P1 | Guardrails viviam em prosa — enforcement só depois do diff, quando havia | Um script por regra, dois consumidores (hook de aviso + CI merge-blocking); `verify-all.sh` como autoridade única | **N**, **T** |
| P2 | A superfície normativa (constituição, skills, agentes) não tinha teste — editar a constituição era deploy sem regressão | Evals de agente mutation-style: trajetórias golden + mutated, gate de staleness por blob SHA | **T** |
| P3 | Orçamento de instruções estourado — a constituição carregava errata narrativa inline | Conhecimento em dois níveis (`learned-rules.md`) + ratchet descendente do orçamento | **N** |
| P4 | Unidades de trabalho grandes demais para o loop propõe → arbitra (estimativas de "> 1 semana") | Dimensionamento *bolt*: RULE-TASK-01 (≤ 5 ACs, ≤ 8 arquivos, uma sessão) e RULE-UOW-01 (3–5, teto 8) | **E** |
| P5 | O processo não se media — a escada de rigor não era calibrável | Trilha de auditoria `process-metrics.jsonl` (`story_closed`, `rework_observed`) + agregador | **T**, **E** |
| P6 | A fase Operation era zero — penhasco conhecido | Slot registrado com gatilho de ativação observável (não construído até ser necessário) | **E** |

Hipótese testada e **descartada** (não era lacuna): a memória institucional já existia —
`docs/office/` + Decision Log são um equivalente mais estruturado do *method memory* do AI-DLC.

## 3. O que o Mandate já tinha (equivalência)

| AI-DLC | Mandate | |
|---|---|---|
| Ideation / business intent | **Initiative** (opcional) | ✅ |
| Inception | RFC → ADR + spec de story | ✅ mais forte — o AI-DLC não tem Decision Log |
| Construction | Unit of Work + `backlog-executor` | ✅ |
| Stages com dono + gate de aprovação | passos do loop do executor + 5 gates de handoff (G1–G5) | ✅ equivalente funcional |
| Depth levels (escolhidos à mão) | Escada de rigor N0–N3 (**derivada dos paths tocados**) | ✅ mecânico > manual |
| Method memory | `docs/office/` + `DECISIONS.md` | ✅ com reversibilidade/sensibilidade/ratificação |
| Domain experts + quality reviewers + composer | org virtual (`qa-engineer`/`release-manager` = revisores) | ✅ |

## 4. O que foi adotado

1. **Unit of Work** — convergência literal de nome (substituiu o antigo "Wave"); **Initiative**
   substituiu o antigo nível de topo ("Tide"). `Intent` foi rejeitado como nome por colidir com um termo
   de produto — nomes são escolhidos por **colisão medida** (`grep` no repositório), não por gosto.
2. **Dimensionamento *bolt*** — adotado como regra de tamanho, não como nível novo da hierarquia.
3. **Trilha de auditoria** — um evento estruturado por fechamento de story.
4. **Conhecimento em dois níveis** — constituição (o quê) + regras aprendidas (por quê).
5. **Fase Operation** — como slot com gatilho observável.

## 5. O que foi rejeitado — de propósito

| Elemento do AI-DLC | Por que não |
|---|---|
| Adotar o método inteiro (33 stages, 14 agentes) | Trocaria o eixo forte do Mandate por um empate. Stages existem para coordenar quem **não compartilha contexto**; mapear os pontos reais de handoff achou **cinco** (G1–G5), não 33 |
| Rename global para o vocabulário AI-DLC | Custo em centenas de arquivos para termos em que o Mandate não perde nada (story, RFC, ADR, PD) |
| Artefato de logical architecture por Unit of Work | **Não-adoção** registrada — uma decisão, não uma lacuna de backlog |
| Mob elaboration síncrona | Feita para grupos de pessoas numa sala; um decisor com org virtual cobre isso de forma assíncrona (N2 = três pareceres independentes antes do merge). Revisitada com os PODs — §7 |
| Depth levels manuais | O rigor derivado de path do Mandate é estritamente melhor: classificar é derivação, não escolha |

## 6. O que ainda falta

| Lacuna | Onde está planejado |
|---|---|
| Fase Operation construída (roster de plantão, runbooks, loop de incidente), gatilho como consulta de dado | ROADMAP UoW-10 (MF-032..034) |
| Evals de agente merge-blocking, capturados de sessões reais, multi-runtime | ROADMAP UoW-04 (MF-011..013) |
| G1 (intent aceito) e G2 (aceite de escopo pela contraparte) aplicados, não só documentados | ROADMAP UoW-06 (MF-019) |
| Ratificação federada por dono em vez de um decisor só | ROADMAP UoW-06 (MF-018, MF-020, MF-021) |
| Autonomia que se adapta à evidência (o AI-DLC tem checkpoints humanos fixos; o Mandate quer checkpoints conquistados) | ROADMAP INI-01 |
| O modelo operacional de vários times — **PODs** | §7 e ROADMAP UoW-07 |

## 7. PODs — a unidade de trabalho paralelo

A mob elaboration e os donos por stage do AI-DLC pressupõem um time. O Mandate começou com um decisor e
um executor; os gates de prontidão para escala (G1–G5) prepararam o schema para mais gente. O **POD** é
a unidade operacional que transforma esse preparo em prática.

**Um POD é um time pequeno e estável de humanos e agentes dono de uma fatia do sistema de ponta a
ponta** — tipicamente 1–3 pessoas mais os seus agentes de papel — com paths, backlog, decisor e nível de
autonomia próprios. É pelos PODs que o Mandate escala: acrescentam-se PODs, não processo.

| Um POD tem | No Mandate |
|---|---|
| **Paths que são dele** | as suas entradas no `CODEOWNERS` |
| **Um decisor para os seus domínios** | `Ratified-by: owner:<pod>` — o `Sensitivity` roteia cada PD para o POD dono |
| **O seu backlog** | as Units of Work de que é dono (`owner:` no front matter da UoW) |
| **O seu roster** | agentes compartilhados da org + overrides específicos do POD em `.claude/agents/` |
| **O seu mandato** | um nível de autonomia (A0–A4) conquistado pela **sua própria** trilha de auditoria |
| **Os seus rituais** | uma *mob* síncrona curta só na Inception (intent → UoW), assíncrono em todo o resto |

**Contratos entre PODs** são os gates que já existem:

- **G2 — aceite da contraparte.** Story que toca paths de outro POD precisa do aceite registrado desse
  POD sobre o seu *Out of scope* — "fora de escopo" deixa de ser transferência silenciosa de trabalho.
- **G5 — gate de saída da Unit of Work.** O gate executável é o sinal que outro POD espera.
- **Decisões `Scope: org`.** Decisão que prende outros PODs é visível, roteada e ratificada no nível da org.

**Regras práticas:** um POD é dono de *resultados*, não de camadas (um POD por capacidade de negócio, não
um "POD de backend"); dois PODs nunca dividem um path sem contrato G2 explícito; a autonomia de um POD
nunca passa do nível que os próprios dados dele sustentam; o decisor da org fica só com `Scope: org` e os
desempates entre PODs.

O modelo de PODs está planejado no ROADMAP UoW-07 (MF-022..024, MF-038..041).
