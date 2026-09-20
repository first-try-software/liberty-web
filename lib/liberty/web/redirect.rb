# frozen_string_literal: true

module Liberty
  module Web
    # Endpoint classes that only redirect, for an authenticator's challenge:
    #
    #   def challenge_endpoint_class = Liberty::Web::Redirect.to("/login")
    #
    # One class per path and status, so Liberty sees the same class each time.
    module Redirect
      class << self
        def to(path, status: 303)
          classes[[path, status]] ||= build(path, status)
        end

        private

        def classes
          @classes ||= {}
        end

        def build(path, status)
          Class.new(Endpoint) do
            define_method(:status) { status }
            define_method(:headers) { location(path) }
          end
        end
      end
    end
  end
end
