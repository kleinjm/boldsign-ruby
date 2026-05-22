module Boldsign
  module Resources
    class User < Resource
      def list(**params);   @client.get("/v1/users/list", params); end
      def get(user_id);     @client.get("/v1/users/get", userId: user_id); end
      def create(body);     @client.post("/v1/users/create", body: body); end
      def update(body, **params); @client.put("/v1/users/update", body: body, params: params); end
      def update_metadata(body, **params); @client.put("/v1/users/updateMetaData", body: body, params: params); end
      def change_team(body, **params);     @client.put("/v1/users/changeTeam", body: body, params: params); end
      def resend_invitation(**params); @client.post("/v1/users/resendInvitation", params: params); end
      def cancel_invitation(**params); @client.post("/v1/users/cancelInvitation", params: params); end
    end
  end
end
