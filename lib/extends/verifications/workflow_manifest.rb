# frozen_string_literal: true
require "active_support/concern"

module WorkflowManifestExtend
  extend ActiveSupport::Concern

  included do

    attribute :omniauth_provider, String
    attribute :minimum_age, Integer, default: 0

  end
end

Decidim::Verifications::WorkflowManifest.send(:include, WorkflowManifestExtend)