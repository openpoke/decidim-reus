# frozen_string_literal: true

module Decidim
  module RemovableAuthorizations
    module AdminLog
      module UserPresenterOverrides
        def action_string
          case action
          when "grant_id_documents_offline_verification", "invite", "officialize", "remove_from_admin", "unofficialize", "create_authorization_success", "create_authorization_error" # rubocop:disable Layout/LineLength
            "decidim.admin_log.user.#{action}"
          else
            super
          end
        end

        def changeset
          case action
          when "create_authorization_success", "create_authorization_error"
            original_changeset, fields_mapping = authorization_changeset
          else
            original_changeset = { badge: [previous_user_badge, user_badge] }
            fields_mapping = { badge: :i18n }
          end

          Decidim::Log::DiffChangesetCalculator.new(
            original_changeset,
            fields_mapping,
            i18n_labels_scope
          ).changeset
        end

        def i18n_labels_scope
          case action
          when "create_authorization_success", "create_authorization_error"
            "decidim.verifications.authorizations.error_log"
          else
            super
          end
        end

        def has_diff?
          %w(officialize unofficialize create_authorization_success create_authorization_error).include?(action)
        end

        def authorization_changeset
          changeset_list = action_log.extra.symbolize_keys
                                     .except(:component, :participatory_space, :resource, :user) # Don't display extra_data added by ActionLogger
                                     .map { |k, v| [k, [nil, v]] }
          original_changeset = changeset_list.to_h

          fields_mapping = original_changeset.transform_values do |v|
            authorization_changeset_attribute_type(v.second)
          end

          [original_changeset, fields_mapping]
        end

        def show_previous_value_in_diff?
          super && %w(create_authorization_success create_authorization_error).exclude?(action)
        end

        def authorization_changeset_attribute_type(value)
          [true, false].include?(value) ? :boolean : :string
        end
      end
    end
  end
end
