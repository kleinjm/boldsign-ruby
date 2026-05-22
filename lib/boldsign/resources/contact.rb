module Boldsign
  module Resources
    class Contact < Resource
      def list(**params);    @client.get("/v1/contacts/list", params); end
      def get(contact_id);   @client.get("/v1/contacts/get", contactId: contact_id); end
      def create(body);      @client.post("/v1/contacts/create", body: body); end
      def update(body, **params); @client.put("/v1/contacts/update", body: body, params: params); end
      def delete(contact_id);     @client.delete("/v1/contacts/delete", contactId: contact_id); end
    end
  end
end
