# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

describe "Account" do
  let(:organization) { create(:organization, available_locales: [:ca], default_locale: :ca) }
  let(:user) { create(:user, :confirmed, password: password, password_confirmation: password, organization: organization) }
  let(:password) { "dqCFgjfDbC7dPbrv" }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  describe "navigation" do
    it "shows the account form when clicking on the menu" do
      visit decidim.root_path

      within_user_menu do
        find("a", text: "El meu compte").click
      end

      expect(page).to have_css("form.edit_user")
    end
  end

  context "when on the account page" do
    before do
      visit decidim.account_path
    end

    describe "updating personal data" do
      it "updates the user's data" do
        within "form.edit_user" do
          fill_in :user_name, with: "Nikola Tesla"
          fill_in :user_personal_url, with: "https://example.org"
          fill_in :user_about, with: "A Serbian-American inventor, electrical engineer, mechanical engineer, physicist, and futurist."
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("correctament")
        end

        user.reload

        within_user_menu do
          find("a", text: "perfil públic").click
        end

        expect(page).to have_content("example.org")
        expect(page).to have_content("Serbian-American")
      end
    end

    describe "when update password" do
      let!(:encrypted_password) { user.encrypted_password }
      let(:new_password) { "decidim1234567890" }

      before do
        click_button "Canvia la contrasenya"
      end

      it "toggles old and new password fields" do
        within "form.edit_user" do
          expect(page).to have_content("no ha de ser massa comú (per exemple 123456) i ha de ser diferent del teu àlies i la teva adreça de correu electrònic")
          expect(page).to have_field("user[password]", with: "", type: "password")
          expect(page).to have_field("user[old_password]", with: "", type: "password")
          click_button "Canvia la contrasenya"
          expect(page).to have_no_field("user[password]", with: "", type: "password")
          expect(page).to have_no_field("user[old_password]", with: "", type: "password")
        end
      end

      it "shows fields if password is wrong" do
        within "form.edit_user" do
          fill_in "Contrasenya", match: :first, with: new_password
          fill_in "Contrasenya actual", with: "wrong password12345"
          find("*[type=submit]").click
        end
        expect(page).to have_field("user[password]", with: "decidim1234567890", type: "password")
        expect(page).to have_content("no és vàlid")
      end

      it "changes the password with correct password" do
        within "form.edit_user" do
          fill_in "Contrasenya", match: :first, with: new_password
          fill_in "Contrasenya actual", with: password
          find("*[type=submit]").click
        end
        within_flash_messages do
          expect(page).to have_content("correctament")
        end
        expect(user.reload.encrypted_password).not_to eq(encrypted_password)
        expect(page).to have_no_field("user[password]", with: "", type: "password")
        expect(page).to have_no_field("user[old_password]", with: "", type: "password")
      end
    end

    context "when update email" do
      let(:pending_email) { "foo@bar.com" }

      context "when typing new email" do
        before do
          within "form.edit_user" do
            fill_in "El teu correu electrònic", with: pending_email
            find("*[type=submit]").click
          end
        end

        it "toggles the current password" do
          expect(page).to have_content("Per tal de confirmar els canvis al teu compte, si us plau, proporciona'ns la teva contrasenya actual.")
          expect(find_by_id("user_old_password")).to be_visible
          expect(page).to have_content "Contrasenya actual*"
          expect(page).to have_no_content "Contrasenya*"
        end

        it "renders the old password with error" do
          within "form.edit_user" do
            find("*[type=submit]").click
            fill_in :user_old_password, with: "wrong password"
            find("*[type=submit]").click
          end
          within ".flash.alert" do
            expect(page).to have_content "S'ha produït un error en actualitzar el teu compte."
          end
          within ".old-user-password" do
            expect(page).to have_content "no és vàlid"
          end
        end
      end

      context "when correct old password" do
        before do
          within "form.edit_user" do
            fill_in "El teu correu electrònic", with: pending_email
            find("*[type=submit]").click
            fill_in :user_old_password, with: password

            perform_enqueued_jobs { find("*[type=submit]").click }
          end

          within_flash_messages do
            expect(page).to have_content("Rebràs un correu electrònic per confirmar la teva nova adreça de correu electrònic.")
          end
        end

        after do
          clear_enqueued_jobs
        end

        it "tells user to confirm new email" do
          expect(page).to have_content("Verificació del canvi de correu electrònic")
          expect(page).to have_css("#user_email[disabled='disabled']")
          expect(page).to have_content("Hem enviat un correu a #{pending_email} per a verificar la teva nova adreça de correu electrònic")
        end

        it "resend confirmation" do
          within "#email-change-pending" do
            click_link "Tornar a enviar"
          end

          expect(page).to have_content("Correu de confirmació reenviat amb èxit a #{pending_email}")
          perform_enqueued_jobs
          perform_enqueued_jobs

          # the emails also include the update email notification
          expect(emails.count).to eq(3)
          visit last_email_link
          expect(page).to have_content("La teva adreça de correu electrònic s'ha confirmat correctament")
        end

        it "cancels the email change" do
          expect(Decidim::User.find(user.id).unconfirmed_email).to eq(pending_email)
          within "#email-change-pending" do
            click_link "cancel"
          end

          expect(page).to have_content("Canvi de correu electrònic cancel·lat amb èxit")
          expect(page).to have_no_content("Verificació del canvi de correu electrònic")
          expect(Decidim::User.find(user.id).unconfirmed_email).to be_nil
        end
      end
    end

    context "when on the notifications settings page" do
      before do
        visit decidim.notifications_settings_path
      end

      it "updates the user's notifications" do
        page.find("[for='newsletter_notifications']").click

        within "form.edit_user" do
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("correctament")
        end
      end
    end

    context "when on the delete my account page" do
      before do
        visit decidim.delete_account_path
      end

      it "the user can delete his account" do
        fill_in :delete_user_delete_account_delete_reason, with: "I just want to delete my account"

        click_button "Eliminar el meu compte"

        click_button "Sí, vull eliminar el meu compte"

        within_flash_messages do
          expect(page).to have_content("correctament")
        end

        click_link("Entra", match: :first)

        within ".new_user" do
          fill_in :session_user_email, with: user.email
          fill_in :session_user_password, with: password
          find("*[type=submit]").click
        end

        expect(page).to have_no_content("S'ha iniciat la sessió correctament")
        expect(page).to have_no_content(user.name)
      end
    end
  end
end
