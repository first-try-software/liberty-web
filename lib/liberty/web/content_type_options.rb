# frozen_string_literal: true

module Liberty
  module Web
    # Tells the browser never to guess a response's type. This is the useful
    # half of rack-protection's XSSHeader; the other half, x-xss-protection,
    # is obsolete and is not sent.
    class ContentTypeOptions
      HEADER = "x-content-type-options"

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = app.call(env)
        headers[HEADER] ||= "nosniff"
        [status, headers, body]
      end
    end
  end
end
