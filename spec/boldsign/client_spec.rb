require "spec_helper"

RSpec.describe Boldsign::Client do
  describe "#initialize" do
    it "raises ConfigurationError when no usable credentials are provided" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(Boldsign::ConfigurationError)
      expect { described_class.new(api_key: "") }
        .to raise_error(Boldsign::ConfigurationError)
      expect { described_class.new }
        .to raise_error(Boldsign::ConfigurationError, /client_id/)
    end

    it "resolves base_url from region and allows override" do
      us_client     = described_class.new(api_key: "k", region: :us)
      eu_client     = described_class.new(api_key: "k", region: :eu)
      custom_client = described_class.new(api_key: "k", base_url: "https://example.test")

      expect(us_client.base_url).to eq("https://api.boldsign.com")
      expect(eu_client.base_url).to eq("https://api-eu.boldsign.com")
      expect(custom_client.base_url).to eq("https://example.test")
    end

    it "reports the api_key auth mode" do
      expect(described_class.new(api_key: "k").auth_mode).to eq(:api_key)
    end
  end

  describe "OAuth authentication" do
    def stub_token(host: "https://account.boldsign.com")
      stub_request(:post, "#{host}/connect/token")
        .to_return(status: 200,
                   body: { access_token: "oauth-tok", expires_in: 3600 }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    def stub_list(token: "oauth-tok")
      stub_request(:get, "https://api.boldsign.com/v1/document/list")
        .with(headers: { "Authorization" => "Bearer #{token}" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
    end

    it "fetches a token and sends Authorization: Bearer" do
      token_stub = stub_token
      api_stub = stub_list

      client = described_class.new(client_id: "cid", client_secret: "secret", region: :us)
      expect(client.auth_mode).to eq(:oauth)
      client.documents.list

      expect(token_stub).to have_been_requested
      expect(api_stub).to have_been_requested
    end

    it "resolves the token host from the region, defaulting to US when region is absent" do
      default_stub = stub_token
      eu_stub = stub_token(host: "https://account-eu.boldsign.com")
      stub_request(:get, %r{boldsign\.com/v1/document/list})
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      described_class.new(client_id: "c", client_secret: "s").documents.list
      described_class.new(client_id: "c", client_secret: "s", region: :eu).documents.list

      expect(default_stub).to have_been_requested
      expect(eu_stub).to have_been_requested
    end

    it "honors a token_url override" do
      token_stub = stub_request(:post, "https://custom.test/token")
                   .to_return(status: 200,
                              body: { access_token: "oauth-tok", expires_in: 3600 }.to_json,
                              headers: { "Content-Type" => "application/json" })
      api_stub = stub_list

      described_class.new(
        client_id: "c", client_secret: "s", token_url: "https://custom.test/token"
      ).documents.list

      expect(token_stub).to have_been_requested
      expect(api_stub).to have_been_requested
    end

    it "uses a static access_token without fetching one" do
      api_stub = stub_list(token: "static-tok")

      client = described_class.new(access_token: "static-tok")
      expect(client.auth_mode).to eq(:bearer)
      client.documents.list

      expect(api_stub).to have_been_requested
    end
  end

  describe "#get" do
    it "sends X-API-KEY header and parses JSON response" do
      stub = stub_request(:get, "https://api.boldsign.com/v1/plan/apiCreditsCount")
             .with(headers: { "X-API-KEY" => "test-key" })
             .to_return(status: 200, body: '{"apiCount":42}',
                        headers: { "Content-Type" => "application/json" })

      result = described_class.new(api_key: "test-key").plan.api_credits_count

      expect(result).to eq({ "apiCount" => 42 })
      expect(stub).to have_been_requested
    end

    it "forwards id arguments as query params" do
      stub = stub_request(:get, "https://api.boldsign.com/v1/document/properties")
             .with(query: { documentId: "abc" })
             .to_return(status: 200, body: '{"id":"abc"}',
                        headers: { "Content-Type" => "application/json" })

      described_class.new(api_key: "k").documents.properties("abc")

      expect(stub).to have_been_requested
    end
  end

  describe "#post" do
    it "encodes body as JSON with the correct Content-Type" do
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .with(body: { "title" => "Hi" }.to_json,
                   headers: { "X-API-KEY" => "k", "Content-Type" => "application/json" })
             .to_return(status: 200, body: '{"documentId":"abc"}',
                        headers: { "Content-Type" => "application/json" })

      result = described_class.new(api_key: "k").documents.send_document(title: "Hi")

      expect(result).to eq({ "documentId" => "abc" })
      expect(stub).to have_been_requested
    end

    it "sends a multipart request when files: is provided" do
      captured_body = nil
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .with { |req|
               captured_body = req.body.dup
               req.headers["Content-Type"].to_s.include?("multipart/form-data")
             }
             .to_return(status: 200, body: '{"documentId":"abc"}',
                        headers: { "Content-Type" => "application/json" })

      described_class.new(api_key: "k").documents.send_document(
        title: "NDA",
        signers: [{ name: "Jane", emailAddress: "jane@example.com" }],
        disableEmails: true,
        files: [{ io: StringIO.new("PDF"), filename: "nda.pdf", content_type: "application/pdf" }]
      )

      expect(stub).to have_been_requested
      expect(captured_body).to include('name="title"')
      expect(captured_body).to include("NDA")
      # Single-element signer array is unwrapped to a JSON object (NOT a JSON
      # array string) — BoldSign rejects `[{...}]` for multipart signers.
      expect(captured_body).to include('name="signers"')
      expect(captured_body).not_to include('name="signers[]"')
      expect(captured_body).to match(/name="signers"\r\n\r\n\{/)
      expect(captured_body).to include('"emailAddress":"jane@example.com"')
      expect(captured_body).to include('name="disableEmails"')
      # `Files` is keyed verbatim (capital F, no `[]` brackets) and carries a
      # single file part — Faraday's automatic `Files[]` bracketing trips
      # BoldSign so the gem sends one FilePart value, not an array.
      expect(captured_body).to include('name="Files"')
      expect(captured_body).not_to include('name="Files[]"')
      expect(captured_body).to include('filename="nda.pdf"')
    end

    it "passes through a Faraday::Multipart::FilePart unchanged" do
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      part = Faraday::Multipart::FilePart.new(StringIO.new("PDF"), "application/pdf", "x.pdf")
      described_class.new(api_key: "k").documents.send_document(title: "T", files: [part])

      expect(stub).to have_been_requested
    end

    it "skips nil top-level fields and defaults content_type when omitted, accepting string keys" do
      captured_body = nil
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .with { |req| captured_body = req.body.dup; true }
             .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      described_class.new(api_key: "k").documents.send_document(
        title: "T",
        brandId: nil,
        files: [{ "io" => StringIO.new("X"), "filename" => "x.bin" }]
      )

      expect(stub).to have_been_requested
      expect(captured_body).not_to include('name="brandId"')
      expect(captured_body).to include("application/octet-stream")
    end

    it "raises ArgumentError for file entries missing :io or :filename" do
      client = described_class.new(api_key: "k")

      expect { client.documents.send_document(title: "T", files: [{ filename: "x.pdf" }]) }
        .to raise_error(ArgumentError, /:io/)
      expect { client.documents.send_document(title: "T", files: [{ io: StringIO.new("x") }]) }
        .to raise_error(ArgumentError, /:filename/)
      expect { client.documents.send_document(title: "T", files: ["not a hash"]) }
        .to raise_error(ArgumentError, /Hash/)
    end

    it "JSON-encodes nested Hash body fields (e.g. metaData)" do
      captured_body = nil
      stub_request(:post, "https://api.boldsign.com/v1/document/send")
        .with { |req| captured_body = req.body.dup; true }
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      described_class.new(api_key: "k").documents.send_document(
        title: "T",
        meta_data: { source_document_uuid: "abc" },
        files: [{ io: StringIO.new("X"), filename: "x.pdf" }]
      )

      expect(captured_body).to include('name="metaData"')
      expect(captured_body).to include('"sourceDocumentUuid":"abc"')
    end

    it "raises NotImplementedError for multi-file bodies (still unsupported)" do
      part = Faraday::Multipart::FilePart.new(StringIO.new("x"), "application/pdf", "x.pdf")
      client = described_class.new(api_key: "k")

      expect { client.documents.send_document(title: "T", files: [part, part]) }
        .to raise_error(NotImplementedError, /multi-file/)
    end

    it "sends a multi-signer multipart request as repeated same-named parts, not a JSON array or bracket-suffixed field" do
      captured_body = nil
      stub = stub_request(:post, "https://api.boldsign.com/v1/document/send")
             .with { |req| captured_body = req.body.dup; true }
             .to_return(status: 200, body: '{"documentId":"abc"}',
                        headers: { "Content-Type" => "application/json" })

      described_class.new(api_key: "k").documents.send_document(
        title: "NDA",
        signers: [
          { name: "Jane", emailAddress: "jane@example.com", signerOrder: 1 },
          { name: "Cilian", emailAddress: "cilian@example.com", signerOrder: 2 }
        ],
        enableSigningOrder: true,
        files: [{ io: StringIO.new("PDF"), filename: "nda.pdf" }]
      )

      expect(stub).to have_been_requested
      # Two distinct `signers` parts, same field name, no `[]` suffix or
      # wrapping JSON array — each is its own JSON object.
      expect(captured_body.scan('name="signers"').size).to eq(2)
      expect(captured_body).not_to include('name="signers[]"')
      expect(captured_body).to include('"name":"Jane"')
      expect(captured_body).to include('"signerOrder":1')
      expect(captured_body).to include('"name":"Cilian"')
      expect(captured_body).to include('"signerOrder":2')
      expect(captured_body).not_to match(/name="signers"\r\n\r\n\[/)
    end
  end

  describe "error handling" do
    it "maps HTTP status codes to typed errors with message and status" do
      stub_request(:get, %r{api\.boldsign\.com/v1/document/list})
        .to_return(status: 401, body: '{"message":"bad key"}',
                   headers: { "Content-Type" => "application/json" })

      expect { described_class.new(api_key: "k").documents.list }
        .to raise_error(Boldsign::AuthenticationError, /bad key/) { |e|
          expect(e.status).to eq(401)
          expect(e.body).to eq({ "message" => "bad key" })
        }
    end

    it "raises ServerError for 5xx responses" do
      stub_request(:get, %r{api\.boldsign\.com/v1/document/list})
        .to_return(status: 503, body: "down")

      expect { described_class.new(api_key: "k").documents.list }
        .to raise_error(Boldsign::ServerError)
    end
  end
end
