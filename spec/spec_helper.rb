# frozen_string_literal: true

require "decidim/dev"

if ENV["CODECOV"]
  require "simplecov"
  SimpleCov.start "rails"
end

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = File.expand_path(File.join("spec", "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
