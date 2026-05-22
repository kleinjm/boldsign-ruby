module Boldsign
  module Resources
    # Document endpoints (`/v1/document/*`) — the bulk of the BoldSign API:
    # sending, listing, downloading, editing, reminding, authenticating, tagging,
    # and embedded signing flows.
    #
    # @example Send a document
    #   client.documents.send_document(
    #     title: "NDA",
    #     signers: [{ name: "Jane", emailAddress: "jane@example.com", signerOrder: 1 }],
    #     files: [...]
    #   )
    #
    # @see https://developers.boldsign.com/documents
    class Document < Resource
      def list(**params);       @client.get("/v1/document/list", params); end
      def team_list(**params);  @client.get("/v1/document/teamlist", params); end
      def behalf_list(**params); @client.get("/v1/document/behalfList", params); end
      def properties(document_id); @client.get("/v1/document/properties", documentId: document_id); end

      def send_document(body);  @client.post("/v1/document/send", body: body); end
      def draft_send(body);     @client.post("/v1/document/draftSend", body: body); end
      def edit(document_id, body); @client.put("/v1/document/edit", body: body, params: { documentId: document_id }); end
      def cancel_editing(document_id); @client.post("/v1/document/cancelEditing", params: { documentId: document_id }); end

      def create_embedded_request_url(body); @client.post("/v1/document/createEmbeddedRequestUrl", body: body); end
      def create_embedded_edit_url(body);    @client.post("/v1/document/createEmbeddedEditUrl", body: body); end
      def get_embedded_sign_link(**params);  @client.get("/v1/document/getEmbeddedSignLink", params); end

      def download(document_id);   @client.download("/v1/document/download", documentId: document_id); end
      def download_attachment(**params); @client.download("/v1/document/downloadAttachment", params); end
      def download_audit_log(document_id); @client.download("/v1/document/downloadAuditLog", documentId: document_id); end

      def revoke(document_id, body = {}); @client.post("/v1/document/revoke", body: body, params: { documentId: document_id }); end
      def remind(document_id, body = {}); @client.post("/v1/document/remind", body: body, params: { documentId: document_id }); end
      def delete(document_id);            @client.delete("/v1/document/delete", documentId: document_id); end
      def extend_expiry(document_id, body); @client.patch("/v1/document/extendExpiry", body: body, params: { documentId: document_id }); end

      def change_access_code(document_id, body); @client.patch("/v1/document/changeAccessCode", body: body, params: { documentId: document_id }); end
      def change_recipient(document_id, body);   @client.patch("/v1/document/changeRecipient", body: body, params: { documentId: document_id }); end

      def add_tags(body);    @client.patch("/v1/document/addTags", body: body); end
      def delete_tags(body); @client.delete("/v1/document/deleteTags", body: body); end

      def remove_authentication(document_id, body); @client.patch("/v1/document/RemoveAuthentication", body: body, params: { documentId: document_id }); end
      def add_authentication(document_id, body);    @client.patch("/v1/document/addAuthentication", body: body, params: { documentId: document_id }); end

      def prefill_fields(document_id, body); @client.patch("/v1/document/prefillFields", body: body, params: { documentId: document_id }); end
    end
  end
end
