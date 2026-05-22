module Boldsign
  module Resources
    # Contact-group endpoints (`/v1/contactGroups/*`).
    class ContactGroup < Resource
      def list(**params); @client.get("/v1/contactGroups/list", params); end
      def get(group_id);  @client.get("/v1/contactGroups/get", groupId: group_id); end
      def create(body);   @client.post("/v1/contactGroups/create", body: body); end
      def update(body, **params); @client.put("/v1/contactGroups/update", body: body, params: params); end
      def delete(group_id);       @client.delete("/v1/contactGroups/delete", groupId: group_id); end
    end
  end
end
