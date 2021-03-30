# frozen_string_literal: true

require "active_support/concern"

module CreateOmniauthRegistrationExtend
  extend ActiveSupport::Concern

  included do
    def initialize(form, verified_email = nil)
      @form = form
      @verified_email = verified_email
      @after_confirmation = false
    end

    def call
      verify_oauth_signature!

      # we need add option to assign email and tos after first step for csam
      if existing_identity && form.step == "step2"
        return broadcast(:invalid) if form.invalid?

        create_or_find_user
        @identity = existing_identity
        @user.after_confirmation if @after_confirmation
        verify_user_confirmed(@user)
        trigger_omniauth_registration

        return broadcast(:ok, @user)
      elsif existing_identity
        user = existing_identity.user
        verify_user_confirmed(user)

        return broadcast(:ok, user)
      end

      transaction do
        create_or_find_user
        create_identity
      end

      broadcast(:confirm, @user)
    rescue ActiveRecord::RecordInvalid => e
      broadcast(:error, e.record)
    end

    private

    def verify_user_confirmed(user)
      return true if user.confirmed?
      return false if user.email.present? && user.email != verified_email

      user.skip_confirmation!
      user.save!
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def create_or_find_user
      generated_password = SecureRandom.hex

      if (verified_email || form.email).blank? && form.step == "step1"
        @user = Decidim::User.new(
          email: "",
          organization: organization,
          name: form.name,
          nickname: form.normalized_nickname,
          newsletter_notifications_at: nil,
          email_on_notification: false,
          accepted_tos_version: organization.tos_version,
          # managed: true,
          password: generated_password,
          password_confirmation: generated_password
        )
        @user.skip_confirmation!
      else
        # for csam we need a different option to find user, since we don't have an email
        criterias = if form.nickname.present?
                      { nickname: form.nickname, organization: organization }
                    else
                      { email: verified_email, organization: organization }
                    end

        @user = Decidim::User.find_or_initialize_by(criterias)

        if @user.persisted? && form.step == "step2"
          @user.email = form.email || verified_email
          @user.tos_agreement = form.tos_agreement
          @user.accepted_tos_version = Time.current
          @user.confirmed_at = nil if verified_email != form.email
          @after_confirmation = true if form.email.present? && verified_email != form.email
        elsif @user.persisted?
          # If user has left the account unconfirmed and later on decides to sign
          # in with omniauth with an already verified account, the account needs
          # to be marked confirmed.
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
        else
          @user.name = form.name
          @user.email = form.email || verified_email
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.email_on_notification = true
          @user.password = generated_password
          @user.password_confirmation = generated_password
          @user.remote_avatar_url = form.avatar_url if form.avatar_url.present?
          @user.skip_confirmation!
        end
      end

      @user.save!
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

Decidim::CreateOmniauthRegistration.send(:include, CreateOmniauthRegistrationExtend)
