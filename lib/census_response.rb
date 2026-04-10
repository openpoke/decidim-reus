# frozen_string_literal: true

class CensusResponse
  attr_accessor(
    :response_code,
    :registered_in_census,
    :message
  )

  def initialize(params = {})
    self.response_code = params[:code]
  end

  def registered_in_census?
    response_code && response_code == "0"
  end

  def message
    @message || default_message_for(response_code)
  end

  private

  def default_message_for(code)
    case code
    when "0"
      "OK. Persona empadronada"
    else
      code
    end
  end
end
