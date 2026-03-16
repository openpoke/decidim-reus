# frozen_string_literal: true

require "spec_helper"

describe "Authorizations", with_authorization_workflows: ["dummy_authorization_handler"] do
  before do
    switch_to_host(organization.host)
  end

  let(:document_number) { "123456789X" }

  context "when existing user from her account" do
    let(:organization) { create(:organization, available_authorizations: authorizations) }
    let(:user) { create(:user, :confirmed, organization: organization) }

    before do
      login_as user, scope: :user
      visit decidim.root_path
    end

    context "when another user is already authorized with the same data" do
      let(:authorizations) { ["dummy_authorization_handler"] }
      let(:first_user) { create(:user, :confirmed, organization: organization) }
      let!(:first_authorization) { create(:authorization, user: first_user, unique_id: document_number, name: "dummy_authorization_handler") }

      before do
        login_as user, scope: :user
        visit decidim.root_path
      end

      it "displays a verbose error message" do
        within_user_menu do
          click_link "My account"
        end

        click_link "Authorizations"
        click_link "Example authorization"

        fill_in "Document number", with: document_number
        page.execute_script("$('#authorization_handler_birthday').focus()")
        page.find(".datepicker-dropdown .day", text: "12").click
        click_button "Send"

        expect(page).to have_content("There was a problem creating the authorization.")
        expect(page).to have_content("Try to login with that account")
      end
    end

    context "when a managed user is already authorized with the same data" do
      let(:authorizations) { ["dummy_authorization_handler"] }
      let(:first_user) { create(:user, :confirmed, organization: organization, managed: true) }
      let!(:first_authorization) { create(:authorization, user: first_user, unique_id: document_number, name: "dummy_authorization_handler") }

      before do
        login_as user, scope: :user
        visit decidim.root_path
      end

      it "displays a verbose error message" do
        within_user_menu do
          click_link "My account"
        end

        click_link "Authorizations"
        click_link "Example authorization"

        fill_in "Document number", with: document_number
        page.execute_script("$('#authorization_handler_birthday').focus()")
        page.find(".datepicker-dropdown .day", text: "12").click
        click_button "Send"

        expect(page).to have_content("There was a problem creating the authorization.")
        expect(page).to have_content("It is associated with a managed accoun")
      end
    end
  end
end
