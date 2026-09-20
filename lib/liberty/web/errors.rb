# frozen_string_literal: true

module Liberty
  module Web
    # The base for every error Liberty Web raises. A Liberty::Error too, so an
    # application can rescue the framework as a whole.
    Error = Class.new(Liberty::Error)

    # Raised by Liberty::Web.app for a Config with errors.
    ConfigurationError = Class.new(Error)
  end
end
