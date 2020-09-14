# Decidim::Verifications::Omniauth

## About

Adds a new custom authorization options for the verifications workflow.
This module introduce `Saml` authorization strategy for [CSAM](https://www.csam.be/en/index.html).

Core utils were extracted from the [OpenSourcePolitics/decidim](https://github.com/OpenSourcePolitics/decidim/tree/alt/petition_merge)
as an extension, to provide functionality without forking the decidim.

## How to install

Add this line to your application's Gemfile:

```ruby
gem 'decidim-verifications_omniauth', git: 'git@github.com:belighted/decidim-module-verifications_omniauth.git'
```

And then execute:

```bash
bundle install
```

Add setup for new verifications workflow in the initializer e.g `{APP}/config/initializers/decidim.rb`

```ruby
require 'decidim/verifications/omniauth/bosa_action_authorizer'

Decidim::Verifications.register_workflow(:saml) do |workflow|
  workflow.engine = Decidim::Verifications::Omniauth::Engine
  workflow.admin_engine = Decidim::Verifications::Omniauth::AdminEngine
  workflow.action_authorizer = "Decidim::Verifications::Omniauth::BosaActionAuthorizer"
  # workflow.form = "Decidim::Verifications::Omniauth::OmniauthAuthorizationForm"
  workflow.omniauth_provider = :saml
  workflow.minimum_age = 16
end

# Add secondary workflow based on the same engine, but you you need to change the omniauth_provider
Decidim::Verifications.register_workflow(:csam) do |workflow|
  workflow.engine = Decidim::Verifications::Omniauth::Engine
  workflow.admin_engine = Decidim::Verifications::Omniauth::AdminEngine
  workflow.action_authorizer = "Decidim::Verifications::Omniauth::BosaActionAuthorizer"
  # workflow.form = "Decidim::Verifications::Omniauth::OmniauthAuthorizationForm"
  workflow.omniauth_provider = :csam
  workflow.minimum_age = 16
end
```

Add a translations keys for new omniauth_providers for all supported locales in the `{APP}/config/locales`.
Example for `{APP}/config/locales/en.yml`:

```yaml
en:
  decidim:
    authorization_handlers:
      csam:
        name: CSAM
        explanation: Validate with your CSAM account
      saml:
        name: CSAM eID
        explanation: Validate with your CSAM eID account
      admin:
        csam:
          help:
            - Validate with a CSAM account
        saml:
          help:
            - Validate with a CSAM eID account
```

In the application's `config/secrets.yml` add following options in the omniauth section:

```yaml
 omniauth:
   saml:
     enabled: true
   csam:
     enabled: true
```

## Usage

As a system admin you can enable a new authorization strategies for organization in the following steps:

* sign in to the `/system`

* Go to organization `Edit` view

* Scroll down to the `Omniauth settings` section and enable strategy

* Set configuration option for the enabled strategy


For each organization you have to set valid configuration options:

* Saml

![Saml setup](doc/assets/saml.png)

* CSAM

![CSAM setup](doc/assets/csam.png)

## Testing

Create a dummy app in the `spec` dir (if not present):

```bash
bin/rails decidim:generate_external_test_app
RAILS_ENV=test bundle exec rails db:migrate
```

And run tests:

```bash
bundle exec rspec spec
```

## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

This engine is distributed under the [GNU AFFERO GENERAL PUBLIC LICENSEa](LICENSE-AGPLv3.txt).
