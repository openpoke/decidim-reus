# frozen_string_literal: true

module Decidim
  module RemovableAuthorizations
    module AuthorizationHandlerOverrides
      # Creates an admin log entry for a successful authorization
      # Can be overriden to avoid logging
      def log_successful_authorization
        log_authorization("create_authorization_success", log_success_entry_extras)
      end

      # Creates an admin log entry for a failed authorization
      # Can be overriden to avoid logging
      def log_failed_authorization
        log_authorization("create_authorization_error", log_error_entry_extras)
      end

      def uniqueness
        return true if unique_id.nil? || duplicate.blank?

        errors.add(
          :base,
          duplicated_authorization_error_message(duplicate.user).html_safe
        )

        false
      end

      def duplicated_authorization_error_message(other_user)
        if other_user.managed?
          I18n.t(
            "decidim.authorization_handlers.errors.duplicate.managed_user_html",
            name: Decidim::RemovableAuthorizations::AttributeObfuscator.name_hint(other_user.name)
          )
        else
          I18n.t(
            "decidim.authorization_handlers.errors.duplicate.regular_user_html",
            email: Decidim::RemovableAuthorizations::AttributeObfuscator.email_hint(other_user.email),
            logout_link: decidim.destroy_user_session_path
          )
        end
      end

      def decidim
        Decidim::Core::Engine.routes.url_helpers
      end

      # Handler attributes that will be displayed in the log.
      # Can be overriden to customize the attributes, the level of obfuscation,
      # or the information logged for success/error.
      def log_entry_extras
        extras = { handler_name: handler_name }

        attributes.except(:user, :handler_name).each do |k, v|
          extras[k] = Decidim::RemovableAuthorizations::AttributeObfuscator.secret_attribute_hint(v)
        end

        extras
      end
      alias log_success_entry_extras log_entry_extras
      alias log_error_entry_extras log_entry_extras

      def log_authorization(action_name, log_entry_extras)
        Decidim::ActionLogger.log(action_name, user, user, 0, log_entry_extras)
      end
    end
  end
end
