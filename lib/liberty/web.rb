# frozen_string_literal: true

require "liberty"
require_relative "web/version"
require_relative "web/errors"
require_relative "web/config"
require_relative "web/stack"
require_relative "web/endpoint"
require_relative "web/redirect"

module Liberty
  # The browser stack for a Liberty application: sessions, CSRF, host and
  # origin checks, security headers, a redirect challenge, and a seam for the
  # application's renderer. Liberty itself stays free of all of it, so an API
  # never carries cookies or templates it did not ask for.
  #
  # The application builds a Config with its values and hands it here:
  #
  #   run Liberty::Web.app(config)
  module Web
    class << self
      # Liberty's Rack application wrapped in the browser middleware, in the
      # order a browser needs. Refuses a config with errors, naming them all.
      def app(config)
        raise ConfigurationError, "Liberty::Web.app cannot build: #{config.errors.join(". ")}." unless config.valid?

        @config = config
        Stack.new(config).to_app
      end

      # The renderer the stack was built with, which endpoints reach as `renderer`.
      def renderer
        raise ConfigurationError, "Liberty::Web.app has not been built, so there is no renderer" unless @config

        @config.renderer
      end
    end
  end
end
