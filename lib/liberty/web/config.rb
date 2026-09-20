# frozen_string_literal: true

module Liberty
  module Web
    # What the stack needs, as a value the application fills in. Building one
    # never raises, so a task that serves no pages can hold a half-filled one;
    # `errors` says what is missing or wrong, and Liberty::Web.app refuses to
    # build while there are any.
    #
    #   session_secrets   one or more strings of at least 64 bytes; more than one rotates
    #   permitted_hosts   the host names the app answers for; never empty, which would mean anyone
    #   secure_cookies    true behind TLS, which the proxy must say so with X-Forwarded-Proto
    #   renderer          the object endpoints reach as `renderer`; the app chooses its engine
    #   static            a directory whose top-level entries are served as urls, or nil
    #   logger            a ::Logger for rack.logger and the protection middleware, or nil for
    #                     one per request on the request's error stream
    Config = Data.define(:session_secrets, :permitted_hosts, :secure_cookies, :renderer, :static, :logger) do
      def initialize(session_secrets: [], permitted_hosts: [], secure_cookies: nil, renderer: nil, static: nil, logger: nil)
        super(
          session_secrets: Array(session_secrets),
          permitted_hosts: Array(permitted_hosts),
          secure_cookies: secure_cookies,
          renderer: renderer,
          static: static,
          logger: logger
        )
      end

      def errors
        [secrets_error, hosts_error, cookies_error, renderer_error, static_error].compact
      end

      def valid?
        errors.empty?
      end

      private

      def minimum_secret_bytes
        64
      end

      def secrets_error
        return "session_secrets must hold at least one secret" if session_secrets.empty?
        return unless session_secrets.any? { |secret| secret.to_s.bytesize < minimum_secret_bytes }

        "session_secrets must each be at least #{minimum_secret_bytes} bytes"
      end

      def hosts_error
        "permitted_hosts must name at least one host" if permitted_hosts.empty?
      end

      def cookies_error
        "secure_cookies must be true or false" unless [true, false].include?(secure_cookies)
      end

      def renderer_error
        "renderer must be set" if renderer.nil?
      end

      def static_error
        "static must be an existing directory" if static && !File.directory?(static)
      end
    end
  end
end
