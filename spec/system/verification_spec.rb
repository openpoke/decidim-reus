# frozen_string_literal: true

require "spec_helper"
require "rails_helper"
require "census_client"
require "census_response"

def stub_census_client_for_success
  allow(CensusClient).to(
    receive(:make_request).and_return(CensusResponse.new(code: "0"))
  )
end

describe "Verification" do
  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"], extra_user_fields:) }
  let(:extra_user_fields) do
    {
      "enabled" => true,
      "phone_number" => { "enabled" => true, "pattern" => phone_number_pattern, "placeholder" => nil }
    }
  end
  let(:phone_number_pattern) { "^(\\+34)?[0-9 ]{9,12}$" }
  let(:user) { create(:user, :confirmed, password: password, password_confirmation: password, organization: organization) }
  let(:password) { "dqCFgjfDbC7dPbrv" }
  let(:telephone_number) { "999 456 789" }
  let(:document_number) { "12345678" }
  let(:date_of_birth) { Date.new(1979, 1, 12) }

  def fill_in_authorization_form(options = {})
    fill_in "authorization_handler[document_number]", with: document_number
    fill_in :authorization_handler_date_of_birth, with: date_of_birth

    fill_in "authorization_handler[telephone_number_custom]", with: "999 456 789" if options[:with_custom_fields]
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim.account_path
    click_link "Autoritzacions"
  end

  context "when user is registered in census" do
    before { stub_census_client_for_success }

    describe "when telephone number is missing" do
      it "sets them and creates the authorization" do
        click_link "Padró municipal"

        fill_in_authorization_form(with_custom_fields: true)

        click_button "Enviar"

        expect(page).to have_content("Se t'ha autoritzat correctament")

        user.reload

        expect(user.extended_data["phone_number"]).to eq(telephone_number)
        expect(Decidim::Authorization).to exist(decidim_user_id: user.id)
      end
    end

    describe "when any field is invalid" do
      it "rejects the authorization and does not update custom fields" do
        click_link "Padró municipal"

        fill_in_authorization_form
        fill_in "authorization_handler[telephone_number_custom]", with: "123a"

        click_button "Enviar"

        expect(page).to have_content("S'ha produït un error en crear l'autorització")

        user.reload

        expect(user.extended_data["phone_number"]).to be_blank
        expect(Decidim::Authorization).not_to exist(decidim_user_id: user.id)
      end
    end

    describe "when telephone number is already set" do
      before do
        user.update(extended_data: { "phone_number" => telephone_number })
      end

      it "creates the authorization" do
        click_link "Padró municipal"

        refute has_field? "authorization_handler[telephone_number_custom]"

        fill_in_authorization_form

        click_button "Enviar"

        expect(page).to have_content("Se t'ha autoritzat correctament")

        user.reload

        expect(user.extended_data["phone_number"]).to eq(telephone_number)
        expect(Decidim::Authorization).to exist(decidim_user_id: user.id)
      end
    end
  end

  context "when user is not registered in census" do
    before { allow(CensusClient).to(receive(:make_request).and_return(CensusResponse.new(code: "5"))) }

    it "rejects the authorization and does not update custom fields" do
      click_link "Padró municipal"

      fill_in_authorization_form(with_custom_fields: true)

      click_button "Enviar"

      expect(page).to have_content("S'ha produït un error en crear l'autorització")

      user.reload

      expect(user.extended_data["phone_number"]).to be_nil
      expect(Decidim::Authorization).not_to exist(decidim_user_id: user.id)
    end
  end

  context "when there is another user authorized with the same data" do
    let(:first_user) { create(:user, :confirmed, organization: organization, email: "harry@potter.com") }
    let(:date_of_birth) { Date.new(1979, 1, 12) }
    let(:unique_id) { CensusAuthorizationHandler.build_unique_id(document_number, date_of_birth) }
    let!(:first_authorization) { create(:authorization, user: first_user, unique_id: unique_id, name: "census_authorization_handler") }

    before { stub_census_client_for_success }

    it "rejects the authorization and does not update custom fields" do
      click_link "Padró municipal"

      fill_in_authorization_form(with_custom_fields: true)

      click_button "Enviar"

      expect(page).to have_content("Ja s'ha verificat un usuari amb aquest document d'identificació. Està associada al compte amb correu-e h***y@potter.com")
      expect(page).to have_content("Tracta d'entrar com a usuari amb aquest compte.")
      expect(page).to have_content("Si encara tens problemes posa't en contacte amb un administrador via email (info.participacio@reus.cat) o telefònica (977.010.029)")

      expect(Decidim::Authorization).not_to exist(decidim_user_id: user.id)
    end
  end

  context "when there is a managed user authorized with the same data" do
    let(:first_user) { create(:user, :confirmed, organization: organization, managed: true, name: "Harry Potter") }
    let(:date_of_birth) { Date.new(1979, 1, 12) }
    let(:unique_id) { CensusAuthorizationHandler.build_unique_id(document_number, date_of_birth) }
    let!(:first_authorization) { create(:authorization, user: first_user, unique_id: unique_id, name: "census_authorization_handler") }

    before { stub_census_client_for_success }

    it "rejects the authorization and does not update custom fields" do
      click_link "Padró municipal"

      fill_in_authorization_form(with_custom_fields: true)

      click_button "Enviar"

      expect(page).to have_content("Ja s'ha verificat un usuari amb aquest document d'identificació. Està associada a un compte administrat amb nom Har******ter")
      expect(page).to have_content("Posa't en contacte amb un administrador via email (info.participacio@reus.cat) o telefònica (977.010.029) per promocionar el compte original i poder participar")

      expect(Decidim::Authorization).not_to exist(decidim_user_id: user.id)
    end
  end
end
