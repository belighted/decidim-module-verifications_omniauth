# frozen_string_literal: true

require "spec_helper"

describe Decidim::Authorization do
  let(:authorization) { build(:authorization) }

  it "is valid" do
    expect(authorization).to be_valid
  end

  context "when leaving verification data around" do
    let(:authorization) do
      build(:authorization, verification_metadata: { sensible_stuff: "123456" })
    end

    it "is not valid" do
      expect(authorization).not_to be_valid
    end
  end

  describe "self.create_or_update_from" do
    let(:user) { create(:user) }
    let(:handler_name) { "dummy_authorization_handler" }
    let(:metadata) { { document_number: "1233123X", postal_code: "23-445" } }
    let(:params) do
      { user: user, handler_name: handler_name, unique_id: "12345" }.merge(metadata)
    end

    let(:authorization_handler) do
      Decidim::AuthorizationHandler.handler_for(handler_name, params)
    end

    context "when creates" do
      it "adds a new Authorization record" do
        expect { described_class.create_or_update_from(authorization_handler) }
          .to change(Decidim::Authorization, :count)
      end
    end

    context "when updates" do
      let(:updated_metadata) { { document_number: "15123X", postal_code: "55-444" } }
      let(:params) do
        { user: user, handler_name: handler_name }.merge(updated_metadata)
      end
      let!(:authorization) do
        create(:authorization,
               user: user,
               name: handler_name,
               unique_id: metadata[:document_number],
               metadata: metadata)
      end

      it "is not creating a new Authorization record" do
        expect { described_class.create_or_update_from(authorization_handler) }
          .not_to change(Decidim::Authorization, :count)
      end

      it "updates the attributes" do
        described_class.create_or_update_from(authorization_handler)
        authorization.reload

        expect(authorization.unique_id).to eq(updated_metadata[:document_number])
      end
    end
  end
end
