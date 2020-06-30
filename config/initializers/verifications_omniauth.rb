# frozen_string_literal: true

require "extends/verifications/workflow_manifest"

# in the app initializer...
# Decidim::Verifications.register_workflow(:saml) do |workflow|
#   workflow.engine = Decidim::Verifications::Omniauth::Engine
#   workflow.admin_engine = Decidim::Verifications::Omniauth::AdminEngine
#   workflow.action_authorizer = "Decidim::Verifications::Omniauth::BosaActionAuthorizer"
#   # workflow.form = "Decidim::Verifications::Omniauth::OmniauthAuthorizationForm"
#   workflow.omniauth_provider = :saml
#   workflow.minimum_age = 16
# end
