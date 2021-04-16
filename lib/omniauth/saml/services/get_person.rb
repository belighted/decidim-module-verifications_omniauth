# frozen_string_literal: true

require "savon"
require "akami"
require "onelogin/ruby-saml/utils"

module OmniAuth
  module SAML
    module Services
      class GetPerson
        attr_reader :person_id, :opts

        INCLUSIVE_NAMESPACES = %w(head soapenv v1 v3 v31 xsd xsi).freeze

        def initialize(person_id:, opts:)
          @person_id = person_id
          @opts = (opts || {}).with_indifferent_access
        end

        def call
          make_request if client.operations.include?(:get_person)
        end

        def client
          @client ||= Savon.client(
            wsdl: opts[:person_services_wsdl],
            proxy: opts[:person_services_proxy].blank? ? nil : opts[:person_services_proxy].blank?,

            log: true,
            logger: Logger.new(STDOUT),
            pretty_print_xml: false,

            namespace_identifier: :v31,
            env_namespace: :soapenv,
            namespaces: {
              "xmlns:head" => "http://fsb.belgium.be/header",
              "xmlns:v1" => "http://fsb.belgium.be/data/business/context/v1_00",
              "xmlns:v3" => "http://fsb.belgium.be/getPersonService/v3_00",
              "xmlns:v31" => "http://fsb.belgium.be/getPersonService/messages/v3_00"
            },
            strip_namespaces: false,

            soap_header: {
              "head:fsbHeader" => {
                "head:messageId" => SecureRandom.uuid
              }
            },
            wsse_timestamp: true
          )
        end

        private

        def make_request
          build_request
            .then {|request| sign_request_body(request)}
            .then {|signed_xml| client.call(:get_person, message_tag: :getPersonRequest, xml: signed_xml)}
            .then do |response|
            begin
              if Mongoid.default_client.database_names.present?
                GetPersonRequestHistory.create(person_id: person_id, response: response.body)
              end
            rescue
              nil
            end
            response.body
          end
        end

        def build_request
          client.build_request(:get_person,
                               message_tag: :getPersonRequest,
                               message: {
                                 "v1:userContext": {
                                   "v1:personNumber": person_id,
                                   "v1:language": "en"
                                 },
                                 "v31:personNumber": person_id
                               })
        end

        def sign_request_body(request)
          doc = Nokogiri::XML(request.body)

          # Sign xml using Signer
          signer = Signer.new(doc.to_xml(encoding: "UTF-8", indent: 0))
          signer.cert = OpenSSL::X509::Certificate.new(certificate)
          signer.private_key = OpenSSL::PKey::RSA.new(private_key, opts[:person_services_secret])
          signer.ds_namespace_prefix = "ds"

          signer.document.xpath("//soapenv:Body").each do |node|
            signer.digest!(node, inclusive_namespaces: INCLUSIVE_NAMESPACES)
          end
          signer.document.xpath("//u:Timestamp", "u" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd").each do |node|
            signer.digest!(node, inclusive_namespaces: INCLUSIVE_NAMESPACES)
          end

          signer.sign!(security_token: true, inclusive_namespaces: INCLUSIVE_NAMESPACES)
          signer.to_xml
        end

        def certificate
          OneLogin::RubySaml::Utils.format_cert(opts[:person_services_cert])
        end

        def private_key
          OneLogin::RubySaml::Utils.format_private_key(opts[:person_services_key])
        end
      end
    end
  end
end
