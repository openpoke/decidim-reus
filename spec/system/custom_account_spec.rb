# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

describe "Account" do
  let(:organization) { create(:organization, extra_user_fields:) }
  let(:extra_user_fields) do
    {
      "enabled" => true,
      "phone_number" => { "enabled" => true, "pattern" => phone_number_pattern, "placeholder" => nil }
    }
  end
  let(:phone_number_pattern) { "^(\\+34)?[0-9 ]{9,12}$" }
  let(:user) { create(:user, :confirmed, password:, organization:) }
  let(:password) { "dqCFgjfDbC7dPbrv" }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when on the account page" do
    before do
      puts "Visit: #{decidim.account_path}"
      visit decidim.account_path
    end

    describe "updating personal data" do
      it "updates the user's data" do
        within "form.edit_user" do
          fill_in :user_name, with: "Normal User Name"
          fill_in :user_personal_url, with: "https://example.org"
          fill_in :user_about, with: "User Biography Text"
          fill_in :user_phone_number, with: "123456789"
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("correctament")
        end

        user.reload

        within_user_menu do
          find("a", text: "perfil públic").click
        end

        visit decidim.account_path

        expect(page).to have_css("input[value='Normal User Name']")
        assert page.has_content?("User Biography Text")
        expect(page).to have_css("input[value='123456789']")
      end
    end
  end
end
