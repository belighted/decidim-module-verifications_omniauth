# frozen_string_literal: true

FactoryBot.define do
  factory :verifications_omniauth_authorization, parent: :authorization do
    encrypted_metadata { '' }
  end
end
