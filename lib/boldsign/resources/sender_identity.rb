module Boldsign
  module Resources
    class SenderIdentity < Resource
      def list(**params);  @client.get("/v1/senderIdentities/list", params); end
      def properties(**params); @client.get("/v1/senderIdentities/properties", params); end
      def create(body);    @client.post("/v1/senderIdentities/create", body: body); end
      def update(body, **params); @client.post("/v1/senderIdentities/update", body: body, params: params); end
      def delete(**params);       @client.delete("/v1/senderIdentities/delete", params); end
      def resend_invitation(**params); @client.post("/v1/senderIdentities/resendInvitation", params: params); end
      def rerequest(body, **params);   @client.post("/v1/senderIdentities/rerequest", body: body, params: params); end
    end
  end
end
