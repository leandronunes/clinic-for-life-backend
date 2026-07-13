source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# JSON Web Tokens for stateless authentication
gem "jwt", "~> 3.2"

# CSV parsing for bioimpedance imports (removed from Ruby default gems in 3.4+)
gem "csv"

# PDF text extraction for bioimpedance imports (InBody/mynutri reports)
gem "pdf-reader", "~> 2.15"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.0"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# Throttle and block abusive requests
gem "rack-attack"

# AWS S3 — presigned URL generation for direct video uploads
gem "aws-sdk-s3", "~> 1.170", require: false

# Serves the static OpenAPI document and an interactive Swagger UI at /api-docs
gem "rswag-api"
gem "rswag-ui"
# ostruct left Ruby's default gems in 4.0; rswag-ui still requires it but doesn't declare it
gem "ostruct"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Loads environment variables from .env files
  gem "dotenv-rails"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec test framework for Rails
  gem "rspec-rails", "~> 8.0"

  # Fixtures replacement to build test data
  gem "factory_bot_rails", "~> 6.4"

  # One-liner matchers for common Rails validations/associations
  gem "shoulda-matchers", "~> 8.0"

  # Generates synthetic PDF fixtures for MynutriPdfParser specs
  gem "prawn", require: false
  # prawn depends on matrix, removed from Ruby default gems in 3.1+
  gem "matrix", require: false
end

group :test do
  # SQLite for testing
  gem "sqlite3", ">= 2.1"
  # Code coverage analysis
  gem "simplecov", "~> 0.22", require: false

  # Consumer-driven contract testing (provider verification against the frontend's pacts)
  # pact/rspec requires the "rspec" meta-gem directly, on top of rspec-rails' own
  # rspec-core/mocks/expectations — without it, `require "pact/rspec"` fails to load.
  gem "rspec", "~> 3.13", require: false
  gem "pact", "~> 2.0", require: false
  gem "pact_broker-client", "~> 1.78", require: false
  # Provider verification hits the app over HTTP, so committed (not transactional) fixtures
  # are required for the request's own connection to see the provider-state setup data.
  gem "database_cleaner-active_record", "~> 2.2", require: false
end

gem "web-push", "~> 3.1"
