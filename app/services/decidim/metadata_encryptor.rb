# frozen_string_literal: true

module Decidim
  # Service to encrypt and decrypt metadata
  class MetadataEncryptor
    attr_reader :uid

    def initialize(args = {})
      uid = args.fetch(:uid) || 'default'
      @key = ActiveSupport::KeyGenerator.new(uid).generate_key(
        Rails.application.secrets.secret_key_base,
        ActiveSupport::MessageEncryptor.key_len
      )
      @encryptor = ActiveSupport::MessageEncryptor.new(@key)
    end

    def encrypt(data)
      @encryptor.encrypt_and_sign(data)
    end

    def decrypt(encrypted_data)
      @encryptor.decrypt_and_verify(encrypted_data)
    end
  end
end
