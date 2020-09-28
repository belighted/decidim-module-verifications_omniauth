# frozen_string_literal: true

require "spec_helper"

describe "CSAM omniauth workflow", type: :request do
  let(:user) { create(:user) }

  before { sign_in user, scope: :user }

  describe "new authorization" do
    before { get "/csam", headers: { host: user.organization.host } }

    it { is_expected.to redirect_to("/users/auth/csam") }
  end
end
