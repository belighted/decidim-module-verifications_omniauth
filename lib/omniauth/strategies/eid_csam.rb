# frozen_string_literal: true

require "omniauth-saml"
require "savon"
require "akami"
require "onelogin/ruby-saml/utils"

module OmniAuth
  module Strategies
    class EidCsam < OmniAuth::Strategies::EidSaml

      option :name, :csam

    end
  end
end

# OmniAuth.config.add_camelization 'csam', 'CSAM'
