module Boldsign
  module Resources
    # Template endpoints (`/v1/template/*`) — create, send, edit, and embed
    # reusable signing templates.
    #
    # @see https://developers.boldsign.com/templates
    class Template < Resource
      def list(**params);          @client.get("/v1/template/list", params); end
      def properties(template_id); @client.get("/v1/template/properties", templateId: template_id); end
      def download(template_id);   @client.download("/v1/template/download", templateId: template_id); end

      def create(body);            @client.post("/v1/template/create", body: body); end
      def edit(template_id, body); @client.put("/v1/template/edit", body: body, params: { templateId: template_id }); end
      def delete(template_id);     @client.delete("/v1/template/delete", templateId: template_id); end

      def send_template(template_id, body)
        @client.post("/v1/template/send", body: body, params: { templateId: template_id })
      end
      def merge_and_send(body); @client.post("/v1/template/mergeAndSend", body: body); end

      def create_embedded_template_url(body); @client.post("/v1/template/createEmbeddedTemplateUrl", body: body); end
      def get_embedded_template_edit_url(body); @client.post("/v1/template/getEmbeddedTemplateEditUrl", body: body); end
      def create_embedded_request_url(template_id, body)
        @client.post("/v1/template/createEmbeddedRequestUrl", body: body, params: { templateId: template_id })
      end
      def merge_create_embedded_request_url(body)
        @client.post("/v1/template/mergeCreateEmbeddedRequestUrl", body: body)
      end
      def create_embedded_preview_url(body)
        @client.post("/v1/template/createEmbeddedPreviewUrl", body: body)
      end

      def add_tags(body);    @client.patch("/v1/template/addTags", body: body); end
      def delete_tags(body); @client.delete("/v1/template/deleteTags", body: body); end
    end
  end
end
