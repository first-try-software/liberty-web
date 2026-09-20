# frozen_string_literal: true

require "rack/protection"

module Liberty
  module Web
    # A Liberty endpoint with what a browser endpoint reaches for. Four private
    # helpers and nothing else: no lifecycle, no response object, and no
    # opinion about how the renderer is called.
    class Endpoint < Liberty::Endpoint
      private

      # The rack session hash. An application wraps it with its own class when
      # it wants a vocabulary for what the cookie carries.
      def session
        request.env["rack.session"]
      end

      # The masked token the CSRF middleware accepts for this session, for a
      # hidden field or a meta tag.
      def csrf_token
        Rack::Protection::AuthenticityToken.token(session)
      end

      # The headers of a redirect. The status stays the endpoint's own answer.
      def location(path)
        {"location" => path}
      end

      # The object the Config was built with, called however that object is called.
      def renderer
        Liberty::Web.renderer
      end
    end
  end
end
