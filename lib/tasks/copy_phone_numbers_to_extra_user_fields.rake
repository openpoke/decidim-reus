# frozen_string_literal: true

namespace :extra_user_fields do
  desc "Copy telephone number custom user attribute to extra user fields in extended_data"
  task copy_phone_numbers_to_extra_user_fields: [:environment] do
    Decidim::User.find_each do |user|
      next if (phone_number = user.telephone_number_custom).blank?

      extended_data = user.extended_data.presence || {}
      extended_data.merge!("phone_number" => phone_number.to_s)

      user.update(extended_data:)
    end
  end
end
