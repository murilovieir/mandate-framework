# Mandate Framework — Roadmap

> 🇺🇸 English: [ROADMAP.md](ROADMAP.md) · Autor: **Murilo Vieira** (@murilovieir)

Para onde o Mandate vai depois da v1.0.0, organizado no próprio vocabulário do Mandate: **Initiatives**
(resultados) → **Units of Work** (incrementos com gate de saída) → **stories**. As stories do framework
usam o prefixo `MF-NNN` para nunca colidir com as stories `T-NNN` de um projeto que adote o Mandate.

Duas linhas concentram a maior parte do valor, e as duas seguem o mesmo princípio — **autonomia e
paralelismo se conquistam com evidência, nunca são concedidos por padrão**:

1. **Autonomia** — o agente fazendo mais sozinho, na medida em que os dados mostram que ele consegue.
2. **Vários humanos + várias IAs em paralelo** — sair de um decisor e um executor para **PODs**: times
   de pessoas e agentes trabalhando ao mesmo tempo sem pisar um no outro.

Como o Mandate se compara ao AI-DLC da AWS — o que já tem, o que adotou, o que rejeitou e o que falta —
está em [`docs/reference/mandate-vs-ai-dlc.pt-BR.md`](docs/reference/mandate-vs-ai-dlc.pt-BR.md).

Horizontes: **Agora** (próximas releases) · **Depois** (depende do Agora) · **Mais adiante** (precisa
de um segundo time real ou de uso real em produção para ser bem desenhado). Status de todos os itens
hoje: `todo`.

---

## Concluído

| ID | Story | Pronto quando |
|---|---|---|
| MF-042 | **Higiene da release v1.0.0** — revisão de conteúdo por referências a qualquer projeto de origem; About do repositório | ✅ varredura sem nenhuma ocorrência · texto do About pronto (aplicado pelo autor nas configurações do repositório) |

---

## INI-01 — Autonomia conquistada

*Resultado: o mandato do agente se amplia sozinho onde a trilha de auditoria prova que é seguro, e se
estreita onde não é — em vez de ficar fixo à mão.*

### UoW-01 — Níveis de autonomia como configuração · **Agora**
Gate de saída: o nível de autonomia de todo path está declarado, é lido por máquina e aplicado pelo `verify-all.sh`.

| ID | Story | Pronto quando |
|---|---|---|
| MF-001 | **Escada de autonomia A0–A4** no `governance.env` (A0 só propõe · A1 implementa, humano mergeia · A2 auto-merge de N0 verde · A3 auto-merge de N1 com review gate limpo · A4 loops autônomos), declarada por padrão de path | um guardrail rejeita merge acima do nível do path |
| MF-002 | **Mandato por story** — a spec declara o que o agente pode tocar (paths, comandos, chamadas externas); um hook avisa sobre o que estiver fora | edição fora dos paths declarados gera aviso, e o CI reprova |
| MF-003 | **Orçamentos** — teto de tokens/custo/tempo por story e por nível de rigor; o executor para e escala ao estourar | `story_closed` registra o custo, e uma execução acima do orçamento para com nota de escalação |
| MF-004 | **Kill switch** — uma flag que derruba todo agente para A0 na hora (incidente, auditoria, férias) | ligar a flag faz todo loop autônomo sair no passo seguinte |

### UoW-02 — Autonomia conquistada pela trilha de auditoria · **Depois**
Gate de saída: um script propõe mudanças de nível a partir do `process-metrics.jsonl`; o decisor ratifica como PD.

| ID | Story | Pronto quando |
|---|---|---|
| MF-005 | **Agregador de métricas** — taxa de retrabalho, ACs reprovadas no gate, achados de review por agente, lead time, custo por nível de rigor | `scripts/planning/process-metrics.py` imprime a tabela a partir do JSONL |
| MF-006 | **Propostas de autonomia** — "path X: 20 stories, 0 retrabalho, 0 falha de gate → propor A2"; e o inverso em regressão | o script escreve um rascunho `PD-AUTONOMY-NN` com a evidência, nunca aplica |
| MF-007 | **Rebaixamento automático** — um evento de retrabalho num path A2/A3 desce um nível até ser reconquistado | um `rework_observed` baixa o nível na rodada seguinte, registrado como PD |

### UoW-03 — Loops autônomos · **Depois**
Gate de saída: as rotinas recorrentes rodam sozinhas por agenda, cada uma somente-leitura ou limitada pelo seu nível.

| ID | Story | Pronto quando |
|---|---|---|
| MF-008 | **Rotinas agendadas** — briefing semanal do `chief-of-staff`, `/analyze` antes de fechar UoW, saúde do Decision Log; templates para cron do GitHub Actions e agendadores de agente | as rotinas rodam na agenda e escrevem em `docs/reports/` sem um humano disparar |
| MF-009 | **PRs que se curam** — o executor acompanha a própria PR: corrige CI vermelho, responde threads de review, roda o gate de novo; escala depois de N rodadas | uma PR vermelha aberta pelo agente volta a verde sem humano, ou gera escalação |
| MF-010 | **Piloto automático do backlog** (A4) — pega a próxima story pronta do `next-tasks`, executa, abre PR, para no gate de merge | uma story vai de `todo` a PR aberta sem prompt humano, dentro do orçamento |

### UoW-04 — Testar o agente, não só o código · **Agora**
Gate de saída: a superfície normativa (constituição, skills, agentes) tem testes de regressão que bloqueiam merge.

| ID | Story | Pronto quando |
|---|---|---|
| MF-011 | **Evals de agente no framework** — portar os evals mutation-style de invariantes (trajetórias golden + mutated, staleness por blob SHA) | o `verify-all.sh` roda os evals; três invariantes entregues |
| MF-012 | **Captura de trajetória** — gravar sessões reais como fixtures em vez de escrevê-las à mão | uma sessão capturada pode ser reproduzida como fixture |
| MF-013 | **Evals multi-runtime** — a mesma invariante checada no Claude Code, no Codex e em outros | uma invariante passa em pelo menos dois runtimes |

---

## INI-02 — Vários humanos e várias IAs, em paralelo

*Resultado: várias pessoas e vários agentes trabalham no mesmo repositório ao mesmo tempo, com dono
claro, sem colisão silenciosa e com decisões ratificadas pela pessoa certa.*

### UoW-05 — Claims e coordenação · **Agora**
Gate de saída: ninguém — humano ou agente — começa uma story que outro está segurando, e claims parados expiram.

| ID | Story | Pronto quando |
|---|---|---|
| MF-014 | **Protocolo de claim/lease** — `claimed_by` (id de humano ou agente) + `lease_until` no front matter da story, espelhado no assignee da issue | começar uma story com claim de outro é recusado pelo executor e sinalizado no CI |
| MF-015 | **Colisão detectada pelo diff real** — comparar branches/PRs abertas pelos arquivos tocados, não pelos "arquivos esperados" declarados | duas PRs abertas tocando o mesmo arquivo são reportadas antes de qualquer merge |
| MF-016 | **Fan-out em worktrees** — uma worktree git por agente, lotes vindos do `next-tasks`, ordem de merge calculada pelas dependências | três stories prontas rodam em worktrees paralelas e mergeiam numa ordem consistente |
| MF-017 | **Cápsula de handoff** — um `HANDOFF.md` padrão por story em andamento (estado, próximo passo, perguntas abertas) para qualquer humano ou agente retomar | uma sessão nova retoma uma story interrompida só pela cápsula |

### UoW-06 — Decisões federadas · **Depois**
Gate de saída: decisões são roteadas ao dono certo e ratificadas por papel, não por uma pessoa só.

| ID | Story | Pronto quando |
|---|---|---|
| MF-018 | **Roteamento de ratificação** — `Sensitivity` + `CODEOWNERS` definem quem precisa ratificar uma PD; o `decision-index.py` aplica | PD ratificada pelo dono errado reprova o `--check` |
| MF-019 | **Aceite de escopo pela contraparte (G2)** — story que toca paths de outro dono precisa do aceite registrado desse dono sobre o Out of scope | o guardrail reprova uma spec sem a linha de aceite |
| MF-020 | **Decisões de escopo org** — PDs `Scope: org` replicadas num registro de decisões compartilhado entre repositórios | uma PD de org escrita num repo é visível e checada em outro |
| MF-021 | **RFCs com vários decisores** — aprovadores explícitos por área e regra de quórum quando as áreas se sobrepõem | uma RFC que toca duas áreas precisa das duas aprovações para virar `approved` |

### UoW-07 — PODs: times de humanos e agentes · **Mais adiante**
Gate de saída: dois PODs trabalham numa mesma base de código, cada um com paths, backlog, roster, decisor e nível de autonomia próprios, coordenados só por contratos G2/G5. Conceito: [`docs/reference/mandate-vs-ai-dlc.pt-BR.md` §7](docs/reference/mandate-vs-ai-dlc.pt-BR.md).

| ID | Story | Pronto quando |
|---|---|---|
| MF-022 | **Modos de pareamento** — humano conduz/agente revisa e agente conduz/humano revisa como modos explícitos da story, com gates diferentes | o modo na spec muda quais gates se aplicam |
| MF-023 | **Rosters por time** — cada time com overrides próprios de `.claude/agents/` sobre a org compartilhada | dois times rodam rosters diferentes no mesmo repo sem conflito |
| MF-024 | **Board de dependências entre times** — gates de saída de UoW como o sinal que outro time espera | a story bloqueada de um time desbloqueia sozinha quando o gate do outro time é atingido |
| MF-038 | **Manifesto de POD** — `pods/<nome>.yaml`: membros (humanos + agentes), paths de que é dono, decisor, nível de autonomia; `CODEOWNERS` gerado a partir dele | criar um POD é um arquivo, e o `CODEOWNERS` é regenerado e checado no CI |
| MF-039 | **Planejamento por POD** — `next-tasks` e o board filtram por POD; Units of Work levam `owner: <pod>` | cada POD vê só as suas stories prontas e os seus bloqueios entre PODs |
| MF-040 | **Métricas e autonomia por POD** — trilha de auditoria separada por POD; autonomia conquistada e rebaixada por POD | um POD em A2 e outro em A1 no mesmo repo, ambos justificados pelos próprios dados |
| MF-041 | **Ritual de mob na Inception** — sessão síncrona curta (humanos + agentes architect/product-owner) que transforma uma Initiative em Units of Work, registrada como RFC/UoW | o resultado do ritual é uma UoW pronta com gate de saída executável |

---

## INI-03 — O Mandate como produto

*Resultado: adotar e atualizar o Mandate leva minutos, e quem adota recebe melhorias sem recopiar
arquivos.*

### UoW-08 — CLI e atualizações · **Agora**
Gate de saída: `mandate init`, `mandate verify` e `mandate upgrade` funcionam a partir de um pacote.

| ID | Story | Pronto quando |
|---|---|---|
| MF-025 | **CLI `mandate`** — `init`, `verify`, `new story|rfc|pd|adr`, `status`, empacotada para npm e pipx | `npx mandate-cli init` inicializa um repo |
| MF-026 | **Arquivos do framework × do projeto** — um manifesto do que pertence ao Mandate e do que pertence a quem adotou | `mandate upgrade` atualiza os arquivos do framework e nunca toca nos do projeto |
| MF-027 | **Adoção em projeto existente** — um guia mais um modo `adopt` que mapeia docs/issues de um repo existente para o Mandate | um repositório existente ganha o Mandate sem perder o histórico |
| MF-028 | **Plugin do Claude Code** — skills, agentes e hooks distribuídos como plugin | instalar o plugin entrega as skills sem copiar arquivos |

### UoW-09 — Visibilidade · **Depois**
Gate de saída: o estado do método é visível sem ler markdown.

| ID | Story | Pronto quando |
|---|---|---|
| MF-029 | **Painel de governança** — stories, PDs aguardando ratificação, níveis de autonomia, retrabalho, custo | uma página renderizada a partir dos arquivos do repositório |
| MF-030 | **Resumo de evidência na PR** — seção gerada com nível de rigor, resultado do `verify-all` e tabela AC × execução | toda PR aberta pelo agente traz a seção |
| MF-031 | **Site de documentação** — guia do método, pilares e exemplos publicados, EN + PT-BR | site publicado a partir de `docs/` |

---

## INI-04 — Operação e confiança

*Resultado: o Mandate cobre o sistema depois que ele chega em produção, e as ações dele próprio são
auditáveis.*

### UoW-10 — A fase Operation · **Mais adiante**
Gate de saída: ativar o gatilho de Operation instala um loop de plantão funcionando.

| ID | Story | Pronto quando |
|---|---|---|
| MF-032 | **Roster de operação** — agentes `sre-oncall`, `incident-commander`, `customer-success` com skills de runbook | o gatilho ativa o roster sem configuração manual |
| MF-033 | **Loop de incidente** — incidente → linha do tempo → postmortem → `LR-NNN` → guardrail, fechando o ciclo de aprendizado | um postmortem produz uma regra aprendida e um guardrail proposto |
| MF-034 | **Gatilho de Operation resolvível por máquina** — a condição de ativação como consulta de dado no CI | o gatilho dispara por dado, não por alguém lembrar |

### UoW-11 — Segurança e auditoria das ações dos agentes · **Depois**
Gate de saída: toda ação de agente é atribuível, e as mais arriscadas exigem uma segunda chave.

| ID | Story | Pronto quando |
|---|---|---|
| MF-035 | **Guardrails de segurança** — varredura de segredos, allowlist de dependências, nenhuma dependência nova sem RFC | commit com segredo ou dependência não aprovada reprova o CI |
| MF-036 | **Livro-razão de ações dos agentes** — registro assinado e append-only do que cada agente fez (comandos, arquivos, PRs) | o registro responde "qual agente mudou isto, em qual story e com qual nível" |
| MF-037 | **Ações de duas chaves** — operações destrutivas ou de mão única exigem confirmação humana registrada no livro-razão | uma ação de mão única sem confirmação registrada é bloqueada |

---

## Como este roadmap é governado

- Itens viram stories de verdade (arquivos de spec `MF-NNN`) só quando a Unit of Work deles começa —
  spec escrita cedo demais envelhece.
- A prioridade muda com evidência: dados do `process-metrics` e feedback real de adoção, não lista de
  desejos.
- Toda regra nova sai com o seu script (pilar **N**) e o seu teste — item de roadmap que acrescenta
  regra sem enforcement não está pronto.
