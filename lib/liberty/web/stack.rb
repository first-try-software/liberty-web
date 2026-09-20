# frozen_string_literal: true

require "rack"
require "rack/builder"
require "rack/static"
require "rack/method_override"
require "rack/session"
require "rack/protection"
require_relative "request_logger"
require_relative "content_type_options"

module Liberty
  module Web
    # The middleware around Liberty's application, request first:
    #
    #   Rack::Static                 files answer before anything else runs
    #   RequestLogger                a quiet logger for rack-protection, or the injected one
    #   Rack::MethodOverride         forms can only GET and POST; _method gives a POST another verb
    #   Rack::Session::Cookie        encrypted; `secrets:`, never `secret:`, keeps the legacy HMAC path off
    #   HostAuthorization            before the CSRF check, so a bad host is told so plainly
    #   AuthenticityToken            the token from a form field or X-CSRF-Token; needs the session above
    #   HttpOrigin                   an unsafe request's Origin must be the app's own
    #   FrameOptions                 SAMEORIGIN on HTML
    #   ContentTypeOptions           nosniff on everything; the obsolete x-xss-protection is not sent
    class Stack
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def to_app
        stack = self
        Rack::Builder.new(Liberty.rack_app) do
          use Rack::Static, urls: stack.static_urls, root: stack.config.static if stack.config.static
          use RequestLogger, stack.config.logger
          use Rack::MethodOverride
          use Rack::Session::Cookie, **stack.session_options
          use Rack::Protection::HostAuthorization, permitted_hosts: stack.config.permitted_hosts
          use Rack::Protection::AuthenticityToken
          use Rack::Protection::HttpOrigin
          use Rack::Protection::FrameOptions
          use ContentTypeOptions
        end.to_app
      end

      def static_urls
        Dir.children(config.static).sort.map { |name| "/#{name}" }
      end

      def session_options
        {secrets: config.session_secrets, same_site: :lax, httponly: true, secure: config.secure_cookies}
      end
    end
  end
end
