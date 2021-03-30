# frozen_string_literal: true

require "active_support/concern"

module OmniauthRegistrationFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :step, String
    attribute :email_confirmation, String

    clear_validators!

    validates :email, confirmation: true, if: proc { |u| u.email.present? }
    validates :name, presence: true
    validates :provider, presence: true
    validates :uid, presence: true
    validates :tos_agreement, presence: true, if: proc { |u| u.step == "step2" }

    def normalized_nickname
      Decidim::UserBaseEntity.nicknamize(nickname || predefined_nickname, organization: current_organization)
    end

    private

    def predefined_nickname
      "#{raw_data[:info][:first_name][0]}#{raw_data[:info][:last_name]}"
    end
  end
end

Decidim::OmniauthRegistrationForm.send(:include, OmniauthRegistrationFormExtend)
