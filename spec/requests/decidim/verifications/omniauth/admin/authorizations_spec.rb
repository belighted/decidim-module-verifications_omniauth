# frozen_string_literal: true

require "spec_helper"

describe "Admin::Authorizations", type: :request do
  let(:user) { create(:user, :admin) }

  before { sign_in user, scope: :user }

  describe "#index" do
    before do
      # pending
      get decidim_admin_csam.root_path, headers: { host: user.organization.host }
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to render_template(:index) }
  end
end
