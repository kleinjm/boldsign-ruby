require "spec_helper"

RSpec.describe "full coverage" do
  describe "Boldsign module" do
    it "configures, returns a memoized client, and resets" do
      Boldsign.configure do |c|
        c.api_key = "key"
        c.region  = :us
      end

      first  = Boldsign.client
      second = Boldsign.client
      expect(first).to be_a(Boldsign::Client)
      expect(first).to equal(second)

      Boldsign.reset!
      expect(Boldsign.client).not_to equal(first)
    end
  end

  describe "Boldsign::Client HTTP verbs" do
    it "issues put, patch, delete with bodies and params" do
      put_stub = stub_request(:put, "https://api.boldsign.com/v1/template/edit")
                 .with(query: { templateId: "t1" }, body: { "Title" => "x" }.to_json)
                 .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
      patch_stub = stub_request(:patch, "https://api.boldsign.com/v1/document/extendExpiry")
                   .with(query: { documentId: "d1" }, body: { "NewExpiryValue" => 5 }.to_json)
                   .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
      delete_stub = stub_request(:delete, "https://api.boldsign.com/v1/document/delete")
                    .with(query: { documentId: "d1" })
                    .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      client = Boldsign::Client.new(api_key: "k")
      client.templates.edit("t1", title: "x")
      client.documents.extend_expiry("d1", newExpiryValue: 5)
      client.documents.delete("d1")

      expect(put_stub).to have_been_requested
      expect(patch_stub).to have_been_requested
      expect(delete_stub).to have_been_requested
    end

    it "downloads raw bytes and skips JSON parsing" do
      stub_request(:get, "https://api.boldsign.com/v1/document/download")
        .with(query: { documentId: "d1" })
        .to_return(status: 200, body: "PDFBYTES",
                   headers: { "Content-Type" => "application/pdf" })

      result = Boldsign::Client.new(api_key: "k").documents.download("d1")

      expect(result).to eq("PDFBYTES")
    end

    it "accepts a pre-serialized String JSON body" do
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .with(body: '{"title":"raw"}',
                   headers: { "Content-Type" => "application/json" })
             .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      Boldsign::Client.new(api_key: "k").post("/v1/document/send", body: '{"title":"raw"}')

      expect(stub).to have_been_requested
    end

    it "supports multipart bodies" do
      stub = stub_request(:post, "https://api.boldsign.com/v1/upload")
             .with { |req| req.headers["Content-Type"].to_s.include?("multipart/form-data") }
             .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      file = Faraday::Multipart::FilePart.new(StringIO.new("hello"), "text/plain", "hi.txt")
      Boldsign::Client.new(api_key: "k").post(
        "/v1/upload",
        body: { field: "value", file: file },
        multipart: true
      )

      expect(stub).to have_been_requested
    end

    it "attaches a Faraday logger when one is supplied" do
      io = StringIO.new
      stub_request(:get, "https://api.boldsign.com/v1/plan/apiCreditsCount")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      Boldsign::Client.new(api_key: "k", logger: Logger.new(io)).plan.api_credits_count

      expect(io.string).to include("GET")
    end

    it "calls endpoints with no query params" do
      stub = stub_request(:get, "https://api.boldsign.com/v1/plan/apiCreditsCount")
             .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
      download_stub = stub_request(:get, "https://example.test/raw")
                      .to_return(status: 200, body: "bytes")

      client = Boldsign::Client.new(api_key: "k")
      client.plan.api_credits_count
      Boldsign::Client.new(api_key: "k", base_url: "https://example.test").download("/raw")

      expect(stub).to have_been_requested
      expect(download_stub).to have_been_requested
    end
  end

  describe "response parsing" do
    it "returns nil for empty body responses" do
      stub_request(:delete, "https://api.boldsign.com/v1/document/delete")
        .with(query: { documentId: "d1" })
        .to_return(status: 200, body: "")

      expect(Boldsign::Client.new(api_key: "k").documents.delete("d1")).to be_nil
    end

    it "returns raw body for non-JSON content types" do
      stub_request(:get, "https://api.boldsign.com/v1/plan/apiCreditsCount")
        .to_return(status: 200, body: "plain text",
                   headers: { "Content-Type" => "text/plain" })

      expect(Boldsign::Client.new(api_key: "k").plan.api_credits_count).to eq("plain text")
    end

    it "returns raw body when JSON content type contains invalid JSON" do
      stub_request(:get, "https://api.boldsign.com/v1/plan/apiCreditsCount")
        .to_return(status: 200, body: "not-json",
                   headers: { "Content-Type" => "application/json" })

      expect(Boldsign::Client.new(api_key: "k").plan.api_credits_count).to eq("not-json")
    end
  end

  describe "error body handling" do
    it "falls back to raw body and generic Error for unmapped non-JSON failures" do
      stub_request(:get, "https://api.boldsign.com/v1/document/list")
        .to_return(status: 418, body: "teapot")

      expect { Boldsign::Client.new(api_key: "k").documents.list }
        .to raise_error(Boldsign::Error, /teapot/) { |e|
          expect(e.status).to eq(418)
          expect(e.body).to eq("teapot")
        }
    end

    it "extracts 'error' key when 'message' is absent" do
      stub_request(:get, "https://api.boldsign.com/v1/document/list")
        .to_return(status: 400, body: '{"error":"bad input"}',
                   headers: { "Content-Type" => "application/json" })

      expect { Boldsign::Client.new(api_key: "k").documents.list }
        .to raise_error(Boldsign::BadRequestError, /bad input/)
    end

    it "stringifies hash without message/error keys" do
      stub_request(:get, "https://api.boldsign.com/v1/document/list")
        .to_return(status: 403, body: '{"foo":"bar"}',
                   headers: { "Content-Type" => "application/json" })

      expect { Boldsign::Client.new(api_key: "k").documents.list }
        .to raise_error(Boldsign::ForbiddenError, /foo/)
    end
  end

  describe "remaining resource methods" do
    it "exercises every resource accessor and untouched method" do
      client = Boldsign::Client.new(api_key: "k")

      paths = {
        # Brand
        [:get,    "/v1/brand/list"]     => -> { client.brand.list },
        [:get,    "/v1/brand/get"]      => -> { client.brand.get("b") },
        [:post,   "/v1/brand/create"]   => -> { client.brand.create({}) },
        [:post,   "/v1/brand/edit"]     => -> { client.brand.edit("b", {}) },
        [:delete, "/v1/brand/delete"]   => -> { client.brand.delete("b") },
        [:post,   "/v1/brand/resetdefault"] => -> { client.brand.reset_default("b") },

        # Contacts
        [:get,    "/v1/contacts/list"]   => -> { client.contacts.list },
        [:get,    "/v1/contacts/get"]    => -> { client.contacts.get("c") },
        [:post,   "/v1/contacts/create"] => -> { client.contacts.create({}) },
        [:put,    "/v1/contacts/update"] => -> { client.contacts.update({}) },
        [:delete, "/v1/contacts/delete"] => -> { client.contacts.delete("c") },

        # Contact groups
        [:get,    "/v1/contactGroups/list"]   => -> { client.contact_groups.list },
        [:get,    "/v1/contactGroups/get"]    => -> { client.contact_groups.get("g") },
        [:post,   "/v1/contactGroups/create"] => -> { client.contact_groups.create({}) },
        [:put,    "/v1/contactGroups/update"] => -> { client.contact_groups.update({}) },
        [:delete, "/v1/contactGroups/delete"] => -> { client.contact_groups.delete("g") },

        # Custom fields
        [:get,    "/v1/customField/list"]   => -> { client.custom_fields.list },
        [:post,   "/v1/customField/create"] => -> { client.custom_fields.create({}) },
        [:post,   "/v1/customField/edit"]   => -> { client.custom_fields.edit({}) },
        [:delete, "/v1/customField/delete"] => -> { client.custom_fields.delete },
        [:post,   "/v1/customField/createEmbeddedCustomFieldUrl"] =>
          -> { client.custom_fields.create_embedded_url({}) },

        # Document (extras not in client_spec)
        [:get,    "/v1/document/teamlist"]   => -> { client.documents.team_list },
        [:get,    "/v1/document/behalfList"] => -> { client.documents.behalf_list },
        [:post,   "/v1/document/draftSend"]  => -> { client.documents.draft_send({}) },
        [:put,    "/v1/document/edit"]       => -> { client.documents.edit("d", {}) },
        [:post,   "/v1/document/cancelEditing"] => -> { client.documents.cancel_editing("d") },
        [:post,   "/v1/document/createEmbeddedRequestUrl"] =>
          -> { client.documents.create_embedded_request_url({}) },
        [:post,   "/v1/document/createEmbeddedEditUrl"] =>
          -> { client.documents.create_embedded_edit_url({}) },
        [:get,    "/v1/document/getEmbeddedSignLink"] =>
          -> { client.documents.get_embedded_sign_link(documentId: "d") },
        [:get,    "/v1/document/downloadAttachment"] =>
          -> { client.documents.download_attachment(documentId: "d") },
        [:get,    "/v1/document/downloadAuditLog"] => -> { client.documents.download_audit_log("d") },
        [:post,   "/v1/document/revoke"] => -> { client.documents.revoke("d") },
        [:post,   "/v1/document/remind"] => -> { client.documents.remind("d") },
        [:patch,  "/v1/document/changeAccessCode"] =>
          -> { client.documents.change_access_code("d", {}) },
        [:patch,  "/v1/document/changeRecipient"] =>
          -> { client.documents.change_recipient("d", {}) },
        [:patch,  "/v1/document/addTags"]    => -> { client.documents.add_tags({}) },
        [:delete, "/v1/document/deleteTags"] => -> { client.documents.delete_tags({}) },
        [:patch,  "/v1/document/RemoveAuthentication"] =>
          -> { client.documents.remove_authentication("d", {}) },
        [:patch,  "/v1/document/addAuthentication"] =>
          -> { client.documents.add_authentication("d", {}) },
        [:patch,  "/v1/document/prefillFields"] => -> { client.documents.prefill_fields("d", {}) },

        # Identity verification
        [:post, "/v1/identityVerification/report"] => -> { client.identity_verification.report({}) },
        [:post, "/v1/identityVerification/image"]  => -> { client.identity_verification.image({}) },
        [:post, "/v1/identityVerification/createEmbeddedVerificationUrl"] =>
          -> { client.identity_verification.create_embedded_url({}) },

        # Sender identities
        [:get,    "/v1/senderIdentities/list"]       => -> { client.sender_identities.list },
        [:get,    "/v1/senderIdentities/properties"] => -> { client.sender_identities.properties },
        [:post,   "/v1/senderIdentities/create"]     => -> { client.sender_identities.create({}) },
        [:post,   "/v1/senderIdentities/update"]     => -> { client.sender_identities.update({}) },
        [:delete, "/v1/senderIdentities/delete"]     => -> { client.sender_identities.delete },
        [:post,   "/v1/senderIdentities/resendInvitation"] =>
          -> { client.sender_identities.resend_invitation },
        [:post,   "/v1/senderIdentities/rerequest"] => -> { client.sender_identities.rerequest({}) },

        # Teams
        [:get,    "/v1/teams/list"]   => -> { client.teams.list },
        [:get,    "/v1/teams/get"]    => -> { client.teams.get("t") },
        [:post,   "/v1/teams/create"] => -> { client.teams.create({}) },
        [:put,    "/v1/teams/update"] => -> { client.teams.update({}) },

        # Templates (untouched in other specs)
        [:get,    "/v1/template/list"]       => -> { client.templates.list },
        [:get,    "/v1/template/properties"] => -> { client.templates.properties("t") },
        [:get,    "/v1/template/download"]   => -> { client.templates.download("t") },
        [:post,   "/v1/template/create"]     => -> { client.templates.create({}) },
        [:delete, "/v1/template/delete"]     => -> { client.templates.delete("t") },
        [:post,   "/v1/template/send"]       => -> { client.templates.send_template("t", {}) },
        [:post,   "/v1/template/mergeAndSend"] => -> { client.templates.merge_and_send({}) },
        [:post,   "/v1/template/createEmbeddedTemplateUrl"] =>
          -> { client.templates.create_embedded_template_url({}) },
        [:post,   "/v1/template/getEmbeddedTemplateEditUrl"] =>
          -> { client.templates.get_embedded_template_edit_url({}) },
        [:post,   "/v1/template/createEmbeddedRequestUrl"] =>
          -> { client.templates.create_embedded_request_url("t", {}) },
        [:post,   "/v1/template/mergeCreateEmbeddedRequestUrl"] =>
          -> { client.templates.merge_create_embedded_request_url({}) },
        [:post,   "/v1/template/createEmbeddedPreviewUrl"] =>
          -> { client.templates.create_embedded_preview_url({}) },
        [:patch,  "/v1/template/addTags"]    => -> { client.templates.add_tags({}) },
        [:delete, "/v1/template/deleteTags"] => -> { client.templates.delete_tags({}) },

        # Users
        [:get,    "/v1/users/list"]   => -> { client.users.list },
        [:get,    "/v1/users/get"]    => -> { client.users.get("u") },
        [:post,   "/v1/users/create"] => -> { client.users.create({}) },
        [:put,    "/v1/users/update"] => -> { client.users.update({}) },
        [:put,    "/v1/users/updateMetaData"] => -> { client.users.update_metadata({}) },
        [:put,    "/v1/users/changeTeam"]     => -> { client.users.change_team({}) },
        [:post,   "/v1/users/resendInvitation"] => -> { client.users.resend_invitation },
        [:post,   "/v1/users/cancelInvitation"] => -> { client.users.cancel_invitation }
      }

      paths.each_key do |(method, path)|
        stub_request(method, %r{\Ahttps://api\.boldsign\.com#{Regexp.escape(path)}(\?|\z)})
          .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
      end

      paths.each_value { |call| call.call }
    end
  end
end
