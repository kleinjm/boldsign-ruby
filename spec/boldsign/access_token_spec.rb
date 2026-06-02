require "spec_helper"

RSpec.describe Boldsign::AccessToken do
  let(:token_url) { "https://account.boldsign.com/connect/token" }

  def access_token(**opts)
    described_class.new(client_id: "cid", client_secret: "secret", token_url: token_url, **opts)
  end

  def stub_token(body:, status: 200)
    stub_request(:post, token_url)
      .to_return(status: status,
                 body: body.is_a?(String) ? body : body.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  it "requests a token with the client_credentials grant and default scope" do
    stub = stub_request(:post, token_url)
           .with(
             headers: { "Content-Type" => "application/x-www-form-urlencoded" },
             body: {
               "grant_type" => "client_credentials",
               "client_id" => "cid",
               "client_secret" => "secret",
               "scope" => "BoldSign.Documents.All"
             }
           )
           .to_return(status: 200, body: { access_token: "tok", expires_in: 3600 }.to_json,
                      headers: { "Content-Type" => "application/json" })

    expect(access_token.value).to eq("tok")
    expect(stub).to have_been_requested
  end

  it "requests a custom scope when provided" do
    stub = stub_request(:post, token_url)
           .with(body: hash_including("scope" => "BoldSign.Templates.All"))
           .to_return(status: 200, body: { access_token: "tok", expires_in: 3600 }.to_json,
                      headers: { "Content-Type" => "application/json" })

    expect(access_token(scope: "BoldSign.Templates.All").value).to eq("tok")
    expect(stub).to have_been_requested
  end

  it "caches the token until near expiry" do
    stub = stub_token(body: { access_token: "tok", expires_in: 3600 })

    token = access_token
    expect(token.value).to eq("tok")
    expect(token.value).to eq("tok")

    expect(stub).to have_been_requested.once
  end

  it "refreshes once the cached token has expired" do
    stub = stub_token(body: { access_token: "tok", expires_in: 0 })

    token = access_token
    token.value
    token.value

    expect(stub).to have_been_requested.twice
  end

  it "falls back to a default lifetime when expires_in is absent" do
    stub = stub_token(body: { access_token: "tok" })

    token = access_token
    token.value
    token.value

    expect(stub).to have_been_requested.once
  end

  describe "error handling" do
    it "raises AuthenticationError using error_description" do
      stub_token(status: 400, body: { error_description: "bad creds" })

      expect { access_token.value }
        .to raise_error(Boldsign::AuthenticationError, /bad creds/) { |e|
          expect(e.status).to eq(400)
        }
    end

    it "falls back to the error key when error_description is absent" do
      stub_token(status: 401, body: { error: "invalid_client" })

      expect { access_token.value }
        .to raise_error(Boldsign::AuthenticationError, /invalid_client/)
    end

    it "stringifies a hash body with no recognized error keys" do
      stub_token(status: 400, body: { foo: "bar" })

      expect { access_token.value }
        .to raise_error(Boldsign::AuthenticationError, /foo/)
    end

    it "uses the raw body for non-JSON error responses" do
      stub_token(status: 500, body: "boom")

      expect { access_token.value }
        .to raise_error(Boldsign::AuthenticationError, /boom/) { |e|
          expect(e.body).to eq("boom")
        }
    end
  end
end
