# frozen_string_literal: true
require "active_support/concern"

module OmniauthRegistrationFormExtend
  extend ActiveSupport::Concern

  included do

    validate :email, :email_is_unique, unless: -> {email.blank?}

    def email_is_unique
      errors.add(:email, "#{email} #{I18n.t("errors.messages.taken")}") if Decidim::User.where(organization: current_organization, email: email).exists?
    end

  end
end

Decidim::OmniauthRegistrationForm.send(:include, OmniauthRegistrationFormExtend)
