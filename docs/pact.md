# Contract Testing (Pact) — Backend / Provider

Este backend é **provider** — nunca consumer — dos contratos definidos pelo
frontend (`clinic-for-life`, repo irmão). A verificação garante que os
controllers/serializers reais desta API continuam batendo com o que o
frontend espera, sem depender de um ambiente de integração completo.

Arquitetura resumida:

```
Frontend (consumer)                     Backend (provider, este repo)
  *.pact.test.ts
    ↓ gera
  pacts/clinic-for-life-clinic-for-life-backend.json
    ↓ publica (CI, push em main)                    bundle exec rake pact:verify
  Pact Broker  ───────────────────────────────────────────→  busca o pact
                                                              boota a app real
                                                              repete cada interação
                                                              compara request/response
```

## Como rodar localmente

Sem Broker configurado (mais comum no dia a dia — aponta direto para o
arquivo gerado pelo frontend):

```bash
# no repo do frontend, gera/atualiza pacts/clinic-for-life-clinic-for-life-backend.json
cd ../clinic-for-life && npm run test:pact

# de volta aqui, verifica contra esse arquivo
cd ../clinic-for-life-backend
PACT_URL="../clinic-for-life/pacts/clinic-for-life-clinic-for-life-backend.json" \
  bundle exec rake pact:verify
```

Com Broker configurado (`.env`: `PACT_BROKER_BASE_URL`, `PACT_BROKER_TOKEN`):

```bash
bundle exec rake pact:verify
```

Sem `PACT_URL` nem `PACT_BROKER_BASE_URL`, cai no default: procura um
diretório `pacts/` na raiz deste repo (não existe por padrão — só faz
sentido para depuração manual colocando um arquivo ali).

## Como rodar no CI

Job `pact_verify` em `.github/workflows/ci.yml`, independente de
`scan_ruby`/`lint`/`test` — uma falha de Broker não deve travar os outros
checks. Roda em todo PR e push. Requer os secrets `PACT_BROKER_BASE_URL` e
`PACT_BROKER_TOKEN` configurados no repositório GitHub; sem eles, o job falha
com "no pacts found" (comportamento esperado até esses secrets serem
configurados — ver Limitações).

## Como adicionar um novo contrato

Todo o registro de estados do provider vive em **um único** ponto de entrada:
`spec/pact/consumers/backend_provider_spec.rb` (nome do diretório é
proposital — veja o comentário no topo do arquivo). `http_pact_provider` só
pode ser declarado uma vez por execução, então **nunca** crie um novo
`RSpec.describe` com `http_pact_provider` — sempre estenda o existente.

1. Crie (ou edite) `spec/pact/support/states/<dominio>.rb`:

   ```ruby
   module PactStates
     module SeuDominio
       def self.definitions
         proc do
           provider_state "descrição do estado, deve bater com o .given(...) do consumer" do
             set_up do
               clean_database!   # sempre primeiro — ver "Detalhes técnicos"
               # ... FactoryBot.create(...) o necessário ...
               PactStateContext.as(FactoryBot.create(:user, :admin))  # se o endpoint exige auth
             end
           end
         end
       end
     end
   end
   ```

2. Registre em `backend_provider_spec.rb`:
   ```ruby
   instance_eval(&PactStates::SeuDominio.definitions)
   ```
3. No frontend, escreva o `*.pact.test.ts` correspondente (ver
   `../clinic-for-life/docs/pact.md`) usando **exatamente** a mesma string em
   `.given(...)`.
4. Rode o ciclo local (gerar no frontend → verificar aqui) até fechar.

## Detalhes técnicos que importam ao mexer nisso

- **IDs fixos nos states**: sempre que o consumer referencia um ID na URL
  (`/api/v1/students/501`), crie o registro com `id: 501` explícito no
  `FactoryBot.create` — não confie em autoincremento.
- **`clean_database!` é obrigatório no início de todo `set_up`**: o
  verificador FFI tenta de novo um `set_up` que falhou antes de desistir, e
  os estados podem ser reexecutados fora de ordem (ex.: filtrando por
  `PACT_PROVIDER_STATE`). `DatabaseCleaner.clean_with(:truncation)` (via o
  helper `clean_database!`) garante que cada tentativa comece de uma faixa
  limpa — sem isso, colisões de unicidade (email, `measured_on`, etc.)
  aparecem de forma intermitente. Não use `config.before(:each)` do RSpec
  para isso: só roda uma vez por execução inteira, não por interação.
- **Autenticação**: `PactStateContext.as(user)` (em `spec/pact/support/jwt_fixtures.rb`)
  marca qual usuário autentica a *próxima* requisição. Um middleware Rack
  (`PactAuthOverride`) troca o header `Authorization` do consumer (que é só
  um valor fake batendo com o formato de um JWT) por um token real, minerado
  com `JsonWebToken.encode` — o mesmo código que os controllers usam. É
  "single-shot": consumido e limpo assim que usado, para não vazar para a
  próxima interação sem estado (cenários 401 "sem token").
- **`http_port` fixo**: `spec/pact/consumers/backend_provider_spec.rb` passa
  `http_port: 4567` (não `0`/efêmero) porque o verificador FFI recebe a porta
  *antes* do WEBrick de fato bindar uma — com porta efêmera os dois
  discordam sobre onde mandar a requisição.
- **WEBrick exige `Content-Length` em todo POST/PUT sem corpo**
  (`spec/pact/support/webrick_patch.rb` desliga essa checagem só para este
  suite). Produção roda Puma, não WEBrick — isso nunca afeta usuários reais.
- **`spec/pact/**` nunca conta na cobertura do SimpleCov nem roda dentro de
  `bundle exec rspec`** — tem `.rspec-pact` e require chain próprios
  (`spec/pact/pact_helper.rb`), e o `.rspec` da raiz exclui
  `spec/pact/**/*_spec.rb` explicitamente.

## Como depurar uma falha

Rode com o pact local (`PACT_URL=...`) para ver a saída completa — o job de
CI só mostra o resumo do RSpec, mas localmente o log do verificador (nível
`:info` por padrão) mostra cada requisição e o mismatch exato.

| Sintoma no output | Causa provável |
|---|---|
| `Could not load pacts from directory` / `no pacts found` | `PACT_URL`/`PACT_BROKER_BASE_URL` não configurado, ou Broker sem esse consumer publicado ainda |
| `expected 200 but was 404` | Endpoint foi removido/renomeado no backend, ou a rota mudou — confira `config/routes.rb` |
| `expected 200 but was 401/403` | Mudou uma regra de autorização; o provider state precisa autenticar com outro papel (`PactStateContext.as(...)`) |
| `Expected null (Null) to be the same type as '...'` | O state não populou um campo que o consumer espera preenchido (ou vice-versa) — ajuste o `FactoryBot.create` no state ou o matcher no consumer |
| `Expected a List with N elements but received M` | Consumer usou array literal (`[x]`) em vez de `eachLike(x, min)`, ou o state criou uma quantidade diferente da esperada |
| `Failed to parse the actual body: 'expected value at line 1 column 1'` junto com status inesperado | Corpo da resposta veio vazio — geralmente sintoma de um erro 411/500 anterior ao handler da action rodar; olhe o status real primeiro |
| `Email has already been taken` / outro erro de unicidade nos logs do `set_up` | `clean_database!` não está no topo do `set_up`, ou dados de uma tentativa anterior ficaram (rode `Model.delete_all` manualmente se estiver depurando fora do CI) |

## Riscos e limitações conhecidas

1. **DSL da gem `pact` 2.x é recente e pouco documentada** fora deste
   próprio código — se um upgrade futuro quebrar, o fallback é `pact ~> 1.67`
   (API clássica `Pact.service_provider`/`honours_pact_with`, bem mais
   documentada, mesma compatibilidade com Rack 3).
2. **Sem Broker configurado ainda**, o job `pact_verify` do CI falha com "no
   pacts found" até `PACT_BROKER_BASE_URL`/`PACT_BROKER_TOKEN` serem
   adicionados como secrets do repositório.
3. **`can-i-deploy` não está automatizado** — nenhum dos dois repos tem
   workflow de deploy ainda. Quando existir, adicione antes do passo de
   deploy real:
   ```bash
   bundle exec pact-broker can-i-deploy \
     --pacticipant clinic-for-life-backend \
     --version "$(git rev-parse HEAD)" \
     --to-environment production
   ```
4. **Profundidade de cobertura**: os domínios `auth` e `students` têm
   contratos exaustivos (todo verbo, todo tipo de matcher, nulos, arrays
   vazios/cheios, todos os erros aplicáveis) — servem de referência. Os
   outros 12 domínios têm contrato para **todo** endpoint (critério de
   aceite atendido), mas com cenários mais enxutos (feliz + erros de
   auth/validação centrais). Estenda um domínio existente seguindo o mesmo
   padrão sempre que precisar de mais profundidade nele.
