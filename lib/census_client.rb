# frozen_string_literal: true

require "savon"
require "census_response"

class CensusClient
  class InvalidBirthDate < StandardError; end

  class InvalidDocumentNumber < StandardError; end

  def self.make_request(original_document_number, original_formatted_birthdate)
    document_number = original_document_number.dup.to_s
    formatted_birthdate = original_formatted_birthdate.dup.to_s

    message = build_message(document_number, formatted_birthdate)

    Rails.logger.info "[Census WS] Sending request with message: #{obfuscated_message(message)}"

    if (Rails.ENV["STAGING"].present? || Rails.env.development?) && original_document_number.include?("#")
      # Try 12345678#315
      response_code = original_document_number.split("#").last
    else
      response = client.call(:padro_decidim, message: message)
      response_code = response.body[:padro_decidim_response][:acces]
    end

    Rails.logger.info "[Census WS] Response code was: #{response_code}"

    CensusResponse.new(code: response_code)
  rescue InvalidBirthDate
    CensusResponse.new(code: nil, success: false, message: "Data naiximent invàlida")
  rescue InvalidDocumentNumber
    CensusResponse.new(code: nil, success: false, message: "Número de document invàlid")
  end

  def self.client
    Savon.client(wsdl: census_endpoint, ssl_verify_mode: :none)
  end
  private_class_method :client

  def self.build_message(document_number, formatted_birthdate)
    # if document matches DNI pattern or NIE, remove last letter
    document_number.chop! if (/^\d{8}[a-zA-Z]$/.match(document_number)) || (/^[a-zA-Z]\d{7}[a-zA-Z]$/.match(document_number))

    validate_parameters!(document_number, formatted_birthdate)

    {
      dni: document_number,
      datan: formatted_birthdate
    }
  end
  private_class_method :build_message

  def self.census_endpoint
    ENV.fetch("CENSUS_ENDPOINT", nil)
  end
  private_class_method :census_endpoint

  def self.validate_parameters!(_document_number, formatted_birthdate)
    if %r{\A\d{2}/\d{2}/\d{4}\z}.match(formatted_birthdate).nil?
      Rails.logger.info "[Census WS] Invalid birthdate: #{formatted_birthdate}"
      raise InvalidBirthDate
    end
  end
  private_class_method :validate_parameters!

  def self.obfuscated_message(message)
    message.merge(
      dni: obfuscated_document_number(message[:dni]),
      datan: obfuscated_formatted_birthdate(message[:datan])
    )
  end

  def self.obfuscated_document_number(document_number)
    return "<invalid length>" if document_number.length < 6

    obfuscated_document_number = document_number.dup
    obfuscated_document_number[2..5] = "****"
    obfuscated_document_number
  end

  def self.obfuscated_formatted_birthdate(formatted_birthdate)
    return "<invalid length>" if formatted_birthdate.length < 2

    obfuscated_formatted_birthdate = formatted_birthdate.dup
    obfuscated_formatted_birthdate[0..1] = "**"
    obfuscated_formatted_birthdate
  end
end
