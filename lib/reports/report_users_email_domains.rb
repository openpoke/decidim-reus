# frozen_string_literal: true

# This script runs a report on users table and prints the top 20 domains
# of user email addresses.

report = {}

Decidim::User.find_each do |user|
  email = user.email
  domain = email.split("@").last
  report[domain] ||= 0
  report[domain] += 1
end

Rails.logger.debug { "- Total users: #{Decidim::User.count}" }
report.sort { |b, a| a.last <=> b.last }[0...20].each do |domain, count|
  Rails.logger.debug "- #{domain}: #{count}"
end
