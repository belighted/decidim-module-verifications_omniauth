# frozen_string_literal: true

require "decidim/dev"

if ENV["CODECOV"]
  require "simplecov"
  SimpleCov.start "rails"
end

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = File.expand_path(File.join("spec", "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Decidim::WardenTestHelpers, type: :request
  config.include Rails.application.routes.url_helpers, type: :request

  config.before :each, type: :request do
    Warden.test_mode!
  end

  config.after :each, type: :request do
    Warden.test_reset!
  end
end
