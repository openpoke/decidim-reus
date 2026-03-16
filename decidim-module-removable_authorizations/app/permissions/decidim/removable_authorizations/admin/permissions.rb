# frozen_string_literal: true

module Decidim
  module RemovableAuthorizations
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          allow! if user.admin? && (permission_action.subject == :authorizations)

          permission_action
        end
      end
    end
  end
end
