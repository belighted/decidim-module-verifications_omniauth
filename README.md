# Decidim::Verifications::Omniauth

## About

Adds a new omniauth options for authorization in the verifications workflow.

## How to install

Add this line to your application's Gemfile:

```ruby
gem 'decidim-verifications_omniauth', git: 'git@github.com:belighted/decidim-module-verifications_omniauth.git'
```

And then execute:

```bash
bundle install
```

Install migrations from the extension.
```bash
bundle exec rails decidim-verifications_omniauth:install:migrations
```

Add a saml workflow for verifications scope in the decidim initializer in the `{APP}/config/initializers/decidim.rb`

```ruby
Decidim::Verifications.register_workflow(:saml) do |workflow|
  workflow.engine = Decidim::Verifications::Omniauth::Engine
  workflow.admin_engine = Decidim::Verifications::Omniauth::AdminEngine
  workflow.action_authorizer = "Decidim::Verifications::Omniauth::BosaActionAuthorizer"
  workflow.form = "Decidim::Verifications::Omniauth::OmniauthAuthorizationForm"
  workflow.omniauth_provider = :saml
  workflow.minimum_age = 16
end
```

Add a translations keys for all supported locales in the `{APP}/config/locales`, eg:

```yaml
en:
  decidim:
    authorization_handlers:
      csam:
        name: CSAM
        explanation: Validate with your CSAM account
      admin:
        csam:
          help:
            - Validate with a CSAM account
```

## Usage


## Testing

Create a dummy app in the `spec` dir (if not present):

```bash
bin/rails decidim:generate_external_test_app
cd spec/decidim_dummy_app/
bundle exec rails decidim-verifications_omniauth:install:migrations
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
