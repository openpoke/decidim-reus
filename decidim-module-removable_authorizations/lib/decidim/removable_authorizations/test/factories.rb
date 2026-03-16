# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :removable_authorizations_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :removable_authorizations).i18n_name }
    manifest_name { :removable_authorizations }
    participatory_space { create(:participatory_process, :with_steps) }
  end

  # Add engine factories here
end
