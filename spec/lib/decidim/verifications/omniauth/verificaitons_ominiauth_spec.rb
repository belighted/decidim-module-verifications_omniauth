# frozen_string_literal: true

require "spec_helper"

describe Decidim, with_authorizations_engines: %w(saml csam) do
  describe ".authorization_engines" do
    it "returns an array of authorization engines" do
      auth_engines = described_class.authorization_engines

      expect(auth_engines.map(&:name)).to include("saml", "csam")
    end
  end
end
