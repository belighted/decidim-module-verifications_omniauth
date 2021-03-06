# frozen_string_literal: true

module Decidim
  module Verifications
    module Omniauth
      autoload :ActionAuthorizer, "decidim/verifications/omniauth/action_authorizer"

      class Engine < ::Rails::Engine
        isolate_namespace Decidim::Verifications::Omniauth

        routes do
          get "authorize", to: "authorizations#new"
          get "callback", to: "authorizations#callback"
          root to: "authorizations#new"
        end

        initializer "extends" do
          Dir.glob("#{Decidim::Verifications::Omniauth::Engine.root}/lib/extends/verifications_omniauth/**/*.rb").each do |override|
            require_dependency override
          end
        end

        initializer "MongoDB" do
          Mongoid.load!(File.path("#{Decidim::Verifications::Omniauth::Engine.root}/config/mongoid.yml"))
        end
      end
    end
  end
end
