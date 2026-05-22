require "faraday"
require "faraday/multipart"
require "json"

require_relative "boldsign/version"
require_relative "boldsign/error"
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

module Boldsign
  REGIONS = {
    us: "https://api.boldsign.com",
    eu: "https://api-eu.boldsign.com",
    ca: "https://api-ca.boldsign.com",
    au: "https://api-au.boldsign.com"
  }.freeze

  class << self
    attr_accessor :api_key, :region, :base_url

    def configure
      yield self
    end

    def client
      @client ||= Client.new(api_key: api_key, region: region, base_url: base_url)
    end

    def reset!
      @client = nil
    end
  end
end
