# frozen_string_literal: true

module Decidim
  module Verifications
    # Helper method related to initiative object and its internal state.
    module MetadataHelper
      include ActionView::Helpers::TagHelper
      include Decidim::SanitizeHelper

      def metadata_modal_button_to(authorization, html_options, &block)
        html_options ||= {}
        html_options["data-open"] = "authorizationModal"
        html_options["data-open-url"] = metadata_authorization_path(authorization)
        html_options["onclick"] = "event.preventDefault();"
        send("button_to", "", html_options, &block)
      end

      def humanize_handler_name(name)
        Rails.application.secrets.dig(:omniauth, name.to_sym, :provider_name).presence || name.to_s.humanize
      end
    end
  end
end
