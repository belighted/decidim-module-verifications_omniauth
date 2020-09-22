# frozen_string_literal: true

require "omniauth-saml"
require "savon"
require "akami"
require "onelogin/ruby-saml/utils"

module OmniAuth
  module Strategies
    class EidCsam < OmniAuth::Strategies::EidSaml
      option :name, :csam

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
          official_birth_date_day = @person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:day")
          official_birth_date_month = @person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:month")
          official_birth_date_year = "#{@person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:century")}#{@person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v21:basic_person", :"v21:official_birth_date", :"v22:year")}"

          if official_birth_date_day.present? && official_birth_date_month.present? && official_birth_date_year.present?
            hash_attributes["official_birth_date"] = Date.strptime("#{official_birth_date_day}/#{official_birth_date_month}/#{official_birth_date_year}", '%d/%m/%Y')
          end

          hash_attributes["postal_code"] = @person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v1:address", :"v1:structured_address", :"v1:municipality", :"v11:code")
          hash_attributes["municipality"] = @person_services_response.dig(:"v3:get_person_response", :"v2:basic_natural_person", :"v1:address", :"v1:structured_address", :"v1:municipality", :"v11:description")
        end

        if ActiveModel::Type::Boolean.new.cast(options[:enable_scope_mapping]) && hash_attributes["postal_code"].present?
          scope = Decidim::Scope.find_by_code(hash_attributes["postal_code"])

          if options[:scope_mapping_level_id].present?
            scope = scope.part_of_scopes.find { |s| s.scope_type_id.to_s == options[:scope_mapping_level_id] }
          end

          hash_attributes["scope_id"] = scope.id
        end

        hash_attributes
      end

      def handle_response(raw_response, opts, settings)
        super(raw_response, opts, settings) do
          if @response_object.success?
            begin
              @person_services_response = person_services_request(options.merge(settings: settings), find_attribute_by(options.attribute_statements['rrn']))
              if @person_services_response.present? && @person_services_response.dig(:"v3:get_person_response", :"v1:error").present?
                Rails.logger.error @person_services_response
                # @person_services_response = nil
                @person_services_response = person_services_request(options.merge(settings: settings), options[:person_services_fallback_rrn]) if options[:person_services_fallback_rrn].present?
              end
            rescue Savon::SOAPFault => e
              Rails.logger.error e.to_hash
              @person_services_response = person_services_request(options.merge(settings: settings), options[:person_services_fallback_rrn]) if options[:person_services_fallback_rrn].present?
            rescue Savon::HTTPError => e
              Rails.logger.error e.to_hash
              session["person_services_error"] = "HTTPError (#{e.http.code}) : #{e.message}"
            rescue Savon::InvalidResponseError => e
              Rails.logger.error e.to_hash
              session["person_services_error"] = "InvalidResponseError : #{e.message}"
            rescue Exception => e
              Rails.logger.error e.message
              session["person_services_error"] = "#{e.class} : #{e.message}"
            end
          end

          @response_object = nil
          yield
        end
      end

      def person_services_request(opts, person_id)
        cert_file = opts[:person_services_cert]
        ca_cert_file = opts[:person_services_cert]
        key_file = opts[:person_services_key]
        password = opts[:person_services_secret]

        ps_client = Savon.client(
          wsdl: opts[:person_services_wsdl],
          proxy: opts[:person_services_proxy],

          log: true,
          logger: Logger.new(STDOUT),
          pretty_print_xml: false,

          namespace_identifier: :v31,
          env_namespace: :soapenv,
          namespaces: {
            'xmlns:head' => 'http://fsb.belgium.be/header',
            'xmlns:v1' => 'http://fsb.belgium.be/data/business/context/v1_00',
            'xmlns:v3' => 'http://fsb.belgium.be/getPersonService/v3_00',
            'xmlns:v31' => 'http://fsb.belgium.be/getPersonService/messages/v3_00'
          },
          strip_namespaces: false,

          soap_header: {
            'head:fsbHeader' => {
              'head:messageId' => SecureRandom.uuid
            }
          },
          wsse_timestamp: true
        )

        if ps_client.operations.include?(:get_person)

          # Build a request to produce its xml
          request = ps_client.build_request(:get_person, message_tag: :getPersonRequest, message: {
            "v1:userContext": {
              "v1:personNumber": person_id,
              "v1:language": 'en'
            },
            "v31:personNumber": person_id
          })
          xml = request.body
          doc = Nokogiri::XML(xml)

          # Sign xml using Signer
          signer = Signer.new(doc.to_xml(encoding: 'UTF-8', indent: 0))
          signer.cert = OpenSSL::X509::Certificate.new(OneLogin::RubySaml::Utils.format_cert(cert_file + ca_cert_file))
          signer.private_key = OpenSSL::PKey::RSA.new(OneLogin::RubySaml::Utils.format_private_key(key_file), password)
          signer.ds_namespace_prefix = 'ds'

          signer.document.xpath('//soapenv:Body').each do |node|
            signer.digest!(node, inclusive_namespaces: %w[head soapenv v1 v3 v31 xsd xsi])
          end
          signer.document.xpath('//u:Timestamp', 'u' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd').each do |node|
            signer.digest!(node, inclusive_namespaces: %w[wsse head soapenv v1 v3 v31 xsd xsi])
          end

          signer.sign!(security_token: true, inclusive_namespaces: %w[head soapenv v1 v3 v31 xsd xsi])
          signed_xml = signer.to_xml

          # Making an actual call to API
          response = ps_client.call(:get_person, message_tag: :getPersonRequest, xml: signed_xml)

          # Handle the response
          return response.body
        end
      end
    end
  end
end

OmniAuth.config.add_camelization 'csam', 'CSAM'
