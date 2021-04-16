# frozen_string_literal: true

require "active_support/concern"

module OmniauthRegistrationsControllerExtend
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, if: :saml_callback?

    before_action :manage_omniauth_authorization, except: [:logout]

    before_action :configure_permitted_parameters, except: [:logout]

    after_action :grant_omniauth_authorization, except: [:logout]

    def new
      @form = form(Decidim::OmniauthRegistrationForm).from_params(user_params)
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def create
      session[:verified_email] = verified_email
      @form = form(Decidim::OmniauthRegistrationForm).from_params(user_params)

      Decidim::CreateOmniauthRegistration.call(@form, verified_email) do
        on(:ok) do |user|
          session[:oauth_hash] = nil
          if user.active_for_authentication?
            sign_in_and_redirect user, event: :authentication
            set_flash_message :notice, :success, kind: provider_name(@form.provider)
          else
            expire_data_after_sign_in!
            user.resend_confirmation_instructions unless user.confirmed?
            redirect_to decidim.root_path
            flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
          end
        end

        on(:invalid) do
          session[:oauth_hash] = oauth_hash if oauth_hash.present?
          set_flash_message :notice, :success, kind: provider_name(@form.provider)
          render :new
        end

        on(:error) do |user|
          session[:oauth_hash] = oauth_hash if oauth_hash.present?

          if user.nil? && oauth_hash.present?
            set_flash_message :notice, :success, kind: provider_name(@form.provider)
          elsif user && user.errors[:email]
            set_flash_message :alert, :failure, kind: provider_name(@form.provider), reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
          end

          render :new
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def logout
      %w(notice success alert error warning info primary secondary omniauth logout).each do |type|
        flash.keep(type.to_sym)
      end

      # if params["state"].present? && params["state"] != stored_state
      #     # flash[:logout] = t("devise.registrations.logout.success", kind: provider_name(params[:provider]))
      #     flash[:alert] = t("devise.registrations.logout.error", kind: provider_name(params[:provider]))
      # end

      redirect_to after_sign_in_path_for(current_user)
    end

    def after_sign_in_path_for(user)
      if logout_uri_is_valid?
        oauth_data[:logout]
      elsif !pending_redirect?(user) && first_login_and_not_authorized?(user)
        decidim_verifications.authorizations_path
      else
        super
      end
    end

    def manage_omniauth_authorization
      # Rails.logger.debug "+++++++++++++++++++++++++"
      # Rails.logger.debug "OmniauthRegistrationsController.manage_omniauth_authorization"
      # Rails.logger.debug params
      # Rails.logger.debug "with current_user" if current_user
      # Rails.logger.debug "location_for :user --> " + store_location_for(:user, stored_location_for(:user)).to_s
      # Rails.logger.debug "location_for :redirect --> " + store_location_for(:redirect, stored_location_for(:redirect)).to_s
      # Rails.logger.debug "match : " + ( !!store_location_for(:user, stored_location_for(:user)).match(/^\/#{params[:action]}\/$/) ).inspect
      # Rails.logger.debug "omniauth_origin --> " + request.env["omniauth.origin"].split("?").first.to_s if request.env["omniauth.origin"].present?
      # Rails.logger.debug "new_user_session_url --> " + decidim.new_user_session_path.split("?").first.to_s
      # Rails.logger.debug "+++++++++++++++++++++++++"
      redirect_url = request.env.dig("omniauth.params", "redirect_url") || request.env.dig("omniauth.origin")

      location = if redirect_url.present? && safe_redirect?(redirect_url)
                   store_location_for(:user, redirect_url)
                 else
                   store_location_for(:user, stored_location_for(:user))
                 end

      Rails.logger.info "+" * 30
      Rails.logger.info "omniauth.origin: #{request.env.dig("omniauth.origin")}"
      Rails.logger.info "omniauth.params: #{request.env.dig("omniauth.params")}"
      Rails.logger.info "session > keys: #{session.keys}"
      Rails.logger.info "session > user_return_to: #{session[:user_return_to]}"
      Rails.logger.info "location: #{location}"
      Rails.logger.info "+" * 30

      return unless location.present? && location.match(%r{^/#{params[:action]}/$}).present?

      @verified_email = current_user.email if current_user

      if request.env["omniauth.origin"].present? && (request.env["omniauth.origin"].split("?").first != decidim.new_user_session_url.split("?").first)
        store_location_for(:user, request.env["omniauth.origin"])
      else
        store_location_for(:user, stored_location_for(:redirect))
      end
    end

    def grant_omniauth_authorization
      Rails.logger.debug "+++++++++++++++++++++++++"
      Rails.logger.debug "OmniauthRegistrationsController.grant_omniauth_authorization"
      Rails.logger.debug params
      Rails.logger.debug oauth_data.to_json if oauth_data
      Rails.logger.debug "+++++++++++++++++++++++++"

      return unless Decidim.authorization_workflows.any? { |a| a.try(:omniauth_provider).to_s == oauth_data[:provider].to_s }

      # just to be safe
      return unless current_user

      flash_for_granted = []
      flash_for_refused = []

      Decidim.authorization_workflows.select { |a| a.try(:omniauth_provider).to_s == oauth_data[:provider].to_s }.each do |workflow|
        form = Decidim::Verifications::Omniauth::OmniauthAuthorizationForm.from_params(user: current_user, provider: workflow.omniauth_provider, oauth_data: oauth_data[:info])

        authorization = Decidim::Authorization.find_or_initialize_by(
          user: current_user,
          name: workflow.name
        )

        Decidim::Verifications::Omniauth::ConfirmOmniauthAuthorization.call(authorization, form, session) do
          on(:ok) do
            flash_for_granted << t("authorizations.new.success", scope: "decidim.verifications.omniauth", locale: current_user.locale)
          end
          on(:invalid) do
            flash_for_refused << form.errors.to_h.values.join(". ")
          end
        end
      end

      flash[:success] = flash_for_granted.uniq.join(". ") if flash_for_granted.present?
      flash[:alert] = flash_for_refused.uniq.join(". ") if flash_for_refused.present?
    end

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: Decidim::OmniauthRegistrationForm.extra_params) if Decidim::OmniauthRegistrationForm.respond_to?(:extra_params)
    end

    private

    def oauth_data
      @oauth_data ||= (oauth_hash.presence || (session[:oauth_hash] || {}).deep_symbolize_keys).slice(:provider, :uid, :info, :logout)
    end

    def user_params
      if user_params_from_oauth_hash
        if params[:user]
          user_params_from_oauth_hash.merge(params[:user].to_unsafe_h)
        else
          user_params_from_oauth_hash
        end
      else
        params[:user]
      end
    end

    # Private: Create form params from omniauth hash
    # Since we are using trusted omniauth data we are generating a valid signature.
    def user_params_from_oauth_hash
      return nil if oauth_data.empty?

      {
        provider: oauth_data[:provider],
        uid: oauth_data[:uid],
        name: oauth_data[:info][:name],
        nickname: oauth_data[:info][:nickname],
        email: oauth_data[:info][:email],
        oauth_signature: Decidim::OmniauthRegistrationForm.create_signature(oauth_data[:provider], oauth_data[:uid]),
        avatar_url: oauth_data[:info][:image],
        raw_data: oauth_hash
      }
    end

    def verified_email
      @verified_email ||= oauth_data.dig(:info, :email) || session[:verified_email]
    end

    def logout_uri_is_valid?
      oauth_data[:logout] &&
        oauth_data[:logout] =~ URI::DEFAULT_PARSER.make_regexp
    end

    def stored_state
      session.delete("omniauth.state")
    end

    def provider_name(provider)
      current_organization.enabled_omniauth_providers[provider.to_sym][:provider_name].presence || provider.capitalize
    end

    def saml_callback?
      Rails.logger.info("request path: #{request.path}")
      Rails.logger.info("is saml callback: #{request.path.end_with?("saml/callback") || request.path.end_with?("csam/callback")}")

      request.path.end_with?("saml/callback") || request.path.end_with?("csam/callback")
    end

    def safe_redirect?(redirect_url)
      redirect_host = URI.parse(redirect_url).host

      !(redirect_url.start_with?("http") ||
        redirect_host.present? && redirect_host != current_organization.host)
    end
  end
end

Decidim::Devise::OmniauthRegistrationsController.send(:include, OmniauthRegistrationsControllerExtend)
