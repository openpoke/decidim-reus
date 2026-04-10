# frozen_string_literal: true

require "spec_helper"

module Decidim::Verifications
  describe AuthorizeUser do
    subject { described_class.new(handler) }

    let(:user) { create(:user, :confirmed) }
    let(:document_number) { "12345678X" }
    let(:handler) do
      DummyAuthorizationHandler.new(
        document_number: document_number,
        user: user
      )
    end

    let(:authorizations) { Authorizations.new(organization: user.organization, user: user, granted: true) }

    context "when the form is not authorized" do
      before do
        allow(handler).to receive(:valid?).and_return(false)
      end

      it "logs the authorization attempt" do
        # rubocop:disable RSpec/AnyInstance
        expect_any_instance_of(handler.class).to receive(:log_failed_authorization)
        # rubocop:enable RSpec/AnyInstance

        subject.call
      end
    end

    context "when everything is ok" do
      it "creates an authorization for the user" do
        expect { subject.call }.to change(authorizations, :count).by(1)
      end

      it "logs the authorization" do
        # rubocop:disable RSpec/AnyInstance
        expect_any_instance_of(handler.class).to receive(:log_successful_authorization)
        # rubocop:enable RSpec/AnyInstance

        subject.call
      end
    end
  end
end
