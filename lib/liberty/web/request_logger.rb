# frozen_string_literal: true

require "logger"

module Liberty
  module Web
    # Gives every request a logger on rack.logger. rack-protection logs through
    # it, and without one builds a DEBUG logger per request that chatters about
    # every host check. The default is INFO on the request's own error stream,
    # which is what lets a spec hand in a StringIO and read what was logged.
    # An injected logger is handed to every request instead.
    class RequestLogger
      attr_reader :app, :logger

      def initialize(app, logger = nil)
        @app = app
        @logger = logger
      end

      def call(env)
        env["rack.logger"] = logger || Logger.new(env["rack.errors"], level: Logger::INFO)
        app.call(env)
      end
    end
  end
end
