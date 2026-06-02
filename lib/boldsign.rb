require "faraday"
require "faraday/multipart"
require "json"
require "uri"

require_relative "boldsign/version"
require_relative "boldsign/error"
require_relative "boldsign/case_convert"
require_relative "boldsign/access_token"
require_relative "boldsign/client"
require_relative "boldsign/resource"
require_relative "boldsign/resources/brand"
require_relative "boldsign/resources/contact"
require_relative "boldsign/resources/contact_group"
require_relative "boldsign/resources/custom_field"
require_relative "boldsign/resources/document"
require_relative "boldsign/resources/identity_verification"
require_relative "boldsign/resources/plan"
require_relative "boldsign/resources/sender_identity"
require_relative "boldsign/resources/team"
require_relative "boldsign/resources/template"
require_relative "boldsign/resources/user"

# Top-level namespace for the BoldSign Ruby client.
#
# Configure once at boot and access a shared {Client} via {Boldsign.client}, or
# instantiate {Client} directly when you need multiple credentials/regions.
#
# @example Configure with OAuth and use the shared client
#   Boldsign.configure do |c|
#     c.client_id     = ENV["BOLDSIGN_CLIENT_ID"]
#     c.client_secret = ENV["BOLDSIGN_CLIENT_SECRET"]
#     c.region        = :us
#   end
#   Boldsign.client.documents.list
module Boldsign
  # Region → base URL map for BoldSign's regional API hosts.
  REGIONS = {
    us: "https://api.boldsign.com",
    eu: "https://api-eu.boldsign.com",
    ca: "https://api-ca.boldsign.com",
    au: "https://api-au.boldsign.com"
  }.freeze

  # Region → account host map for the OAuth token endpoint. Non-US hosts follow
  # BoldSign's regional naming; override with `token_url:` if a region differs.
  TOKEN_REGIONS = {
    us: "https://account.boldsign.com",
    eu: "https://account-eu.boldsign.com",
    ca: "https://account-ca.boldsign.com",
    au: "https://account-au.boldsign.com"
  }.freeze

  # Default account host (US) for the OAuth token endpoint.
  DEFAULT_TOKEN_BASE_URL = "https://account.boldsign.com".freeze

  class << self
    # @return [String, nil] API key used by the shared {client}.
    attr_accessor :api_key

    # @return [String, nil] OAuth app client ID used by the shared {client}.
    attr_accessor :client_id

    # @return [String, nil] OAuth app client secret used by the shared {client}.
    attr_accessor :client_secret

    # @return [String, nil] Pre-obtained OAuth bearer token (used as-is, not refreshed).
    attr_accessor :access_token

    # @return [String, nil] OAuth scope to request (defaults to {AccessToken::DEFAULT_SCOPE}).
    attr_accessor :scope

    # @return [String, nil] Override for the full OAuth token endpoint URL.
    attr_accessor :token_url

    # @return [Symbol, nil] Region key (`:us`, `:eu`, `:ca`, `:au`).
    attr_accessor :region

    # @return [String, nil] Optional explicit base URL override (takes precedence over {region}).
    attr_accessor :base_url

    # Yields self for block-style configuration.
    # @yieldparam config [Boldsign] the module itself
    # @return [void]
    def configure
      yield self
    end

    # @return [Client] memoized shared client built from module-level config.
    def client
      @client ||= Client.new(
        api_key: api_key, client_id: client_id, client_secret: client_secret,
        access_token: access_token, scope: scope, token_url: token_url,
        region: region, base_url: base_url
      )
    end

    # Clears the memoized shared client so the next call to {client} rebuilds it.
    # @return [void]
    def reset!
      @client = nil
    end
  end
end
