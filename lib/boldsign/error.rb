module Boldsign
  class Error < StandardError
    attr_reader :status, :body, :response

    def initialize(message = nil, status: nil, body: nil, response: nil)
      super(message)
      @status = status
      @body = body
      @response = response
    end
  end

  class ConfigurationError < Error; end
  class BadRequestError < Error; end       # 400
  class AuthenticationError < Error; end   # 401
  class ForbiddenError < Error; end        # 403
  class NotFoundError < Error; end         # 404
  class UnprocessableEntityError < Error; end # 422
  class RateLimitError < Error; end        # 429
  class ServerError < Error; end           # 5xx

  ERROR_MAP = {
    400 => BadRequestError,
    401 => AuthenticationError,
    403 => ForbiddenError,
    404 => NotFoundError,
    422 => UnprocessableEntityError,
    429 => RateLimitError
  }.freeze
end
