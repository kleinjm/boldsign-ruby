module Boldsign
  class Client
    DEFAULT_BASE_URL = "https://api.boldsign.com".freeze
    USER_AGENT = "boldsign-ruby/#{Boldsign::VERSION}".freeze

    attr_reader :api_key, :base_url

    def initialize(api_key: nil, region: nil, base_url: nil, adapter: Faraday.default_adapter, logger: nil)
      @api_key = api_key || ENV["BOLDSIGN_API_KEY"]
      raise ConfigurationError, "Missing BoldSign API key" if @api_key.nil? || @api_key.empty?

      @base_url = base_url || Boldsign::REGIONS[region&.to_sym] || DEFAULT_BASE_URL
      @adapter = adapter
      @logger = logger
    end

    def brand;                 @brand ||= Resources::Brand.new(self); end
    def contacts;              @contacts ||= Resources::Contact.new(self); end
    def contact_groups;        @contact_groups ||= Resources::ContactGroup.new(self); end
    def custom_fields;         @custom_fields ||= Resources::CustomField.new(self); end
    def documents;             @documents ||= Resources::Document.new(self); end
    def identity_verification; @identity_verification ||= Resources::IdentityVerification.new(self); end
    def plan;                  @plan ||= Resources::Plan.new(self); end
    def sender_identities;     @sender_identities ||= Resources::SenderIdentity.new(self); end
    def teams;                 @teams ||= Resources::Team.new(self); end
    def templates;             @templates ||= Resources::Template.new(self); end
    def users;                 @users ||= Resources::User.new(self); end

    def get(path, params = {})
      request(:get, path, params: params)
    end

    def post(path, body: nil, params: {}, multipart: false)
      request(:post, path, body: body, params: params, multipart: multipart)
    end

    def put(path, body: nil, params: {})
      request(:put, path, body: body, params: params)
    end

    def patch(path, body: nil, params: {})
      request(:patch, path, body: body, params: params)
    end

    def delete(path, params = {})
      request(:delete, path, params: params)
    end

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
            req.body = body.is_a?(String) ? body : JSON.generate(body)
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
        f.headers["X-API-KEY"] = @api_key
        f.headers["Accept"] = "application/json"
        f.headers["User-Agent"] = USER_AGENT
        f.response :logger, @logger if @logger
        f.adapter @adapter
      end
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
