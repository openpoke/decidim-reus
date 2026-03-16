# frozen_string_literal: true

require "csv"

CSV.open("/tmp/verified_users_20230202_after_delete.csv", "wb") do |csv|
  csv << %w(id email name nickname)
  Decidim::Authorization.find_each do |a|
    u = a.user
    csv << [u.id, u.email, u.name, u.nickname]
  end
end
