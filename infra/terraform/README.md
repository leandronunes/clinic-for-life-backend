# Infraestrutura — compressão de vídeo de exercício

Provisiona a Lambda `video-compressor` (ffmpeg) e o gatilho de evento S3
descritos em `../../docs/video-compression.md` — leia esse documento antes
de rodar qualquer coisa aqui (pré-requisitos, bootstrap do state, ordem dos
comandos, e os cuidados com `aws_s3_bucket_notification`/
`aws_s3_bucket_lifecycle_configuration`, que são autoritativos sobre a
configuração inteira do bucket).

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```
