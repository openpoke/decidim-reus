# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

def fill_registration_form(
  name: "Nikola Tesla",
  email: "nikola.tesla@example.org",
  password: "sekritpass123"
)
  fill_in :registration_user_name, with: name
  fill_in :registration_user_email, with: email
  fill_in :registration_user_password, with: password
end

describe "Registration" do
  let(:organization) { create(:organization, available_locales: [:ca], default_locale: :ca) }
  let!(:terms_of_service_page) { Decidim::StaticPage.find_by(slug: "terms-of-service", organization:) }

  before do
    switch_to_host(organization.host)
    visit decidim.new_user_registration_path
  end

  context "when signing up" do
    describe "on first sight" do
      it "shows fields empty" do
        expect(page).to have_content("Crea un compte per participar en la plataforma.")
        expect(page).to have_field("registration_user_name", with: "")
        expect(page).to have_field("registration_user_email", with: "")
        expect(page).to have_field("registration_user_password", with: "")
        expect(page).to have_field("registration_user_newsletter", checked: false)
      end
    end
  end

  context "when newsletter checkbox is unchecked" do
    it "opens modal on submit" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :visible)
      expect(page).to have_current_path decidim.new_user_registration_path
    end

    it "checks when clicking the checking button" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_button "Marca i continua"
      expect(page).to have_current_path decidim.new_user_registration_path
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :all)
      expect(page).to have_field("registration_user_newsletter", checked: true)
    end

    it "submit after modal has been opened and selected an option" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_button "Deixa desmarcada"
      expect(page).to have_css("#sign-up-newsletter-modal", visible: :all)
      fill_registration_form
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_current_path decidim.user_registration_path
      expect(page).to have_field("registration_user_newsletter", checked: false)
    end
  end

  context "when newsletter checkbox is checked but submit fails" do
    before do
      fill_registration_form
      page.check("registration_user_newsletter")
    end

    it "keeps the user newsletter checkbox true value" do
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_current_path decidim.user_registration_path
      expect(page).to have_field("registration_user_newsletter", checked: true)
    end
  end

  context "when the user is promoted to an admin after the registration" do
    let(:user) { Decidim::User.last }

    before do
      # Add a content block to the home page to see if the user is there
      create(:content_block, organization:, scope_name: :homepage, manifest_name: :hero)

      # Register
      fill_registration_form(password:)
      page.check("registration_user_tos_agreement")
      page.check("registration_user_newsletter")
      within "form.new_user" do
        find("*[type=submit]").click
      end
      expect(page).to have_content("S'ha enviat un missatge amb un enllaç de confirmació a la teva adreça de correu electrònic.")
      user.admin = true
      user.confirmed_at = Time.current
      user.save!

      # Sign in
      click_link "Entra", match: :first
      fill_in :session_user_email, with: user.email
      fill_in :session_user_password, with: password
      click_button "Entra"
    end

    context "with a weak password" do
      let(:password) { "sekritpass123" }

      it "requires a password change" do
        expect(page).to have_content("Canvia la meva contrasenya")
      end
    end

    context "with a strong password" do
      let(:password) { "decidim123456789" }

      it "does not require password change straight away" do
        expect(page).to have_no_content("Canvia la meva contrasenya")
      end
    end
  end
end
