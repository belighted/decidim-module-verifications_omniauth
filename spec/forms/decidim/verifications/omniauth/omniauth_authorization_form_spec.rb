# frozen_string_literal: true

require "spec_helper"

describe Decidim::Verifications::Omniauth::OmniauthAuthorizationForm do
  let(:identity) { create(:identity) }
  let(:handler) { described_class.new(provider: identity.provider, oauth_data: { secret_code: "test" }, user: identity.user) }

  describe "#metadata" do
    subject { handler.metadata.keys }

    it { is_expected.to include(:provider, :secret_code) }
  end

  describe "#form_attributes" do
    subject { handler.form_attributes }

    it { is_expected.to match_array([:handler_name]) }
    it { is_expected.not_to match_array([:id, :user, :provider, :oauth_data]) }
  end

  describe "#to_partial_path" do
    subject { handler.to_partial_path }

    it { is_expected.to eq("omniauth_authorization/form") }
  end

  describe "unique_id" do
    subject { handler.unique_id }

    it { is_expected.to eq(identity.uid) }
  end

  describe "valid?" do
    context "when validation is successfuly" do
      subject { handler.valid? }

      it { is_expected.to be_truthy }
    end

    context "when there is no identity" do
      subject { handler.valid? }

      let(:user) { build_stubbed(:user) }
      let(:handler) { described_class.new(provider: "test", oauth_data: { secret_code: "test" }, user: user) }

      it { is_expected.to be_falsy }
    end
  end
end
