# frozen_string_literal: true

require "active_support/concern"
require "valid_email2"

module OmniauthRegistrationFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :step, String
    attribute :email_confirmation, String

    clear_validators!

    validates :email, presence: true
    validates :email, "valid_email_2/email": { disposable: true },
      confirmation: true#, if: proc { |u| u.email.present? }
    validate :unique_email, if: proc { |u| u.email.present? }
    validates :name, presence: true
    validates :provider, presence: true
    validates :uid, presence: true
    validates :tos_agreement, presence: true, if: proc { |u| u.step == "step2" }

    def normalized_nickname
      Decidim::UserBaseEntity.nicknamize(nickname || predefined_nickname, organization: current_organization)
    end

    def unique_email
      return true if Decidim::User.where(
        organization: context.current_organization,
        email: email
      ).where.not(id: context.current_user.id).empty?

      errors.add :email, :taken
      false
    end

    private

    def predefined_nickname
      "#{raw_data[:info][:first_name][0]}#{raw_data[:info][:last_name]}"
    end
  end
end

Decidim::OmniauthRegistrationForm.send(:include, OmniauthRegistrationFormExtend)
