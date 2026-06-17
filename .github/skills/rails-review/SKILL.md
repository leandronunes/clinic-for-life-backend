---
name: rails-review
description: 'Revisa código do backend Clinic for Life (Rails 8.1 API-only, Ruby 4, PostgreSQL, JWT, serializers, RSpec). Use quando o usuário pedir "rails review", "revisar PR", "revisar código", "analisar mudanças", "verificar boas práticas", checar antes de commitar/abrir PR, ou validar aderência às convenções do projeto. Cobre models/migrations, controllers/concerns, autenticação/autorização (JWT, roles), serializers, segurança, performance (N+1) e testes RSpec.'
argument-hint: 'Arquivos, pasta, diff ou branch a revisar (ex.: app/controllers/api/v1/workouts_controller.rb ou "mudanças no branch atual")'
---

# Rails Review — Backend Clinic for Life

Revisão de código sistemática e acionável para esta API Rails. Produz um parecer
organizado por severidade, com referências a arquivos/linhas e sugestões de
correção alinhadas às convenções do repositório (`.github/copilot-instructions.md`).

## Quando usar

- Antes de abrir/aprovar um PR ou commitar mudanças relevantes.
- Quando pedirem "revisar este código/arquivo/diff/branch".
- Para auditar aderência aos padrões do projeto (Clean Architecture, segurança, testes).

## Procedimento

### 1. Delimitar o escopo
- Se o usuário indicou arquivos/pasta/branch, revise apenas isso.
- Caso contrário, descubra o que mudou:
  - `git diff --name-only` e `git diff` (working tree), ou
  - `git diff main...HEAD` para o branch atual.
- Leia os arquivos alterados por completo antes de comentar; entenda o contexto
  (model, migration, controller, concern, serializer, spec) — não revise trechos
  isolados. Consulte `db/schema.rb` quando avaliar models/queries.

### 2. Rodar as verificações automáticas
Execute e considere os resultados na revisão:
- `bin/rubocop` — estilo (rubocop-rails-omakase). Reporte offenses.
- `bin/brakeman` — análise estática de segurança.
- `bin/bundler-audit` — CVEs em gems.
- `bundle exec rspec` — toda a suíte deve passar (gate de cobertura `line: 90`).
  Use `RAILS_ENV=test bin/rails db:test:prepare` se o schema de teste estiver defasado.
Reporte falhas como bloqueadores.

### 3. Revisar contra o checklist
Use [checklist.md](./checklist.md) como guia. Foque em:
- **Models/migrations**: validações e índices (únicos) adequados; `t.references`
  já cria índice — não duplicar `add_index`; migrations reversíveis; sem lógica
  de negócio inchando o model (Clean Architecture).
- **Controllers/concerns**: finos, com `before_action` e `strong parameters`;
  lógica de domínio fora do controller; tratamento de erro padronizado
  (`render_unprocessable` etc.); cuidado com double render — chamadas inline de
  guards que renderizam devem usar `return if performed?`.
- **Autenticação/autorização**: JWT via `JsonWebToken` (no Ruby 4 passar hash
  explícito: `encode({ sub: ... })`, nunca keyword args); `Authenticable`/
  `Authorizable`; `require_role!` **nunca** sem argumentos (retorna 403); escopo
  por papel (admin/personal/aluno) e por dono do recurso.
- **Serializers**: resposta no envelope `{ data, meta }`; erros em `{ error: ... }`;
  manter alinhamento com os tipos do frontend; atenção à mistura de chaves
  string vs símbolo (ver `AnamnesisSerializer`).
- **Segurança**: sem segredos no código (usar credentials/ENV); strong params
  contra mass assignment; SQL parametrizado (sem interpolação em `where`);
  rack-attack/rack-cors preservados; OWASP Top 10.
- **Performance**: evitar N+1 (`includes`/`preload`); índices nas colunas
  filtradas; sem queries dentro de loops.
- **Regras de negócio**: ex.: aluno tem 1 único treino ATIVO (ao ativar novo, os
  anteriores são arquivados) — preservar invariantes ao alterar controllers/models.
- **Testes RSpec**: cobertura para o que mudou; request specs com status corretos
  (Rails 8/Rack 3: 422 = `:unprocessable_content`); FactoryBot; sem dependência
  de rede; evitar `validate_uniqueness_of` shoulda em coluna numérica (usar
  `build(...).not_to be_valid`).
- **Duplicação**: extrair para concerns, services/POROs ou helpers.

### 4. Emitir o parecer
Estruture o resultado por severidade, sempre com link para arquivo/linha e
sugestão concreta de correção:

- **🔴 Bloqueadores** — bugs, falhas de rubocop/brakeman/rspec, riscos de
  segurança, violações de invariantes de negócio, double render, N+1 graves,
  migrations irreversíveis/quebradas.
- **🟡 Melhorias** — duplicação, lógica no lugar errado (gordura de controller/model),
  falta de testes, índices ausentes, nomenclatura.
- **🟢 Observações** — sugestões opcionais, nitpicks, elogios.

Se nada relevante for encontrado em uma categoria, diga explicitamente.
Seja específico e objetivo: aponte o problema, o porquê e como corrigir.

## Referências
- Convenções do projeto: `.github/copilot-instructions.md`
- Schema do banco: `db/schema.rb`
- Rotas: `config/routes.rb`
- Checklist detalhado: [checklist.md](./checklist.md)
