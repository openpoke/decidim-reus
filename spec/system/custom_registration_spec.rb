# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

def fill_registration_form
  fill_in :registration_user_name, with: "Nikola Tesla"
  fill_in :registration_user_nickname, with: "the-greatest-genius-in-history"
  fill_in :registration_user_email, with: "nikola.tesla@example.org"
  fill_in :registration_user_password, with: "sekritpass123"
  fill_in :registration_user_password_confirmation, with: "sekritpass123"
end

describe "Registration" do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
    visit decidim.root_path
    visit decidim.new_user_registration_path
  end

  context "when signing up" do
    describe "on first sight" do
      it "shows fields empty" do
        expect(page).to have_content("Crea un compte per poder participar")
        expect(page).to have_field("registration_user_name", with: "")
        expect(page).to have_field("registration_user_email", with: "")
        expect(page).to have_field("registration_user_password", with: "")
        expect(page).to have_field("registration_user_newsletter", checked: false)
      end
    end
  end
end
