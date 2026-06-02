module Boldsign
  # HTTP client for the BoldSign REST API.
  #
  # Holds API credentials and exposes one accessor per resource group
  # (`documents`, `templates`, `contacts`, …). Each accessor returns a memoized
  # resource object whose methods wrap individual endpoints.
  #
  # Low-level verb methods ({#get}, {#post}, {#put}, {#patch}, {#delete},
  # {#download}) are also available for hitting any endpoint directly.
  #
  # Authenticates with either an API key (`X-API-KEY`) or OAuth 2.0
  # (`Authorization: Bearer`). For OAuth, pass `client_id`/`client_secret` and
  # the client fetches + caches a token via the client credentials grant; or
  # pass a `access_token` you obtained yourself.
  #
  # @example API key
  #   client = Boldsign::Client.new(api_key: ENV["BOLDSIGN_API_KEY"], region: :us)
  #   client.documents.send_document(title: "NDA", signers: [...])
  #
  # @example OAuth client credentials
  #   client = Boldsign::Client.new(
  #     client_id: ENV["BOLDSIGN_CLIENT_ID"],
  #     client_secret: ENV["BOLDSIGN_CLIENT_SECRET"],
  #     region: :us
  #   )
  class Client
    # Default region (US).
    DEFAULT_BASE_URL = "https://api.boldsign.com".freeze

    # User-Agent header value sent on every request.
    USER_AGENT = "boldsign-ruby/#{Boldsign::VERSION}".freeze

    # @return [String, nil] the API key in use, when authenticating via API key.
    attr_reader :api_key

    # @return [Symbol] the resolved auth mode (`:api_key`, `:oauth`, or `:bearer`).
    attr_reader :auth_mode

    # @return [String] the resolved base URL (region or explicit override).
    attr_reader :base_url

    # @param api_key [String, nil] BoldSign API key. Falls back to `ENV["BOLDSIGN_API_KEY"]`.
    # @param client_id [String, nil] OAuth app client ID (enables the client credentials grant).
    # @param client_secret [String, nil] OAuth app client secret (required with `client_id`).
    # @param access_token [String, nil] A pre-obtained OAuth bearer token (used as-is, not refreshed).
    # @param scope [String, nil] OAuth scope to request (defaults to {AccessToken::DEFAULT_SCOPE}).
    # @param token_url [String, nil] Override for the full OAuth token endpoint URL.
    # @param region [Symbol, nil] One of `:us`, `:eu`, `:ca`, `:au`. Ignored if `base_url`/`token_url` is given.
    # @param base_url [String, nil] Explicit API base URL override.
    # @param adapter [Symbol] Faraday adapter (defaults to `Faraday.default_adapter`).
    # @param logger [Logger, nil] Optional logger; when present, Faraday's logger middleware is enabled.
    # @raise [ConfigurationError] when no usable credentials are provided.
    def initialize(api_key: nil, client_id: nil, client_secret: nil, access_token: nil,
                   scope: nil, token_url: nil, region: nil, base_url: nil,
                   adapter: Faraday.default_adapter, logger: nil)
      @api_key = api_key || ENV["BOLDSIGN_API_KEY"]
      @static_access_token = access_token
      @base_url = base_url || Boldsign::REGIONS[region&.to_sym] || DEFAULT_BASE_URL
      @adapter = adapter
      @logger = logger

      if present?(client_id) && present?(client_secret)
        @auth_mode = :oauth
        @access_token = AccessToken.new(
          client_id: client_id, client_secret: client_secret,
          token_url: token_url || default_token_url(region),
          scope: scope || AccessToken::DEFAULT_SCOPE, adapter: adapter
        )
      elsif present?(@static_access_token)
        @auth_mode = :bearer
      elsif present?(@api_key)
        @auth_mode = :api_key
      else
        raise ConfigurationError,
              "Missing BoldSign credentials: provide client_id/client_secret, access_token, or api_key"
      end
    end

    # @return [Resources::Brand]
    def brand;                 @brand ||= Resources::Brand.new(self); end
    # @return [Resources::Contact]
    def contacts;              @contacts ||= Resources::Contact.new(self); end
    # @return [Resources::ContactGroup]
    def contact_groups;        @contact_groups ||= Resources::ContactGroup.new(self); end
    # @return [Resources::CustomField]
    def custom_fields;         @custom_fields ||= Resources::CustomField.new(self); end
    # @return [Resources::Document]
    def documents;             @documents ||= Resources::Document.new(self); end
    # @return [Resources::IdentityVerification]
    def identity_verification; @identity_verification ||= Resources::IdentityVerification.new(self); end
    # @return [Resources::Plan]
    def plan;                  @plan ||= Resources::Plan.new(self); end
    # @return [Resources::SenderIdentity]
    def sender_identities;     @sender_identities ||= Resources::SenderIdentity.new(self); end
    # @return [Resources::Team]
    def teams;                 @teams ||= Resources::Team.new(self); end
    # @return [Resources::Template]
    def templates;             @templates ||= Resources::Template.new(self); end
    # @return [Resources::User]
    def users;                 @users ||= Resources::User.new(self); end

    # Issue a GET request.
    # @param path [String] request path (e.g. `/v1/document/list`).
    # @param params [Hash] query string parameters.
    # @return [Hash, Array, String, nil] parsed JSON body, or raw body for non-JSON responses.
    # @raise [Error] on any non-success HTTP status.
    def get(path, params = {})
      request(:get, path, params: params)
    end

    # Issue a POST request.
    # @param path [String] request path.
    # @param body [Hash, String, nil] request body. Hashes are JSON-encoded;
    #   pre-serialized JSON strings are sent as-is.
    # @param params [Hash] query string parameters.
    # @param multipart [Boolean] when `true`, body is sent as `multipart/form-data`
    #   (include `Faraday::Multipart::FilePart` values to upload files).
    # @return [Hash, Array, String, nil]
    # @raise [Error] on any non-success HTTP status.
    def post(path, body: nil, params: {}, multipart: false)
      request(:post, path, body: body, params: params, multipart: multipart)
    end

    # Issue a PUT request. See {#post} for parameter semantics.
    def put(path, body: nil, params: {})
      request(:put, path, body: body, params: params)
    end

    # Issue a PATCH request. See {#post} for parameter semantics.
    def patch(path, body: nil, params: {})
      request(:patch, path, body: body, params: params)
    end

    # Issue a DELETE request.
    # @param path [String] request path.
    # @param params [Hash] query string parameters.
    def delete(path, params = {})
      request(:delete, path, params: params)
    end

    # Issue a GET request and return the raw response body without JSON parsing.
    # Use for binary endpoints (downloads, audit logs, attachments).
    # @param path [String] request path.
    # @param params [Hash] query string parameters.
    # @return [String] raw response bytes.
    # @raise [Error] on any non-success HTTP status.
    def download(path, params = {})
      response = connection.get(path) do |req|
        req.params.update(params) if params && !params.empty?
      end
      handle_errors(response)
      response.body
    end

    private

    def request(method, path, body: nil, params: {}, multipart: false)
      response = connection(multipart: multipart).public_send(method, path) do |req|
        req.params.update(params) if params && !params.empty?
        if body
          if multipart
            req.body = body
          else
            req.headers["Content-Type"] = "application/json"
            req.body = body.is_a?(String) ? body : JSON.generate(CaseConvert.camelize(body))
          end
        end
      end
      handle_errors(response)
      parse_body(response)
    end

    def connection(multipart: false)
      Faraday.new(url: @base_url) do |f|
        f.request :multipart if multipart
        f.request :url_encoded
        apply_auth(f.headers)
        f.headers["Accept"] = "application/json"
        f.headers["User-Agent"] = USER_AGENT
        f.response :logger, @logger if @logger
        f.adapter @adapter
      end
    end

    def apply_auth(headers)
      if @auth_mode == :api_key
        headers["X-API-KEY"] = @api_key
      else
        headers["Authorization"] = "Bearer #{bearer_token}"
      end
    end

    def bearer_token
      @auth_mode == :oauth ? @access_token.value : @static_access_token
    end

    def present?(value)
      !value.nil? && !value.empty?
    end

    def default_token_url(region)
      base = Boldsign::TOKEN_REGIONS[region&.to_sym] || Boldsign::DEFAULT_TOKEN_BASE_URL
      "#{base}#{AccessToken::TOKEN_PATH}"
    end

    def parse_body(response)
      return nil if response.body.nil? || response.body.empty?
      content_type = response.headers["content-type"].to_s
      return response.body unless content_type.include?("json")
      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end

    def handle_errors(response)
      return if response.success?

      body = begin
        JSON.parse(response.body)
      rescue StandardError
        response.body
      end
      message = body.is_a?(Hash) ? (body["message"] || body["error"] || body.to_s) : body.to_s
      klass = ERROR_MAP[response.status] || (response.status >= 500 ? ServerError : Error)
      raise klass.new("BoldSign API error (#{response.status}): #{message}",
                      status: response.status, body: body, response: response)
    end
  end
end
