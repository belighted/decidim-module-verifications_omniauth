# frozen_string_literal: true

module Decidim
  module Verifications
    module Omniauth
      class AdminEngine < ::Rails::Engine
        isolate_namespace Decidim::Verifications::Omniauth::Admin

        paths["db/migrate"] = nil
        paths["lib/tasks"] = nil

        routes do
          resources :authorizations, only: [:index] do
            member do
              get :metadata, to: "metadata#show"
            end
          end
          root to: "authorizations#index"
        end

        initializer "extends" do
          Dir.glob("#{Decidim::Verifications::Omniauth::Engine.root}/lib/extends/verifications_omniauth/**/*.rb").each do |override|
            require_dependency override
          end
        end
      end
    end
  end
end
