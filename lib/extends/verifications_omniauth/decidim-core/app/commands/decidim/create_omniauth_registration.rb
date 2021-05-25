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

        @user = existing_identity.user
        @user.email = form.email || verified_email
        @user.tos_agreement = form.tos_agreement
        @user.accepted_tos_version = Time.current
        @user.confirmed_at = nil if verified_email != form.email
        @user.save! # to save confirmed_at, so it will make user active for authentication (otherwise its unable to sign in)

        @after_confirmation = true if form.email.present? && verified_email != form.email
        @user.after_confirmation if @after_confirmation
        verify_user_confirmed(@user)

        @identity = existing_identity
        trigger_omniauth_registration

        return broadcast(:ok, @user)
      elsif existing_identity
        user = existing_identity.user
        verify_user_confirmed(user)

        return broadcast(:ok, user)
      end

      transaction do
        create_or_find_user
        @identity = create_identity
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
    # def create_or_find_user
    #   generated_password = SecureRandom.hex
    #
    #   if verified_email.blank?
    #     @user = Decidim::User.new(
    #       email: "",
    #       organization: organization,
    #       name: form.name,
    #       nickname: form.normalized_nickname,
    #       newsletter_notifications_at: nil,
    #       email_on_notification: false,
    #       password: generated_password,
    #       password_confirmation: generated_password
    #     )
    #     @user.skip_confirmation!
    #   else
    #     @user = Decidim::User.find_or_initialize_by(
    #       email: verified_email,
    #       organization: organization
    #     )
    #
    #     if @user.persisted?
    #       # If user has left the account unconfirmed and later on decides to sign
    #       # in with omniauth with an already verified account, the account needs
    #       # to be marked confirmed.
    #       @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
    #     else
    #       @user.name = form.name
    #       @user.email = form.email || verified_email
    #       @user.nickname = form.normalized_nickname
    #       @user.newsletter_notifications_at = nil
    #       @user.email_on_notification = true
    #       @user.password = generated_password
    #       @user.password_confirmation = generated_password
    #       @user.remote_avatar_url = form.avatar_url if form.avatar_url.present?
    #       @user.skip_confirmation!
    #     end
    #   end
    #
    #   @user.save!
    # end
    # Do not fallback to email as a way to find a user, we rely only on Identity record
    def create_or_find_user
      generated_password = SecureRandom.hex

      @user = Decidim::User.new(
        email: "",
        organization: organization,
        name: form.name,
        nickname: form.normalized_nickname,
        newsletter_notifications_at: nil,
        email_on_notification: false,
        password: generated_password,
        password_confirmation: generated_password
      )
      @user.skip_confirmation!

      @user.save!
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def existing_identity
      return @existing_identity if @existing_identity.present?

      @existing_identity ||= Identity.find_by(
        user: organization.users,
        provider: form.provider,
        uid: form.uid
      )

      rrn = form.raw_data.dig(:info, :rrn)
      if !@existing_identity && rrn.present?
        enterprise_context_identity = Identity.find_by(
          user: organization.users,
          provider: 'saml',
          rrn_hash: Digest::SHA256.base64digest(rrn)
        )
        if enterprise_context_identity.present? && enterprise_context_identity.user.persisted?
          @user = enterprise_context_identity.user
          @existing_identity = create_identity
        end
      end

      @existing_identity
    end
  end
end

Decidim::CreateOmniauthRegistration.send(:include, CreateOmniauthRegistrationExtend)
