require "spec_helper"

RSpec.describe Boldsign::Client do
  describe "#initialize" do
    it "raises ConfigurationError when API key is missing" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(Boldsign::ConfigurationError)
    end

    it "resolves base_url from region and allows override" do
      us_client     = described_class.new(api_key: "k", region: :us)
      eu_client     = described_class.new(api_key: "k", region: :eu)
      custom_client = described_class.new(api_key: "k", base_url: "https://example.test")

      expect(us_client.base_url).to eq("https://api.boldsign.com")
      expect(eu_client.base_url).to eq("https://api-eu.boldsign.com")
      expect(custom_client.base_url).to eq("https://example.test")
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
             .with(body: { title: "Hi" }.to_json,
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
      expect(captured_body).to include('name="signers"')
      expect(captured_body).to include('"emailAddress":"jane@example.com"')
      expect(captured_body).to include('name="disableEmails"')
      # Faraday::Multipart serializes Array values with a trailing `[]` suffix.
      expect(captured_body).to include('name="Files[]"')
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
