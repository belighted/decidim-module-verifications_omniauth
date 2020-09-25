# frozen_string_literal: true

require "spec_helper"

describe Decidim::Verifications::Omniauth::MetadataEncryptor do
  describe "#uid" do
    context "when uuid is defined" do
      subject { described_class.new }

      it "returns default value" do
        expect(subject.uid).to eq("default")
      end
    end

    context "when uuid defined" do
      subject { described_class.new(uid: uid) }

      let(:uid) { "test-1233" }

      it "returns default value" do
        expect(subject.uid).to eq(uid)
      end
    end
  end

  describe "#encrypt" do
    subject { described_class.new }

    let(:data) { { data: "secret" } }

    it "encrypts data" do
      result = subject.encrypt(data)

      expect(result).not_to eq(data)
      expect(result).to end_with("==")
    end
  end

  describe "#encrypt" do
    subject { described_class.new }

    let(:data) { { data: "secret" } }
    let(:encrypted_data) { "TXw1Eh0xuog39T+TIe9haL/FFJXRRd6f--++ohl1eB/Gb3SCmA--49+uEhacy7DnoM3ujo3OKw==" }

    it "decrypts data" do
      expect(subject.decrypt(encrypted_data)).to eq(data)
    end
  end
end
