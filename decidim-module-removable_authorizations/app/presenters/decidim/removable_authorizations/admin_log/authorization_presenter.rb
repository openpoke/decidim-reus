# frozen_string_literal: true

module Decidim
  module RemovableAuthorizations
    module AdminLog
      # This class holds the logic to present a `Decidim::Authorization`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    AuthorizationPresenter.new(action_log, view_helpers).present
      class AuthorizationPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "delete"
            "decidim.admin_log.authorization.#{action}"
          else
            super
          end
        end

        def i18n_params
          super.merge(
            recipient_name: recipient_presenter&.present
          )
        end

        def recipient_presenter
          @recipient_presenter ||= Decidim::Log::UserPresenter.new(recipient, h, user_data) if recipient_data
        end

        # {"extra"=>{"authorization_owner"=>{"id"=>9999}}
        def recipient_data
          @recipient_data ||= action_log.extra.dig("extra", "authorization_owner")
        end

        # {"user"=>{"ip"=>"192.168.192.161", "name"=>"Admin User", "nickname"=>"admin-user"}
        def user_data
          @user_data ||= action_log.extra["user"]
        end

        def recipient
          Decidim::User.find_by(id: recipient_data["id"]) if recipient_data
        end
      end
    end
  end
end
