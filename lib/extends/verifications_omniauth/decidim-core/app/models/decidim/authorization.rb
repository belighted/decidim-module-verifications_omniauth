# frozen_string_literal: true

require "active_support/concern"

module AuthorizationExtend
  extend ActiveSupport::Concern

  included do
    def self.create_or_update_from(handler)
      authorization = find_or_initialize_by(
        user: handler.user,
        name: handler.handler_name
      )

      authorization.attributes = {
        unique_id: handler.unique_id,
        encrypted_metadata: Decidim::MetadataEncryptor.new(
          uid: handler.unique_id
        ).encrypt(handler.metadata)
      }

      authorization.grant!
    end

    def metadata
      encryptor.decrypt(encrypted_metadata)
    end

    def metadata=(data)
      self.encrypted_metadata = encryptor.encrypt(data)
    end

    private

    def encryptor
      @encryptor ||= Decidim::MetadataEncryptor.new(uid: unique_id)
    end
  end
end

Decidim::Authorization.send(:include, AuthorizationExtend)
