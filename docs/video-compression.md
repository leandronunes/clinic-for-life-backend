# Compressão automática de vídeos de exercício

Vídeos de exercício são enviados direto do navegador para o S3 via PUT
pré-assinado (`S3Presigner#presign`, `POST /api/v1/uploads/presign`). Um
vídeo gravado no celular pode chegar grande (até 200MB — limite do
frontend). Uma Lambda, disparada automaticamente por um evento S3, roda
ffmpeg para reduzir o tamanho antes de o vídeo ficar disponível para
visualização.

## Arquitetura

```
Frontend                              S3 (bucket "clinic-for-life")
  PUT no raw key ──────────────────→   uploads/raw/students/7/exercise_video/<uuid>.mp4
                                            │ ObjectCreated (prefixo uploads/raw/)
                                            ▼
                                      Lambda "video-compressor" (ffmpeg)
                                            │ GetObject (raw) + ffmpeg + PutObject (final)
                                            ▼
                                      uploads/students/7/exercise_video/<uuid>.mp4
                                        (chave final — já era o que public_url
                                         sempre apontou, sem update de banco)
  GET (via presign_get_for)  ◄──────────────┘
```

A mesma Lambda também é disparada para uploads feitos a partir do ambiente
de desenvolvimento local, contra o mesmo bucket — só que sob o prefixo
`dev/` (ver `S3Presigner#env_prefix`). O evento S3 tem um segundo gatilho
dedicado ao prefixo `dev/uploads/raw/`, e o rewrite de chave da própria
Lambda só troca o segmento `uploads/raw/` por `uploads/`, preservando
qualquer prefixo antes dele:

```
dev/uploads/raw/students/7/exercise_video/<uuid>.mp4
    → dev/uploads/students/7/exercise_video/<uuid>.mp4
```

Ou seja, vídeo de dev processado fica em `dev/uploads/...`, vídeo de
produção fica em `uploads/...` — os dois namespaces nunca se cruzam, e o
mesmo código/IAM/lifecycle cobrem ambos (ver `infra/terraform/
s3_notification.tf`, `iam.tf`, `s3_lifecycle.tf`).

`S3Presigner#presign` (`app/lib/s3_presigner.rb`) já retorna, desde o
primeiro request, a `public_url` apontando para a chave **final** — a
mesma que sempre foi persistida como `exercise.video_url`. Só o PUT do
upload em si mira uma chave **raw** transitória (só para
`context == "exercise_video"`; os demais contextos — fotos, exames, logo —
continuam com uma única chave, como sempre). Por isso **nenhum update de
banco é necessário** depois que a Lambda termina: a URL certa já estava lá
desde o começo, só o arquivo nela demora alguns segundos a aparecer.

### Por que não há webhook nem status no banco

Este backend não tem fila durável (`ActiveJob` cai no adapter `:async`
in-process — não configurado explicitamente, ver `config/environments/
production.rb`), então uma Lambda não teria como notificar o Rails de
forma confiável quando terminasse. Em vez de adicionar uma coluna de
status + endpoint de webhook autenticado, o frontend trata o 404
transitório (enquanto a Lambda ainda está processando) com uma UI de
fallback e retry manual — ver `VideoPlayer.tsx` no repo do frontend.

## Como aplicar/atualizar a infraestrutura (Terraform)

Toda a infra desta feature vive em `infra/terraform/` — o **primeiro**
código de infraestrutura deste monorepo (o resto da infra AWS é
console-manual, ver `docs/deploy.md`).

### Pré-requisitos (uma vez)

1. Terraform **≥ 1.10** (o locking nativo em S3, `use_lockfile`, só existe
   a partir daí — evita precisar de uma tabela DynamoDB). Instale via
   [tfenv](https://github.com/tfutils/tfenv) ou baixando o binário direto.
2. Bucket de state, criado manualmente uma única vez (Terraform não
   consegue criar o bucket que guarda o próprio state):
   ```bash
   aws s3api create-bucket --bucket clinic-for-life-terraform-state --region us-west-2 \
     --create-bucket-configuration LocationConstraint=us-west-2
   aws s3api put-bucket-versioning --bucket clinic-for-life-terraform-state \
     --versioning-configuration Status=Enabled
   aws s3api put-bucket-encryption --bucket clinic-for-life-terraform-state \
     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
   aws s3api put-public-access-block --bucket clinic-for-life-terraform-state \
     --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
   ```
3. **Antes do primeiro `apply`**, tire uma foto do que já existe
   manualmente no bucket da aplicação — `aws_s3_bucket_notification` e
   `aws_s3_bucket_lifecycle_configuration` são *autoritativos*: o Terraform
   substitui a configuração **inteira** do bucket a cada apply, não só a
   regra que ele define.
   ```bash
   aws s3api get-bucket-notification-configuration --bucket clinic-for-life
   aws s3api get-bucket-lifecycle-configuration --bucket clinic-for-life
   ```
   Se qualquer uma retornar regras existentes, incorpore-as em
   `infra/terraform/s3_notification.tf`/`s3_lifecycle.tf` (blocos adicionais
   `lambda_function`/`topic`/`queue`/`rule`) antes de aplicar — do
   contrário elas somem silenciosamente.
4. O binário do ffmpeg é provisionado pelo próprio Terraform
   (`ffmpeg_layer.tf`), implantando a aplicação `ffmpeg-lambda-layer` do
   AWS Serverless Application Repository (projeto
   [`serverlesspub/ffmpeg-aws-lambda-layer`](https://github.com/serverlesspub/ffmpeg-aws-lambda-layer),
   autor verificado pela AWS, Gojko Adzic) — não é um ARN público
   compartilhado entre contas; o `apply` cria essa layer na nossa própria
   conta. Nenhum passo manual necessário para isso.

### Aplicando

```bash
cd infra/terraform
terraform init
terraform plan     # revisar com cuidado qualquer diff em notification/lifecycle
terraform apply
```

`terraform apply` é um processo manual/local por enquanto (não entra no
CI) — consistente com o processo de release deste projeto, que também é
disparado manualmente (`gh release create`, ver `docs/deploy.md`).

### Atualizando só o código da Lambda

Editar `infra/terraform/lambda/video-compressor/index.mjs` e rodar
`terraform apply` de novo — o `archive_file` recalcula o hash do zip e força
a atualização da função.

## Como testar ponta a ponta

1. `terraform apply` (acima).
2. Como personal, gravar/enviar um vídeo real de exercício pelo app.
3. Acompanhar os logs: `aws logs tail /aws/lambda/video-compressor --follow`
   — esperar a sequência `{"msg":"start",...}` → `{"msg":"ffmpeg ok"}` →
   `{"msg":"done",...}`.
4. Confirmar que o arquivo final encolheu:
   `aws s3api head-object --bucket clinic-for-life --key uploads/students/<id>/exercise_video/<uuid>.mp4`
   — `ContentLength` menor que o vídeo original.
5. Abrir "Ver execução" logo após o upload — o `VideoPlayer` deve mostrar o
   fallback ("vídeo ainda sendo processado") por alguns segundos; clicar em
   "Tentar novamente" até o vídeo comprimido tocar.

## Troubleshooting via CloudWatch Logs

| Sintoma | Onde olhar |
|---|---|
| Vídeo nunca aparece, mesmo depois de minutos | A Lambda foi sequer invocada? Confirme que a chave do upload bate com um dos dois prefixos do evento: `uploads/raw/` (produção) ou `dev/uploads/raw/` (dev local) — ver `infra/terraform/s3_notification.tf`. |
| Log mostra `"msg":"FAILED"` com `ffmpeg exited N: ...` | Erro do próprio ffmpeg — o final da mensagem traz a cauda do stderr (últimas ~4000 chars). Formatos/codecs inesperados do vídeo de origem costumam aparecer aqui. |
| Log mostra `"msg":"FAILED"` sem chegar a rodar o ffmpeg | Provável falha na camada (`ffmpeg_layer_arn` desatualizado/binário ausente) — confira `FFMPEG_PATH` e se a layer configurada ainda expõe `/opt/bin/ffmpeg`. |
| Nada nos logs | Confira `aws_lambda_permission`/`aws_s3_bucket_notification` no `terraform apply` — sem a permissão, o S3 não consegue invocar a função. |

## Racional dos parâmetros do ffmpeg

- **H.264 (`libx264`) + AAC em MP4**: compatibilidade universal com
  qualquer navegador/dispositivo, sem plugins.
- **Limite de 720p, nunca upscale** (`scale='min(1280,iw)':'min(720,ih)'`):
  vídeos de demonstração de exercício não precisam de mais resolução que
  isso para o aluno acompanhar a execução — a maior parte da redução de
  tamanho vem daqui.
- **CRF 26 + preset `fast`**: equilíbrio entre qualidade e tempo de
  Lambda (CPU é proporcional à memória alocada — mais preset "lento" reduz
  o arquivo um pouco mais, mas custa mais tempo de execução).
- **`+faststart`**: move o índice do MP4 para o início do arquivo, para o
  `<video>` da própria página começar a tocar antes do download completo
  (o app reproduz direto de uma URL pré-assinada do S3, sem servidor de
  streaming próprio).

## Riscos e limitações conhecidas

- **Sem DLQ**: se todas as tentativas automáticas da Lambda falharem
  (retry padrão do S3/Lambda: 2 tentativas), a chave final nunca é criada.
  Recuperação manual só é possível dentro da janela de 1 dia antes do
  lifecycle expirar o objeto raw (`aws s3 cp` do raw para local, rodar o
  mesmo comando ffmpeg manualmente, subir o resultado na chave final — ou
  mais simples, `aws s3 cp <raw-key> <raw-key> --metadata-directive REPLACE`
  para reemitir o evento e tentar a pipeline de novo).
- **ffmpeg 4.1.3, uma versão antiga (a layer SAR não foi atualizada desde
  2019)**: suficiente para os codecs comuns (H.264/AAC), mas se algum
  formato de origem mais novo não for suportado, ou se a aplicação SAR
  parar de existir no futuro, a alternativa é migrar para uma imagem de
  container (Docker + ECR) com um build de ffmpeg mais recente — não
  implementado nesta v1.
- **Dev e produção compartilham a mesma Lambda e o mesmo bucket**: um
  upload feito localmente contra o bucket real de produção (com
  `S3_BUCKET`/credenciais configuradas em dev) também dispara a
  compressão, sob o prefixo `dev/uploads/raw/`. Isso é intencional (para
  testar a pipeline fim a fim sem precisar de infraestrutura própria por
  ambiente — ver "Como testar ponta a ponta"), mas significa que testes
  locais consomem a mesma cota de invocações/CPU da Lambda que a
  produção. Não há isolamento de custo entre os dois ambientes.
