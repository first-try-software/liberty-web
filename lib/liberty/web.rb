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
  # origin checks, security headers, and a redirect challenge. Liberty itself
  # stays free of all of it, so an API never carries cookies it did not ask
  # for. Templates are the application's; the gem has no opinion about them.
  #
  # The application builds a Config with its values and hands it here:
  #
  #   run Liberty::Web.app(config)
  module Web
    # Liberty's Rack application wrapped in the browser middleware, in the
    # order a browser needs. Refuses a config with errors, naming them all.
    def self.app(config)
      raise ConfigurationError, "Liberty::Web.app cannot build: #{config.errors.join(". ")}." unless config.valid?

      Stack.new(config).to_app
    end
  end
end
