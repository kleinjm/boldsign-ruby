module Boldsign
  # Base class for all errors raised by this gem.
  # HTTP failures raise a typed subclass; carry the status code, parsed body, and Faraday response.
  class Error < StandardError
    # @return [Integer, nil] HTTP status code, when the error originated from a response.
    attr_reader :status
    # @return [Hash, String, nil] parsed response body (JSON Hash) or raw body string.
    attr_reader :body
    # @return [Faraday::Response, nil] underlying Faraday response.
    attr_reader :response

    def initialize(message = nil, status: nil, body: nil, response: nil)
      super(message)
      @status = status
      @body = body
      @response = response
    end
  end

  # Raised when the gem is misconfigured (e.g. missing API key).
  class ConfigurationError < Error; end
  # HTTP 400.
  class BadRequestError < Error; end
  # HTTP 401.
  class AuthenticationError < Error; end
  # HTTP 403.
  class ForbiddenError < Error; end
  # HTTP 404.
  class NotFoundError < Error; end
  # HTTP 422.
  class UnprocessableEntityError < Error; end
  # HTTP 429.
  class RateLimitError < Error; end
  # HTTP 5xx.
  class ServerError < Error; end

  # Maps HTTP status codes to {Error} subclasses.
  ERROR_MAP = {
    400 => BadRequestError,
    401 => AuthenticationError,
    403 => ForbiddenError,
    404 => NotFoundError,
    422 => UnprocessableEntityError,
    429 => RateLimitError
  }.freeze
end
