# boldsign-ruby

A Ruby client for the [BoldSign](https://developers.boldsign.com/) e-signature API.

Wraps every public endpoint of the BoldSign v1 REST API: documents, templates,
contacts, contact groups, custom fields, sender identities, brands, teams,
users, identity verification, and plan info.

## Installation

```ruby
gem "boldsign"
```

## Configuration

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

Region base URLs:

| Region | URL |
| ------ | --- |
| `:us`  | `https://api.boldsign.com` |
| `:eu`  | `https://api-eu.boldsign.com` |
| `:ca`  | `https://api-ca.boldsign.com` |
| `:au`  | `https://api-au.boldsign.com` |

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

## Development

```sh
bundle install
bundle exec rspec
```

## License

MIT
