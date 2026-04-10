# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DecidimApplication
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.i18n.available_locales = %w(ca es en)
    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false
    config.i18n.fallbacks = { ca: [:en], es: [:en] }

    config.to_prepare do
      Decidim::Devise::OmniauthRegistrationsController.prepend(Decidim::ExtraUserFields::IncludeExtraData)
    end
  end
end

Decidim.configure do |config|
  # Max requests in a time period to prevent DoS attacks. Only applied on production.
  config.throttling_max_requests = 1000

  # Time window in which the throttling is applied.
  # config.throttling_period = 1.minute
end
