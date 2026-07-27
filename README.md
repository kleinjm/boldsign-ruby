# boldsign-ruby

[![CI](https://github.com/EscrowSafe/boldsign-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/EscrowSafe/boldsign-ruby/actions/workflows/ci.yml)
[![API docs](https://img.shields.io/badge/docs-rubydoc.info-blue.svg)](https://rubydoc.info/github/EscrowSafe/boldsign-ruby/main)

A Ruby client for the [BoldSign](https://developers.boldsign.com/) e-signature API.

Wraps every public endpoint of the BoldSign v1 REST API: documents, templates,
contacts, contact groups, custom fields, sender identities, brands, teams,
users, identity verification, and plan info.

## Installation

```ruby
gem "boldsign"
```

## Configuration

The client authenticates with either an API key or OAuth 2.0.

### OAuth 2.0 (client credentials)

Register an OAuth app in the BoldSign dashboard (API → OAuth Apps) and configure
its `client_id` / `client_secret`. The client fetches a bearer token from the
region's account host, caches it until shortly before it expires, and refreshes
automatically — no token plumbing on your side.

```ruby
Boldsign.configure do |c|
  c.client_id     = ENV["BOLDSIGN_CLIENT_ID"]
  c.client_secret = ENV["BOLDSIGN_CLIENT_SECRET"]
  c.region        = :us   # :us, :eu, :ca, :au
  # c.scope       = "BoldSign.Documents.All"  # optional; empty grants all the app allows
end
```

You can also pass a token you obtained yourself (used as-is, not refreshed):

```ruby
Boldsign::Client.new(access_token: "…", region: :us)
```

### API key

```ruby
Boldsign.configure do |c|
  c.api_key = ENV["BOLDSIGN_API_KEY"]
  c.region  = :us   # :us, :eu, :ca, :au  (or set c.base_url directly)
end
```

Or instantiate a client directly:

```ruby
client = Boldsign::Client.new(api_key: "…", region: :us)
```

Region hosts:

| Region | API base URL | OAuth account host |
| ------ | ------------ | ------------------ |
| `:us`  | `https://api.boldsign.com` | `https://account.boldsign.com` |
| `:eu`  | `https://api-eu.boldsign.com` | `https://account-eu.boldsign.com` |
| `:ca`  | `https://api-ca.boldsign.com` | `https://account-ca.boldsign.com` |
| `:au`  | `https://api-au.boldsign.com` | `https://account-au.boldsign.com` |

The token endpoint is the account host + `/connect/token`; override the full URL
with `token_url:` if a region differs.

## Usage

```ruby
client = Boldsign.client

# Send a document
client.documents.send_document(
  title: "NDA",
  signers: [{ name: "Jane Doe", emailAddress: "jane@example.com", signerOrder: 1 }],
  files: [...] # see BoldSign docs for the full schema
)

# List documents
client.documents.list(page: 1, pageSize: 50)

# Properties / download
client.documents.properties("DOCUMENT_ID")
File.binwrite("signed.pdf", client.documents.download("DOCUMENT_ID"))

# Templates
client.templates.list
client.templates.send_template("TEMPLATE_ID", roles: [...])

# Contacts / contact groups
client.contacts.create(contacts: [{ name: "Jane", emailAddress: "jane@example.com" }])
client.contact_groups.list

# Users & teams
client.users.list
client.teams.create(teamName: "Sales")

# Brands
client.brand.list

# Plan
client.plan.api_credits_count
```

## Resources & methods

Each resource on `Boldsign::Client` maps to a group of BoldSign endpoints:

| Accessor | Methods |
| -------- | ------- |
| `client.documents` | `list`, `team_list`, `behalf_list`, `properties`, `send_document`, `draft_send`, `edit`, `cancel_editing`, `create_embedded_request_url`, `create_embedded_edit_url`, `get_embedded_sign_link`, `download`, `download_attachment`, `download_audit_log`, `revoke`, `remind`, `delete`, `extend_expiry`, `change_access_code`, `change_recipient`, `add_tags`, `delete_tags`, `add_authentication`, `remove_authentication`, `prefill_fields` |
| `client.templates` | `list`, `properties`, `download`, `create`, `edit`, `delete`, `send_template`, `merge_and_send`, `create_embedded_template_url`, `get_embedded_template_edit_url`, `create_embedded_request_url`, `merge_create_embedded_request_url`, `create_embedded_preview_url`, `add_tags`, `delete_tags` |
| `client.contacts` | `list`, `get`, `create`, `update`, `delete` |
| `client.contact_groups` | `list`, `get`, `create`, `update`, `delete` |
| `client.custom_fields` | `list`, `create`, `edit`, `delete`, `create_embedded_url` |
| `client.sender_identities` | `list`, `properties`, `create`, `update`, `delete`, `resend_invitation`, `rerequest` |
| `client.brand` | `list`, `get`, `create`, `edit`, `delete`, `reset_default` |
| `client.teams` | `list`, `get`, `create`, `update` |
| `client.users` | `list`, `get`, `create`, `update`, `update_metadata`, `change_team`, `resend_invitation`, `cancel_invitation` |
| `client.identity_verification` | `report`, `image`, `create_embedded_url` |
| `client.plan` | `api_credits_count` |

All methods accept Ruby hashes (with camelCase keys matching the BoldSign API)
and return parsed JSON. Binary endpoints (`download*`) return raw bytes.

## Errors

HTTP errors raise a typed subclass of `Boldsign::Error`:

`BadRequestError` (400), `AuthenticationError` (401), `ForbiddenError` (403),
`NotFoundError` (404), `UnprocessableEntityError` (422), `RateLimitError` (429),
`ServerError` (5xx). Each carries `#status`, `#body`, and `#response`.

## Documentation

Full YARD API documentation is auto-built and hosted at
[rubydoc.info/github/EscrowSafe/boldsign-ruby/main](https://rubydoc.info/github/EscrowSafe/boldsign-ruby/main).

To generate locally:

```sh
bundle exec yard doc
open doc/index.html
```

## Development

```sh
bundle install
bundle exec rspec        # run tests (enforces 100% line + branch coverage)
bundle exec yard doc     # build local API docs to ./doc
```

## License

MIT
