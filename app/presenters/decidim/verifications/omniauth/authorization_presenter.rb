# frozen_string_literal: true

module Decidim
  module Verifications
    module Omniauth
      class AuthorizationPresenter < SimpleDelegator
        def authorized?
          verification_metadata["authorized"] == true
        end
      end
    end
  end
end
