# Security Policy

## Supported Versions

This project does not use versioned releases. Security fixes are applied to
the `main` branch only; deployments should always track the latest commit.

## Reporting a Vulnerability

This application stores personal and health-related data, so we take
security reports seriously.

If you discover a security vulnerability, **please do not open a public
GitHub issue**. Instead, report it privately by emailing:

**leandronunes@gmail.com**

Include as much detail as possible:

- A description of the vulnerability and its potential impact
- Steps to reproduce (proof-of-concept code or requests, if applicable)
- The affected endpoint(s), file(s), or component(s)

### What to expect

- **Acknowledgement**: within 3 business days of your report.
- **Status updates**: as the issue is triaged and fixed.
- **Disclosure**: coordinated with the reporter once a fix is available;
  please allow a reasonable remediation window before any public disclosure.

## Scope

In scope:

- The Rails API in this repository (authentication, authorization,
  endpoints, data handling)
- Infrastructure/configuration defined in this repository (CI, Docker,
  deployment scripts)

Out of scope:

- Third-party services this project depends on (AWS S3, the Pact Broker,
  OAuth providers, etc.) — report those directly to the respective vendor
- Social engineering or physical attacks

## Security Practices in Place

- Authentication via JWT (`has_secure_password` + signed tokens), with
  role-based authorization (`admin` / `personal` / `student`) enforced per
  resource
- Rate limiting via `rack-attack` and restricted cross-origin access via
  `rack-cors`
- Parameterized queries and strong parameters throughout — no raw SQL
  interpolation or mass assignment
- Automated static analysis on every push/PR: `brakeman` (security scanner)
  and `bundler-audit` (dependency CVE scanning)
- Secrets are never committed to source control; configuration is managed
  via Rails credentials and environment variables
