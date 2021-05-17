# frozen_string_literal: true

require "active_support/concern"
require "valid_email2"

module AccountFormExtend
  extend ActiveSupport::Concern

  included do
    clear_validators!

    validates :name, presence: true
    validates :email, allow_blank: true, "valid_email_2/email": { disposable: true }
    validates :nickname, presence: true, format: Decidim::User::REGEXP_NICKNAME

    validates :nickname, length: { maximum: Decidim::User.nickname_max_length, allow_blank: true }
    validates :password, confirmation: true
    validates :password, password: { name: :name, email: :email, username: :nickname }, if: -> { password.present? }
    validates :password_confirmation, presence: true, if: :password_present
    validates :avatar, passthru: { to: Decidim::User }

    validate :unique_email, if: proc { |u| u.email.present? }
    validate :unique_nickname
    validate :personal_url_format
  end
end

Decidim::AccountForm.send(:include, AccountFormExtend)
