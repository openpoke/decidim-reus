# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

DECIDIM_VERSION = { github: "decidim/decidim", branch: "release/0.31-stable" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-pokecode", github: "openpoke/decidim-module-pokecode", branch: "main"
gem "decidim-removable_authorizations", path: "."
gem "decidim-templates", DECIDIM_VERSION
# gem "decidim-processes_admin_stats", github: "PopulateTools/decidim-module-processes_admin_stats", branch: "main"
gem "acts_as_textcaptcha", "~> 4.6.0"
gem "decidim-decidim_awesome", github: "decidim-ice/decidim-module-decidim_awesome", branch: "main"
gem "decidim-extra_user_fields", github: "openpoke/decidim-module-extra_user_fields", branch: "main"
gem "decidim-term_customizer", github: "openpoke/decidim-module-term_customizer", branch: "main"
gem "decidim-trusted_ids", github: "ConsorciAOC-PRJ/decidim-module-trusted-ids", branch: "upgrade-0.31"

gem "bootsnap", "~> 1.7"
gem "progressbar"
gem "puma", ">= 6.3"

group :development, :test do
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0"
  gem "byebug", platform: :mri
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-nvm", require: false
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "capistrano-rbenv"
  gem "capistrano-sidekiq"
  gem "decidim-dev", DECIDIM_VERSION
  gem "ed25519", ">= 1.2", "< 2.0"
  gem "faker", "~> 3.3.1"
end

group :development do
  gem "letter_opener_web"
  gem "listen"
  gem "web-console"
end
