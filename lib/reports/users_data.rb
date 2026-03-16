# frozen_string_literal: true

CSV.open("decidim_users.csv", "wb") do |csv|
  csv << %w(nombre email verificado teléfono)
  Decidim::User.all.each do |user|
    presented_user = Decidim::UserPresenter.new(user)
    name = presented_user.name.presence
    email = presented_user.email
    telephone = userr.extended_data.try(:dig, "phone_number")
    verified = Decidim::Authorization.find_by(user: user, name: "census_authorization_handler")&.granted? ? "true" : "false"
    csv << [name, email, verified, telephone]
  end
end
