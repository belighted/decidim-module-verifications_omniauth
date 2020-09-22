# frozen_string_literal: true

require 'omniauth-saml'
require 'savon'
require 'signer'
require 'nokogiri'

module OmniAuth
  module Strategies
    class EidSaml < OmniAuth::Strategies::SAML
      option :name, :saml

      option :origin_param, 'redirect_url'

      option :authn_context_comparison, 'minimum'
      option :name_identifier_format, 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
      option :uid_attribute, 'urn:be:fedict:iam:attr:fedid'
      option :attribute_service_name, 'Eidas extra attributes'
      option :attribute_statements,
             name: %w[uid name],
             email: %w[mail email],
             first_name: %w[surname first_name firstname firstName],
             last_name: %w[givenName last_name lastname lastName],
             # default_locale: ['locale', 'urn:be:fedict:iam:attr:locale'],
             locale: ['PrefLanguage', 'pref_language', 'preflanguage', 'locale', 'urn:be:fedict:iam:attr:locale'],
             nickname: ['uid'],
             rrn: %w[egovNRN egovnrn egov_nrn nrn rrn]
      # authentication_method: ['authenticationmethod'],
      # authentication_level: ['urn:be:fedict:iam:attr:authenticationmethod'],
      # authentication_context: ['urn:be:fedict:iam:attr:context']
      option :idp_cert_fingerprint_validator, -> (fingerprint) { fingerprint }
      option :force_authn, true
      option :security,
             authn_requests_signed: true, # Enable or not signature on AuthNRequest
             logout_requests_signed: true, # Enable or not signature on Logout Request
             logout_responses_signed: true, # Enable or not signature on Logout Response
             want_assertions_signed: true, # Enable or not the requirement of signed assertion
             metadata_signed: true, # Enable or not signature on Metadata
             digest_method: XMLSecurity::Document::SHA256,
             signature_method: XMLSecurity::Document::RSA_SHA256,
             embed_sign: false

      option :person_services_wsdl, nil
      option :person_services_cert, nil
      option :person_services_ca_cert, nil
      option :person_services_key, nil
      option :person_services_secret, nil
      option :person_services_proxy, nil
      option :person_services_fallback_rrn, nil

      option :enable_scope_mapping, false
      option :scope_mapping_level_id, nil

      info do
        found_attributes = options.attribute_statements.map do |key, values|
          attribute = find_attribute_by(values)
          [key, attribute]
        end

        hash_attributes = Hash[found_attributes]

        hash_attributes["name"] = "#{hash_attributes["last_name"]} #{hash_attributes["first_name"]}"

        if hash_attributes["first_name"].present? && hash_attributes["last_name"].present?
          hash_attributes["nickname"] = "#{hash_attributes["first_name"].split(" ").first}#{hash_attributes["last_name"][0]}".downcase
        end

        hash_attributes
      end
    end
  end
end

OmniAuth.config.add_camelization 'saml', 'SAML'
