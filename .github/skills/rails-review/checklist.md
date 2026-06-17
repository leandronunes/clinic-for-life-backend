# Checklist de Rails Review — Backend Clinic for Life

Marque cada item ao revisar. Itens com 🔴 são bloqueadores quando violados.

## Models e migrations
- [ ] Validações de presença/formato/unicidade adequadas no model.
- [ ] 🔴 Índices únicos no banco para o que precisa ser único (não só validação).
- [ ] `t.references` usado sem `add_index` duplicado (já cria índice).
- [ ] Migrations reversíveis (`change`/`up`+`down`) e sem quebrar `db:reset`.
- [ ] Model magro: regra de negócio complexa fora dele (Clean Architecture).
- [ ] Associações com `dependent:` correto; sem órfãos.

## Controllers e concerns
- [ ] Controller fino; lógica de domínio extraída (service/PORO/concern).
- [ ] 🔴 Strong parameters (`permit`) — sem mass assignment.
- [ ] `before_action` para autenticação/autorização e carregamento de recursos.
- [ ] 🔴 Sem double render: guards que renderizam e são chamados inline usam
      `return if performed?`.
- [ ] Tratamento de erro padronizado (`render_unprocessable` etc.).
- [ ] Sem duplicação entre controllers (extrair para concern).

## Autenticação e autorização
- [ ] 🔴 `JsonWebToken.encode` recebe hash explícito (Ruby 4 — sem keyword args).
- [ ] 🔴 `require_role!` nunca chamado sem argumentos (retorna 403).
- [ ] Escopo por papel (admin/personal/aluno) aplicado corretamente.
- [ ] Autorização por dono do recurso (aluno só acessa o próprio dado).
- [ ] Sem vazar dados de outros usuários nas queries/respostas.

## Serializers e API
- [ ] Resposta no envelope `{ data, meta }`; erros em `{ error: ... }`.
- [ ] Status HTTP corretos (Rails 8/Rack 3: 422 = `:unprocessable_content`).
- [ ] Campos alinhados aos tipos consumidos pelo frontend.
- [ ] Atenção à consistência de chaves string vs símbolo nos serializers.

## Segurança
- [ ] 🔴 Sem segredos/credenciais no código (usar credentials/ENV).
- [ ] 🔴 SQL parametrizado; sem interpolação de input em `where`/`find_by_sql`.
- [ ] Strong params previnem mass assignment de campos sensíveis.
- [ ] rack-attack (throttle) e rack-cors preservados/configurados.
- [ ] Atenção a IDOR, exposição de dados e demais itens do OWASP Top 10.

## Performance
- [ ] 🔴 Sem N+1: usa `includes`/`preload`/`eager_load` onde necessário.
- [ ] Colunas filtradas/ordenadas possuem índice.
- [ ] Sem queries dentro de loops; usa operações em lote quando possível.

## Regras de negócio
- [ ] Invariantes preservadas (ex.: aluno tem 1 único treino ATIVO; ao ativar
      novo, os anteriores são arquivados).
- [ ] Estados/transições válidos; sem efeitos colaterais inesperados.

## Testes (RSpec)
- [ ] Há testes para o que foi alterado (model/request/serializer).
- [ ] 🔴 `bundle exec rspec` passa e a cobertura de linha ≥ 90%.
- [ ] Request specs com status corretos (`:unprocessable_content` p/ 422).
- [ ] FactoryBot para dados; sem dependência de rede.
- [ ] Evita `validate_uniqueness_of` (shoulda) em coluna numérica — usar
      `build(...).not_to be_valid`.

## Qualidade e estilo
- [ ] 🔴 `bin/rubocop` sem offenses (rubocop-rails-omakase).
- [ ] 🔴 `bin/brakeman` sem warnings novos.
- [ ] `bin/bundler-audit` sem CVEs pendentes.
- [ ] Sem código duplicado (extrair concern/service/helper).
- [ ] Backend em inglês; dados/labels de domínio em pt-br quando aplicável.
