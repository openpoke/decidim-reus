# frozen_string_literal: true

Decidim::Verifications.register_workflow(:census_authorization_handler) do |auth|
  auth.form = "CensusAuthorizationHandler"
end

TELEPHONE_NUMBER_REGEXP = /^\d{9,}$/
NORMALIZE_TELEPHONE_REGEXP = /\.|\ |-|_/
