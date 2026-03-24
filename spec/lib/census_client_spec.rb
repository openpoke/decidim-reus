# frozen_string_literal: true

require_relative "../rails_helper"
require "census_client"

def stub_census_client(desired_response_body)
  response = double("soap_response")
  allow(response).to receive(:body).and_return(desired_response_body)

  client = double("soap_client")
  allow(client).to receive(:call).and_return(response)

  allow(Savon).to receive(:client).and_return(client)
end

describe CensusClient do
  describe "::make_request" do
    subject { census_reponse }

    let(:dni_number) { "12345678" }
    let(:birthdate) { Date.civil(1994, 12, 30).strftime("%d/%m/%Y") }
    let(:census_reponse) { CensusClient.make_request(dni_number, birthdate) }
    let(:census_response_code) { "0" }

    before { stub_census_client(padro_decidim_response: { acces: census_response_code }) }

    context "when person exists" do
      it "correctly initializes the response" do
        expect(subject.registered_in_census?).to be true
        expect(subject.response_code).to be "0"
        expect(subject.message).to eq("OK. Persona empadronada")
      end
    end

    context "when person does not exist" do
      let(:census_response_code) { "5" }

      it "correctly initializes the response" do
        expect(subject.registered_in_census?).to be false
        expect(subject.response_code).to be "5"
      end
    end

    context "when response code is unknown" do
      let(:census_response_code) { "wadus" }

      it "correctly initializes the response" do
        expect(subject.registered_in_census?).to be false
        expect(subject.response_code).to be "wadus"
      end
    end
  end
end
