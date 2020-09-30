# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/FilePath
describe OmniAuth::SAML::Services::GetPerson do
  subject { described_class.new(person_id: person_id, opts: opts).call }

  describe ".call" do
    let(:person_id) { "123455" }

    context "when wsdl config is incomplete" do
      let(:opts) do
        {
          person_services_wsdl: mock_wsdl("CPS_GetPersonService_1_without_operations.wsdl"),
          person_services_cert: certificate,
          person_services_ca_cert: "",
          person_services_key: private_key,
          person_services_secret: "123456",
          person_services_proxy: "http://proxy.example.com:32124",
          person_services_fallback_rrn: ""
        }
      end

      it { is_expected.to be_nil }

      it "skips HTTP call" do
        expect(Net::HTTP).not_to receive(:post)
      end
    end

    context "when request is success" do
      let(:opts) do
        {
          person_services_wsdl: mock_wsdl("CPS_GetPersonService_1.wsdl"),
          person_services_cert: certificate,
          person_services_ca_cert: "",
          person_services_key: private_key,
          person_services_secret: "123456",
          person_services_proxy: "http://proxy.example.com:32124",
          person_services_fallback_rrn: ""
        }
      end

      before do
        stub_request(:post, %r{PersonServices\/GetPersonService\/3.0\/CPS_GetPersonService})
          .to_return(body: mock_response, status: 200)
      end

      it "returns valid response" do
        expect(subject).to be_a(Hash)
        expect(subject.keys).to match_array([:"v3:get_person_response", :"@xmlns:wsu", :"@wsu:id"])
      end
    end
  end

  def mock_wsdl(file)
    File.read(File.expand_path("../../../../mocks/#{file}", __dir__))
  end

  def mock_response
    File.read(File.expand_path("../../../../mocks/response.xml", __dir__))
  end

  def certificate
    File.read(File.expand_path("../../../../mocks/localhost.crt", __dir__))
  end

  def private_key
    File.read(File.expand_path("../../../../mocks/localhost.key", __dir__))
  end
end
# rubocop:enable RSpec/FilePath
