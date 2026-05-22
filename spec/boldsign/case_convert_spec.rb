require "spec_helper"

RSpec.describe Boldsign::CaseConvert do
  describe ".pascalize" do
    it "converts snake_case symbol keys recursively" do
      input = {
        title: "NDA",
        signers: [{ email_address: "x@example.com", form_fields: [{ field_type: "Signature" }] }],
        metadata: { source_document_uuid: "u" }
      }

      expect(described_class.pascalize(input)).to eq(
        "Title" => "NDA",
        "Signers" => [{ "EmailAddress" => "x@example.com", "FormFields" => [{ "FieldType" => "Signature" }] }],
        "Metadata" => { "SourceDocumentUuid" => "u" }
      )
    end

    it "leaves already-PascalCase keys unchanged" do
      expect(described_class.pascalize("Title" => "x", "Signers" => [])).to eq("Title" => "x", "Signers" => [])
    end

    it "uppercases the first letter of camelCase keys" do
      expect(described_class.pascalize(emailAddress: "x")).to eq("EmailAddress" => "x")
    end

    it "leaves non-Hash, non-Array values untouched" do
      io = StringIO.new("bytes")
      expect(described_class.pascalize(io)).to equal(io)
      expect(described_class.pascalize("string")).to eq("string")
      expect(described_class.pascalize(42)).to eq(42)
      expect(described_class.pascalize(nil)).to be_nil
    end

    it "handles empty string keys safely" do
      expect(described_class.pascalize_key("")).to eq("")
    end

    it "skips empty segments from leading/trailing/consecutive underscores" do
      expect(described_class.pascalize_key("_foo_bar_")).to eq("FooBar")
      expect(described_class.pascalize_key("foo__bar")).to eq("FooBar")
    end
  end
end
