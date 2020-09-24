# frozen_string_literal: true

require "spec_helper"

describe Decidim::Verifications::Omniauth::ConfirmOmniauthAuthorization do
  subject { described_class.new(authorization, form, session) }

  let(:session) { {} }

  let(:authorization) do
    build_stubbed(:verifications_omniauth_authorization, :pending, name: "test", verification_metadata: verification_metadata)
  end

  let(:verification_metadata) do
    { "secret_code" => "XX42YY" }
  end

  describe "#call" do
    context "when the form is not valid" do
      let(:form) do
        instance_double(Decidim::Verifications::Omniauth::OmniauthAuthorizationForm, valid?: false)
      end

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the form is valid" do
      context "when is not confirmed successfuly" do
        let(:form) do
          instance_double(Decidim::Verifications::Omniauth::OmniauthAuthorizationForm,
                          valid?: true,
                          verification_metadata: { "secret_code" => nil })
        end

        it "is not valid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when confirmed successfuly" do
        let(:metadata) do
          { nickname: "Lorem ipsum", first_name: "Lorem", last_name: "ipsum" }
        end
        let(:form) do
          instance_double(Decidim::Verifications::Omniauth::OmniauthAuthorizationForm,
                          valid?: true,
                          verification_metadata: verification_metadata,
                          unique_id: "12333-1233",
                          metadata: metadata)
        end

        it "broadcasts ok" do
          expect(authorization).to receive(:grant!)
          expect { subject.call }.to broadcast(:ok)
        end
      end
    end
  end
end
