# frozen_string_literal: true

module Liberty
  module Web
    # What the stack needs, as a value the application fills in. Building one
    # never raises, so a task that serves no pages can hold a half-filled one;
    # `errors` says what is missing or wrong, and Liberty::Web.app refuses to
    # build while there are any.
    #
    #   session_secrets   one or more strings of at least MINIMUM_SECRET_BYTES; more than one rotates
    #   permitted_hosts   the host names the app answers for; never empty, which would mean anyone
    #   secure_cookies    true when the site is served over TLS. The session cookie is then written
    #                     only to a request Rack sees as TLS. Behind a proxy that terminates TLS,
    #                     Rack learns that from X-Forwarded-Proto, so the proxy must send it
    #   static            a directory whose top-level entries are served as urls, or nil for none
    #   logger            a ::Logger that every request gets as rack.logger, which is where
    #                     rack-protection warns; or nil for a Logger per request on that request's
    #                     own rack.errors stream at INFO, which keeps rack-protection's debug
    #                     chatter out of the log and lets a spec read the warnings from a StringIO
    class Config < Data.define(:session_secrets, :permitted_hosts, :secure_cookies, :static, :logger)
      MINIMUM_SECRET_BYTES = 64

      def initialize(session_secrets: [], permitted_hosts: [], secure_cookies: nil, static: nil, logger: nil)
        super(
          session_secrets: Array(session_secrets),
          permitted_hosts: Array(permitted_hosts),
          secure_cookies: secure_cookies,
          static: static,
          logger: logger
        )
      end

      def errors
        [secrets_error, hosts_error, cookies_error, static_error].compact
      end

      def valid?
        errors.empty?
      end

      private

      def secrets_error
        return "session_secrets must hold at least one secret" if session_secrets.empty?
        return unless session_secrets.any? { |secret| secret.to_s.bytesize < MINIMUM_SECRET_BYTES }

        "session_secrets must each be at least #{MINIMUM_SECRET_BYTES} bytes"
      end

      def hosts_error
        "permitted_hosts must name at least one host" if permitted_hosts.empty?
      end

      def cookies_error
        "secure_cookies must be true or false" unless [true, false].include?(secure_cookies)
      end

      def static_error
        "static must be an existing directory" if static && !File.directory?(static)
      end
    end
  end
end
