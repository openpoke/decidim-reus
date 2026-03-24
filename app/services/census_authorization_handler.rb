# frozen_string_literal: true

require "census_client"
require "custom_attribute_obfuscator"

class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include Decidim::HumanizeBooleansHelper

  attribute :document_number, String
  attribute :date_of_birth, Date
  attribute :telephone_number_custom, String

  validates :date_of_birth, presence: true
  validates :document_number, presence: true
  validates :telephone_number_custom, presence: true, if: :phone_number?
  validates(
    :telephone_number_custom,
    format: { with: ->(form) { Regexp.new(form.organization.extra_user_field_configuration(:phone_number)["pattern"]) } },
    if: :phone_number_format?
  )
  validate :user_exists_in_census # must be declared as the last validation so custom
  # fields are not saved unless census call succeeds

  def self.from_params(params, additional_params = {})
    instance = super

    params_hash = hash_from(params)

    if params_hash["date_of_birth(1i)"]
      date = Date.civil(
        params["date_of_birth(1i)"].to_i,
        params["date_of_birth(2i)"].to_i,
        params["date_of_birth(3i)"].to_i
      )

      instance.date_of_birth = date
    end

    instance
  end

  def unique_id
    self.class.build_unique_id(document_number, date_of_birth)
  end

  def organization
    @organization ||= user.organization
  end

  def phone_number?
    extra_user_fields_enabled && organization.activated_extra_field?(:phone_number) && user.extended_data["phone_number"].blank?
  end

  private

  def phone_number_format?
    return false unless phone_number?

    organization.extra_user_field_configuration(:phone_number)["pattern"].present?
  end

  def extra_user_fields_enabled
    @extra_user_fields_enabled ||= organization.extra_user_fields_enabled?
  end

  def user_exists_in_census
    @census_response = CensusClient.make_request(document_number, self.class.format_birthdate(date_of_birth))

    if !@census_response.registered_in_census?
      errors.add(:base, @census_response.message)
    elsif errors.empty?
      user.extended_data = (user&.extended_data || {}).merge(phone_number: telephone_number_custom) if phone_number?
      user.save!
    end
  end

  def log_success_entry_extras
    {
      email: CustomAttributeObfuscator.email(user.email),
      document_number: CustomAttributeObfuscator.document_number(document_number),
      managed_user: user.managed,
      census_code: @census_response.response_code,
      census_message: census_message
    }
  end

  def log_error_entry_extras
    {
      email: CustomAttributeObfuscator.email(user.email, false),
      document_number: CustomAttributeObfuscator.document_number(document_number, false),
      managed_user: user.managed,
      census_code: @census_response.response_code,
      census_message: census_message
    }
  end

  def self.build_unique_id(document_number, birth_date) # rubocop:disable Lint/IneffectiveAccessModifier
    Digest::MD5.hexdigest(
      "#{document_number}-#{format_birthdate(birth_date)}-#{Rails.application.secret_key_base}"
    )
  end

  def self.format_birthdate(date) # rubocop:disable Lint/IneffectiveAccessModifier
    date.strftime("%d/%m/%Y") if date.present?
  end

  def census_message
    if duplicate.blank?
      @census_response.message
    else
      other_user = duplicate.user

      "
      Està empadronat, però hi ha #{other_user.managed ? "un compte administrat" : "un altre usuari"} verificat amb les mateixes dades
      (nom: #{Decidim::RemovableAuthorizations::AttributeObfuscator.name_hint(other_user.name)}, email: #{CustomAttributeObfuscator.email(other_user.email)})
      "
    end
  end
end
