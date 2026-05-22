module Boldsign
  module Resources
    # Identity-verification endpoints (`/v1/identityVerification/*`).
    class IdentityVerification < Resource
      def report(body); @client.post("/v1/identityVerification/report", body: body); end
      def image(body);  @client.post("/v1/identityVerification/image", body: body); end
      def create_embedded_url(body)
        @client.post("/v1/identityVerification/createEmbeddedVerificationUrl", body: body)
      end
    end
  end
end
