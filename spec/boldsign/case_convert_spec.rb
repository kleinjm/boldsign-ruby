require "spec_helper"

RSpec.describe Boldsign::CaseConvert do
  describe ".camelize" do
    it "converts snake_case symbol keys recursively to camelCase" do
      input = {
        title: "NDA",
        signers: [{ email_address: "x@example.com", form_fields: [{ field_type: "Signature" }] }],
        meta_data: { source_document_uuid: "u" }
      }

      expect(described_class.camelize(input)).to eq(
        "title" => "NDA",
        "signers" => [{ "emailAddress" => "x@example.com", "formFields" => [{ "fieldType" => "Signature" }] }],
        "metaData" => { "sourceDocumentUuid" => "u" }
      )
    end

    it "leaves already-camelCase keys unchanged" do
      expect(described_class.camelize("title" => "x", "emailAddress" => "y")).to eq(
        "title" => "x",
        "emailAddress" => "y"
      )
    end

    it "lowercases the first letter of PascalCase keys" do
      expect(described_class.camelize(EmailAddress: "x")).to eq("emailAddress" => "x")
    end

    it "leaves non-Hash, non-Array values untouched" do
      io = StringIO.new("bytes")
      expect(described_class.camelize(io)).to equal(io)
      expect(described_class.camelize("string")).to eq("string")
      expect(described_class.camelize(42)).to eq(42)
      expect(described_class.camelize(nil)).to be_nil
    end

    it "handles empty string keys safely" do
      expect(described_class.camelize_key("")).to eq("")
    end

    it "skips empty segments from leading/trailing/consecutive underscores" do
      expect(described_class.camelize_key("_foo_bar_")).to eq("fooBar")
      expect(described_class.camelize_key("foo__bar")).to eq("fooBar")
    end

    it "returns the original string when underscore splits leave nothing" do
      expect(described_class.camelize_key("___")).to eq("___")
    end

    it "guards capitalize_word and lowercase_first against empty input" do
      expect(described_class.capitalize_word("")).to eq("")
      expect(described_class.lowercase_first("")).to eq("")
    end
  end
end
