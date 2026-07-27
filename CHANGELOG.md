# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multi-signer support for multipart `send_document` (file uploads). Array-valued
  body fields (e.g. `signers: [...]`) now emit one JSON-object part per element,
  all under the same field name (`Signers`, `Signers`, …) via
  `Faraday::Multipart::Middleware`'s `flat_encode: true` — confirmed against
  BoldSign's docs as the correct encoding for a multi-recipient envelope sent
  alongside an uploaded file (as opposed to a template reference). Previously
  this raised `NotImplementedError`. Multi-file uploads are still unsupported
  and still raise.

## [0.5.0] — 2026-06-02

### Added
- OAuth 2.0 authentication via the **client credentials** grant. Configure
  `client_id` / `client_secret` (on `Boldsign.configure` or `Client.new`) and
  the client fetches a bearer token from the region's account host
  (`https://account.boldsign.com/connect/token` for `:us`), caches it until
  shortly before `expires_in` lapses, and sends `Authorization: Bearer …`
  instead of `X-API-KEY`. Token fetches are mutex-guarded for shared clients.
- `scope:` (defaults to `BoldSign.Documents.All`) and `token_url:` options to
  override the requested scope and token endpoint.
- `access_token:` option to supply a pre-obtained bearer token that is used
  as-is (not refreshed).
- `Boldsign::AccessToken` encapsulating the client-credentials token lifecycle.
- `TOKEN_REGIONS` / `DEFAULT_TOKEN_BASE_URL` constants and `Client#auth_mode`.

### Changed
- `Client.new` no longer requires an API key. It accepts any one of
  `client_id`/`client_secret`, `access_token`, or `api_key`, and raises
  `ConfigurationError` only when none is provided. The API-key path is
  unchanged, so existing `api_key:` callers keep working.

## [0.4.0] — 2026-05-22

### Changed
- Request body hash keys are now recursively converted to **camelCase** (not
  PascalCase). This matches the casing used by the BoldSign OpenAPI/Swagger
  schema for all request body DTOs, including nested objects like
  `DocumentSigner` and `FormField`. Callers pass idiomatic snake_case (or
  camelCase / PascalCase) Ruby keys and the gem emits the casing BoldSign
  validates against. **Breaking** for callers that relied on the 0.3.0
  PascalCase output.
- Multipart file uploads are still keyed `Files` (capital F) for the
  document send endpoint; only request body field names are camelCased.
- Multipart `send_document`: single-element arrays for both `signers:` and
  `files:` are now unwrapped before encoding. BoldSign's POST
  `/v1/document/send` rejects `signers=[{...}]` (JSON-array string) and
  `Files[]=…` (Faraday's automatic array-bracket form). The gem now emits
  `signers={...}` (single JSON object) and `Files=<file>` (single FilePart)
  for the one-signer/one-file case. Multi-signer / multi-file uploads are
  not yet supported via this helper and raise `NotImplementedError`.

### Removed
- `Boldsign::CaseConvert.pascalize` / `.pascalize_key`. Replaced by
  `.camelize` / `.camelize_key`.

## [0.3.0] — 2026-05-22

### Changed
- Request bodies (JSON and multipart) now have their Hash keys recursively
  converted to PascalCase before being sent to BoldSign. Callers can pass
  idiomatic snake_case (or camelCase) Ruby symbols/strings and the gem will
  emit the casing the API expects. Already-PascalCase keys pass through
  unchanged. Non-Hash/Array values (including IO objects and
  `Faraday::Multipart::FilePart` instances) are not touched.

### Added
- `Boldsign::CaseConvert` module with `pascalize` / `pascalize_key` helpers
  for callers that need to PascalCase keys outside of the HTTP path.

## [0.2.0] — 2026-05-22

### Added
- `Boldsign::Resources::Document#send_document` now supports multipart file
  uploads via a `files:` keyword. Pass an array of `{io:, filename:,
  content_type:}` hashes (or `Faraday::Multipart::FilePart` instances) to
  send PDFs (or other supported file types) for signature. When `files:` is
  omitted the request is sent as JSON, preserving the prior behavior.

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

[Unreleased]: https://github.com/kleinjm/boldsign-ruby/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/kleinjm/boldsign-ruby/compare/v0.4.0...v0.5.0
[0.1.0]: https://github.com/kleinjm/boldsign-ruby/releases/tag/v0.1.0
