# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-05-22

### Added
- Initial release.
- `Boldsign::Client` covering all 84 endpoints of the BoldSign v1 REST API
  across 11 resource groups: documents, templates, contacts, contact groups,
  custom fields, sender identities, brands, teams, users, identity
  verification, and plan info.
- Region support (`:us`, `:eu`, `:ca`, `:au`) plus explicit base-URL override.
- Typed error hierarchy mapped from HTTP status codes.
- YARD documentation for the public API.
- 100% line and branch test coverage enforced via SimpleCov.
- GitHub Actions CI on Ruby 3.4 and 4.0.

[Unreleased]: https://github.com/kleinjm/boldsign-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/kleinjm/boldsign-ruby/releases/tag/v0.1.0
