module Boldsign
  module Resources
    # Reusable custom-field endpoints (`/v1/customField/*`).
    class CustomField < Resource
      def list(**params); @client.get("/v1/customField/list", params); end
      def create(body);   @client.post("/v1/customField/create", body: body); end
      def edit(body, **params); @client.post("/v1/customField/edit", body: body, params: params); end
      def delete(**params);     @client.delete("/v1/customField/delete", params); end
      def create_embedded_url(body); @client.post("/v1/customField/createEmbeddedCustomFieldUrl", body: body); end
    end
  end
end
