# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/FilePath
describe Decidim::Verifications::Omniauth::AuthorizationPresenter do
  let(:presenter) { described_class.new(authorization) }

  describe "#authorized?" do
    subject { presenter.authorized? }

    context "when is truthly" do
      let(:authorization) { build_stubbed(:authorization, verification_metadata: { "authorized" => true }) }

      it { is_expected.to be_truthy }
    end

    context "when is falsy" do
      let(:authorization) { build_stubbed(:authorization, verification_metadata: { "authorized" => false }) }

      it { is_expected.to be_falsy }
    end
  end
end
# rubocop:enable RSpec/FilePath
