# Clinic for Life — Backend

Rails 8.1 API-only, Ruby 3/4, PostgreSQL, JWT, RSpec. Serve o frontend React de `../clinic-for-life`.

## Stack

- Rails 8.1 (API-only) + Ruby
- PostgreSQL + Active Record
- `has_secure_password` + JWT (`JsonWebToken`) para autenticação
- Serializers PORO em `app/serializers/`
- RSpec + FactoryBot + SimpleCov (cobertura ≥ 90%)
- Rubocop (rubocop-rails-omakase), Brakeman, bundler-audit

## Regras obrigatórias — sempre seguir

### Models e migrations
- Validações de presença, formato e unicidade adequadas; **índices únicos no banco** (não só na validação).
- `t.references` já cria índice — não duplicar `add_index`.
- Migrations reversíveis (`change` ou `up`+`down`); não podem quebrar `db:reset`.
- Model magro: regras de negócio complexas fora dele (Clean Architecture). Sem lógica de domínio inchando o model.
- Associações com `dependent:` correto; sem registros órfãos.

### Controllers e concerns
- Controllers finos — lógica de domínio em service/PORO/concern.
- **Strong parameters (`permit`)** em todos os endpoints — sem mass assignment.
- `before_action` para autenticação/autorização e carregamento de recursos.
- **Sem double render**: guards que renderizam e são chamados inline usam `return if performed?`.
- Tratamento de erro padronizado via `render_unprocessable`, `render_not_found`, etc.
- Sem duplicação entre controllers — extrair para concern.

### Autenticação e autorização
- **`JsonWebToken.encode` recebe hash explícito** (Ruby 4): `encode({ sub: id, email: email, role: role })` — nunca keyword args.
- **`require_role!` nunca chamado sem argumentos** (retornaria 403 sempre).
- Escopo por papel (admin/personal/student) aplicado corretamente em cada action.
- Autorização por dono do recurso: aluno só acessa o próprio dado; personal só acessa seus alunos.
- Sem vazar dados de outros usuários nas queries ou respostas.

### Serializers e envelope de resposta
- **Respostas no envelope `{ data, meta }`** via `render_data`; erros em `{ error: ... }`.
- **Status HTTP corretos** (Rails 8/Rack 3): 422 = `:unprocessable_content`, não `:unprocessable_entity`.
- Campos alinhados aos tipos consumidos pelo frontend (ver `src/lib/api/` no projeto frontend).
- Consistência de chaves: símbolos nos serializers PORO.

### Segurança
- **Sem segredos no código** — usar Rails credentials ou ENV.
- **SQL parametrizado sempre** — proibido interpolar input do usuário em `where`/`find_by_sql`.
- Strong params previnem mass assignment de campos sensíveis.
- Preservar configurações de rack-attack e rack-cors.
- Atenção a IDOR, exposição de dados e OWASP Top 10.

### Performance
- **Sem N+1**: usar `includes`/`preload`/`eager_load` onde necessário.
- Colunas filtradas e ordenadas com frequência devem ter índice.
- Sem queries dentro de loops; operações em lote quando possível.

### Regras de negócio críticas
- Um aluno pode ter **múltiplos treinos ativos** simultaneamente; criar ou ativar um treino não afeta os demais.
- Preservar invariantes ao alterar controllers/models.

### Testes (RSpec)
- **Sempre gere testes** para o que foi criado/alterado (model spec, request spec, ou ambos).
- `bundle exec rspec` deve passar com **cobertura de linha ≥ 90%**.
- Request specs com status corretos (`:unprocessable_content` para 422).
- FactoryBot para fixtures; sem dependência de rede externa.
- Evitar `validate_uniqueness_of` do shoulda em coluna numérica — use `build(...).not_to be_valid`.
- Preparar schema de teste quando necessário: `RAILS_ENV=test bin/rails db:test:prepare`.

### Qualidade e estilo
- `bin/rubocop` sem offenses (rubocop-rails-omakase).
- `bin/brakeman` sem warnings novos.
- `bin/bundler-audit` sem CVEs pendentes.
- Sem código duplicado — extrair para concern, service/PORO ou helper.
- Backend em **inglês**; dados e labels de domínio em pt-br quando aplicável.

## Estrutura de resposta da API

```ruby
# Sucesso
render_data(payload)                      # { data: payload }
render_data(payload, meta: { total: n })  # { data: payload, meta: { total: n } }
render_data(payload, status: :created)

# Erros (já tratados pelo BaseController rescue_from)
render json: { error: "mensagem" }, status: :unprocessable_content
render json: { error: "mensagem" }, status: :unauthorized
render json: { error: "mensagem" }, status: :forbidden
```

## Papéis de usuário

| role      | acesso                                      |
|-----------|---------------------------------------------|
| `admin`   | tudo                                        |
| `personal`| apenas seus alunos (`trainer_id`)           |
| `student` | apenas o próprio registro (`student_id`)    |

## Documentação da API (OpenAPI)

- Especificação em `swagger/v1/swagger.yaml` (OpenAPI 3.0.3), servida via `rswag-api`/`rswag-ui`.
- Swagger UI em `/api-docs`; documento bruto em `/api-docs/v1/swagger.yaml`.
- Sempre montado em `development`/`test`; em produção requer `ENABLE_API_DOCS=true` (ver `config/routes.rb`) para não expor o formato da API publicamente por padrão.
- **Ao adicionar/alterar endpoint, atualize `swagger/v1/swagger.yaml` no mesmo PR** (paths, schemas, respostas de erro).
- Valide com `npx @redocly/cli lint swagger/v1/swagger.yaml` antes de commitar.

## Contract testing (Pact)

- Este backend é **provider**. Ver `docs/pact.md` para arquitetura, como rodar, como adicionar um novo contrato e como depurar falhas.
- **Ao adicionar/alterar endpoint consumido pelo frontend, atualize o provider state correspondente em `spec/pact/support/states/`** (registrado em `spec/pact/consumers/backend_provider_spec.rb`) no mesmo PR.
- `bundle exec rake pact:verify` — nunca roda dentro de `bundle exec rspec` nem conta na cobertura do SimpleCov.

## Controle de versão

- **Nunca faça `git commit` ou `git push` sem autorização expressa do usuário.** Sempre deixe as alterações no working tree para revisão antes de perguntar se deve commitar.
- Mesmo que o usuário tenha autorizado commit/push antes, isso não vale para novas alterações — peça confirmação novamente a cada vez.

## Comandos úteis

```bash
bin/rails server -p 3002          # dev server
bundle exec rspec                 # suite completa
bundle exec rspec spec/path/file  # spec específico
bin/rubocop                       # lint
bin/brakeman                      # security scan
bin/rails db:migrate
RAILS_ENV=test bin/rails db:migrate
npx @redocly/cli lint swagger/v1/swagger.yaml   # valida a especificação OpenAPI
bundle exec rake pact:verify                    # verifica contratos Pact — ver docs/pact.md
```
