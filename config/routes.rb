# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.ENV["STAGING"].present?

  mount Decidim::Core::Engine => "/"

  authenticate :user, ->(user) { user.admin } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end
end
