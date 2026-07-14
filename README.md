# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Deploy

Production isn't deployed on push to `main` — it's controlled by GitHub
Releases, via a workflow that validates the commit's CI status and then
triggers the Render Deploy Hook. See [`docs/deploy.md`](docs/deploy.md) for
the full flow, how to cut a release, and how to roll back.

## Exercise video compression

Uploaded exercise videos are compressed by an S3-triggered Lambda (ffmpeg),
provisioned via Terraform in `infra/terraform/`. See
[`docs/video-compression.md`](docs/video-compression.md) for the
architecture, how to apply/update the infrastructure, and troubleshooting.
