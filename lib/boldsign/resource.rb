module Boldsign
  # Base class for all resource wrappers. Holds a reference to the {Client}
  # instance whose HTTP verb methods the resource methods delegate to.
  class Resource
    # @param client [Client]
    def initialize(client)
      @client = client
    end
  end

  # Namespace for endpoint-group resource classes. Each resource is exposed as
  # an accessor on {Client} (e.g. {Client#documents} → {Resources::Document}).
  #
  # @see https://developers.boldsign.com/ BoldSign API reference
  module Resources
  end
end
