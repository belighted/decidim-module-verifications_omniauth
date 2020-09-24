# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

DECIDIM_VERSION = { git: "https://github.com/decidim/decidim", tag: "v0.22.0.rc1" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-verifications_omniauth", path: "."

gem "bootsnap"
gem "puma"
gem "uglifier", "~> 4.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", DECIDIM_VERSION
  gem "faker", "~> 1.9"
  gem "pry-rails"
  gem "rubocop-performance"
end

group :development do
  gem "letter_opener_web", "~> 1.4"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.7"
end
