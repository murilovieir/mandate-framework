# Contribuindo com o Mandate

> 🇺🇸 English: [CONTRIBUTING.md](CONTRIBUTING.md)

Obrigado por considerar uma contribuição. O Mandate é governado pelo próprio Mandate, então contribuir
aqui também é um tour rápido pelo método.

## Antes de começar

- **Bugs e correções pequenas** — abra uma issue (ou vá direto para uma PR em caso de typo).
- **Regras, skills, agentes novos ou mudanças no método** — abra uma issue antes. O decisor (o
  mantenedor) aprova mudanças no método, como o `docs/rfc/` descreve para qualquer projeto.
- **Itens do roadmap** — escolha um `MF-NNN` do [`ROADMAP.pt-BR.md`](ROADMAP.pt-BR.md) e avise na issue
  que vai pegar, para duas pessoas não construírem a mesma coisa.

## Como mandar uma mudança

1. Faça o fork e crie a branch a partir da `develop`: `feat/MF-NNN-slug-curto` (ou `fix/…`, `docs/…`).
2. Instale os hooks uma vez: `git config core.hooksPath scripts/guardrails/git-hooks`.
3. Todo commit termina com um rodapé que referencia o trabalho: `Refs: MF-NNN` (story do roadmap) ou
   `Refs: RFC-NNN`. O hook `commit-msg` aplica isso.
4. Rode o comando único de verificação — é exatamente o que o CI roda:
   ```bash
   ./scripts/guardrails/verify-all.sh
   ```
   Check que não pôde rodar aparece como `not verified` e reprova. Não esconda; explique na PR.
5. Abra a PR contra a **`develop`**, nunca a `main`. A `main` só avança por fast-forward, via
   `scripts/promote-develop.sh`.

## Como é uma boa mudança

- **Regra nova vem com script e teste.** Pilar **N**: regra sem script é desejo. Todo guardrail tem
  teste que prova um caso que passa e um que falha.
- **Agnóstica de stack, domínio e ferramenta.** Nada que só faça sentido para uma linguagem, nuvem ou
  domínio de negócio. O que é específico de projeto fica no `governance.env` ou nos arquivos de quem adota.
- **Docs bilíngues em sincronia.** Docs de método existem em EN (canônico) e PT-BR; mude os dois,
  mantendo os títulos numerados idênticos. Artefatos executáveis (skills, agentes, scripts) são só EN.
- **Pequena.** Uma story por PR, no tamanho da RULE-TASK-01 (≤ 5 critérios de aceite, ≤ 8 arquivos).

## Licença

Ao contribuir, você concorda que as suas contribuições são licenciadas sob a [Licença MIT](LICENSE).
