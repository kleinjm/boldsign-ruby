module Boldsign
  # Fetches and caches an OAuth 2.0 access token using the client credentials
  # grant (server-to-server; no user interaction).
  #
  # A single instance is shared by a {Client} and may be hit from multiple
  # threads, so token reads/refreshes are guarded by a mutex. The token is
  # cached until shortly before it expires ({EXPIRY_LEEWAY_SECONDS}), then a new
  # one is requested on the next call. The client credentials grant does not
  # issue refresh tokens — expiry is handled by re-requesting.
  #
  # @see https://developers.boldsign.com/authentication/oauth-2-0/
  class AccessToken
    # Token endpoint path, appended to the region's account host.
    TOKEN_PATH = "/connect/token".freeze

    # Default scope requested for the access token. Covers the document /
    # signature endpoints this gem is primarily used for. Pass a different
    # `scope:` to request others (an empty scope grants all the app is allowed).
    DEFAULT_SCOPE = "BoldSign.Documents.All".freeze

    # Refresh this many seconds before the token actually expires, so an
    # in-flight request never carries a token that lapses server-side mid-call.
    EXPIRY_LEEWAY_SECONDS = 60

    # Fallback lifetime (seconds) when the token response omits `expires_in`.
    DEFAULT_EXPIRES_IN = 3600

    # @param client_id [String] OAuth app client ID.
    # @param client_secret [String] OAuth app client secret.
    # @param token_url [String] Full token endpoint URL (host + {TOKEN_PATH}).
    # @param scope [String] OAuth scope to request.
    # @param adapter [Symbol] Faraday adapter.
    def initialize(client_id:, client_secret:, token_url:, scope: DEFAULT_SCOPE,
                   adapter: Faraday.default_adapter)
      @client_id = client_id
      @client_secret = client_secret
      @token_url = token_url
      @scope = scope
      @adapter = adapter
      @mutex = Mutex.new
    end

    # @return [String] a currently-valid bearer token, fetching or refreshing
    #   one if the cached token is missing or near expiry.
    def value
      @mutex.synchronize do
        refresh! if expired?
        @token
      end
    end

    private

    def expired?
      @token.nil? || Time.now >= @expires_at
    end

    def refresh!
      response = connection.post(@token_url) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          grant_type: "client_credentials",
          client_id: @client_id,
          client_secret: @client_secret,
          scope: @scope
        )
      end
      raise_token_error(response) unless response.success?

      body = JSON.parse(response.body)
      @token = body["access_token"]
      expires_in = (body["expires_in"] || DEFAULT_EXPIRES_IN).to_i
      @expires_at = Time.now + expires_in - EXPIRY_LEEWAY_SECONDS
    end

    def connection
      Faraday.new do |f|
        f.adapter @adapter
      end
    end

    def raise_token_error(response)
      body = begin
        JSON.parse(response.body)
      rescue StandardError
        response.body
      end
      message = body.is_a?(Hash) ? (body["error_description"] || body["error"] || body.to_s) : body.to_s
      raise AuthenticationError.new(
        "BoldSign OAuth token request failed (#{response.status}): #{message}",
        status: response.status, body: body, response: response
      )
    end
  end
end
