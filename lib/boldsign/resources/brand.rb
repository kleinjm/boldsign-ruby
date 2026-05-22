module Boldsign
  module Resources
    class Brand < Resource
      def list(**params);  @client.get("/v1/brand/list", params); end
      def get(brand_id);   @client.get("/v1/brand/get", brandId: brand_id); end
      def create(body, **params);  @client.post("/v1/brand/create", body: body, params: params); end
      def edit(brand_id, body);    @client.post("/v1/brand/edit", body: body, params: { brandId: brand_id }); end
      def delete(brand_id);        @client.delete("/v1/brand/delete", brandId: brand_id); end
      def reset_default(brand_id); @client.post("/v1/brand/resetdefault", params: { brandId: brand_id }); end
    end
  end
end
