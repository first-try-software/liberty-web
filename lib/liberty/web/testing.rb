# frozen_string_literal: true

require "rack/lint"

module Liberty
  module Web
    # For an application's own specs. Not loaded by `require "liberty/web"`;
    # require "liberty/web/testing" where the tests are set up.
    module Testing
      TOKEN_FIELD = /name="authenticity_token" value="([^"]+)"/

      class << self
        # The app with every request and response checked against the Rack spec.
        def lint(app)
          Rack::Lint.new(app)
        end

        # The value of the hidden field a form carries, for posting it back.
        def csrf_token_in(html)
          html[TOKEN_FIELD, 1]
        end
      end
    end
  end
end
