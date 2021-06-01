# frozen_string_literal: true

require "omniauth-saml"
require "savon"
require "akami"
require "omniauth/saml/services/get_person"

module OmniAuth
  module Strategies
    class EidCsam < OmniAuth::Strategies::EidSaml
      option :name, :csam

      option :origin_param, "redirect_url"

      POSTAL_CODE_LOOKUP = [
        :"v3:get_person_response",
        :"v2:basic_natural_person",
        :"v1:address",
        :"v1:structured_address",
        :"v1:municipality",
        :"v11:code"
      ].freeze

      MUNICIPALITY_LOOKUP = [
        :"v3:get_person_response",
        :"v2:basic_natural_person",
        :"v1:address",
        :"v1:structured_address",
        :"v1:municipality",
        :"v11:description"
      ].freeze

      BIRTH_CENTURY_LOOKUP = [
        :"v3:get_person_response",
        :"v2:basic_natural_person",
        :"v21:basic_person",
        :"v21:official_birth_date",
        :"v22:century"
      ].freeze

      BIRTH_YEAR_LOOKUP = [
        :"v3:get_person_response",
        :"v2:basic_natural_person",
        :"v21:basic_person",
        :"v21:official_birth_date",
        :"v22:year"
      ].freeze

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

        if @person_services_response.present?
          official_birth_date_day = @person_services_response.dig(
            :"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:day"
          )
          official_birth_date_month = @person_services_response.dig(
            :"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:month"
          )
          official_birth_date_year = "#{@person_services_response.dig(*BIRTH_CENTURY_LOOKUP)}#{@person_services_response.dig(*BIRTH_YEAR_LOOKUP)}"

          if official_birth_date_day.present? && official_birth_date_month.present? && official_birth_date_year.present?
            hash_attributes["official_birth_date"] = Date.strptime("#{official_birth_date_day}/#{official_birth_date_month}/#{official_birth_date_year}", "%d/%m/%Y")
          end

          hash_attributes["postal_code"] = @person_services_response.dig(*POSTAL_CODE_LOOKUP)
          hash_attributes["municipality"] = @person_services_response.dig(*MUNICIPALITY_LOOKUP)
        end

        if ActiveModel::Type::Boolean.new.cast(options[:enable_scope_mapping]) && hash_attributes["postal_code"].present?
          scope = Decidim::Scope.find_by(code: hash_attributes["postal_code"])

          scope = scope_mapping(scope, options) if options[:scope_mapping_level_id].present?

          hash_attributes["scope_id"] = scope&.id
        end

        hash_attributes
      end

      private

      def handle_response(raw_response, opts, settings)
        super(raw_response, opts, settings) do
          if @response_object.success?
            person_id = find_attribute_by(options.attribute_statements["rrn"])
            get_person_options = options.merge(settings: settings)

            begin
              @person_services_response = OmniAuth::SAML::Services::GetPerson.new(person_id: person_id, opts: get_person_options).call
              if @person_services_response.present? && @person_services_response.dig(:"v3:get_person_response", :"v1:error").present?
                Rails.logger.error @person_services_response
                if options[:person_services_fallback_rrn].present?
                  @person_services_response = OmniAuth::SAML::Services::GetPerson.new(person_id: options[:person_services_fallback_rrn], opts: get_person_options).call
                end
              end
            rescue Savon::SOAPFault => e
              Rails.logger.error e.to_hash
              if options[:person_services_fallback_rrn].present?
                @person_services_response = OmniAuth::SAML::Services::GetPerson.new(person_id: options[:person_services_fallback_rrn], opts: get_person_options).call
              end
            rescue Savon::HTTPError => e
              Rails.logger.error e.to_hash
              session["person_services_error"] = "HTTPError (#{e.http.code}) : #{e.message}"
            rescue Savon::InvalidResponseError => e
              Rails.logger.error e.to_hash
              session["person_services_error"] = "InvalidResponseError : #{e.message}"
            rescue StandardError => e
              Rails.logger.error e.message
              session["person_services_error"] = "#{e.class} : #{e.message}"
            end
          end

          @response_object = nil
          yield
        end
      end

      def scope_mapping(scope, options)
        scope.part_of_scopes.find { |s| s.scope_type_id.to_s == options[:scope_mapping_level_id] }
      end
    end
  end
end

OmniAuth.config.add_camelization "csam", "CSAM"
