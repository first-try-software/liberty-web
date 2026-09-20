# Liberty Web

[![Gem Version](https://badge.fury.io/rb/liberty-web.svg)](https://badge.fury.io/rb/liberty-web)
[![Ruby](https://github.com/first-try-software/liberty-web/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/first-try-software/liberty-web/actions/workflows/main.yml)

Liberty Web is the browser stack for a [Liberty](https://github.com/first-try-software/liberty) application: sessions, CSRF, host and origin checks, security headers, a redirect challenge, and a seam for the application's renderer.

Liberty itself answers requests and decides who is asking, and it stays free of cookies and templates so an API never carries them. Liberty Web adds what a browser needs, in one explicit call, and no more. It owns the shape of its configuration and the order of its middleware. The application owns every value, its authenticators, its templates, and its data.

Two things Liberty Web does not do, on purpose. It has nothing to say about templates: an endpoint calls whatever renderer the application owns, and the gem never sees it. And it reads no environment: the application reads its own settings and fills in a `Config`.

## Usage

### The stack

Build a `Liberty::Web::Config` with the application's values and hand it to `Liberty::Web.app`:

```ruby
# config.ru
require_relative "app/boot"

config = Liberty::Web::Config.new(
  session_secrets: [ENV.fetch("SESSION_SECRET")],   # one or more strings of at least 64 bytes; more than one rotates
  permitted_hosts: ENV.fetch("PERMITTED_HOSTS").split(","),
  secure_cookies: ENV["RACK_ENV"] == "production",  # true needs the proxy to forward the scheme; see below
  static: "public"                                  # optional: a directory whose top-level entries become urls
)

run Liberty::Web.app(config)
```

Building a `Config` never raises, so a task that serves no pages can hold a half-filled one. `config.errors` names each problem in a sentence, and `Liberty::Web.app` raises `Liberty::Web::ConfigurationError` carrying all of them rather than build a stack that is wrong.

The call wraps `Liberty.rack_app` in this middleware, request first:

| Middleware | Why it is there |
|---|---|
| `Rack::Static` | Files under `static` answer before anything else runs |
| `Liberty::Web::RequestLogger` | rack-protection logs through `rack.logger`; without one it builds a DEBUG logger per request and chatters. The default is INFO on the request's own error stream; pass `logger:` to use your own |
| `Rack::MethodOverride` | Forms can only GET and POST; a hidden `_method` field gives a POST another verb. Only a POST is rewritten |
| `Rack::Session::Cookie` | Encrypted with `secrets:`, never `secret:`, so the legacy HMAC and Marshal path stays off. `SameSite=Lax`, `HttpOnly`, and `Secure` from `secure_cookies` |
| `Rack::Protection::HostAuthorization` | Before the CSRF check, so a request for the wrong host is told "Host not permitted" rather than a puzzling 403 |
| `Rack::Protection::AuthenticityToken` | The token from a form field or the `X-CSRF-Token` header; it needs the session above it |
| `Rack::Protection::HttpOrigin` | An unsafe request's `Origin` must be the application's own |
| `Rack::Protection::FrameOptions` | `SAMEORIGIN` on HTML |
| `Liberty::Web::ContentTypeOptions` | `nosniff` on every response. The obsolete `x-xss-protection` header is not sent |

To add middleware of your own, wrap the result in your own `Rack::Builder`.

### Endpoints

Inherit from `Liberty::Web::Endpoint` instead of `Liberty::Endpoint`. It adds three private helpers and nothing else:

```ruby
session          # the rack session hash; wrap it in your own class if you want a vocabulary
csrf_token       # the token the CSRF middleware accepts for this session, for a hidden field or a meta tag
location(path)   # {"location" => path}; the status stays your own answer
```

```ruby
class Journal < Liberty::Web::Endpoint
  responds_to :get, "/", authenticated_by: Authenticators::Session

  def html
    MyApp.renderer.render("journal", layout: :application, csrf_token: csrf_token, notes: notes)
  end
end

class Logout < Liberty::Web::Endpoint
  responds_to :delete, "/logout", authenticated_by: Authenticators::Session

  def status
    session.clear
    303
  end

  def headers = location("/login")
end
```

The form that posts to a Liberty Web application carries the token in a hidden field, and a page that posts with JavaScript carries it in a `<meta name="csrf-token">` tag and sends it back as `X-CSRF-Token`. Both are the application's markup; the gem only checks them.

### Redirects as challenges

A Liberty authenticator names the endpoint class that answers when there is no principal. For a browser that is a redirect, and `Redirect.to` builds it:

```ruby
module Authenticators
  class Session < Liberty::Authenticator
    def principal = users.find(request.env["rack.session"][:user_id])

    def challenge_endpoint_class = Liberty::Web::Redirect.to("/login")
  end
end
```

`Redirect.to(path, status: 303)` returns one class per path and status, so Liberty sees the same class each time.

### Testing

`require "liberty/web/testing"` where your specs are set up. It is not loaded by `require "liberty/web"`.

```ruby
APP = Liberty::Web::Testing.lint(Rack::Builder.parse_file("config.ru"))   # every request and response checked against the Rack spec

token = Liberty::Web::Testing.csrf_token_in(last_response.body)          # the hidden field's value, for posting a form back
```

### Behind a proxy

With `secure_cookies: true`, the session middleware writes no cookie unless the request arrived over TLS, and the origin check compares against the scheme the request arrived with. Puma usually sits behind a proxy that terminates TLS, so Rack learns the scheme from `X-Forwarded-Proto`, or from a `Forwarded` header with `proto=https`. Caddy, Fly, Heroku, and Render add it for you. Nginx does not:

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
```

Without it, the first symptom is a 403 on every form post.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add liberty-web

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install liberty-web

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run every gate: the specs, Standard, qlty, and flog. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/first-try-software/liberty-web. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/first-try-software/liberty-web/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Liberty Web project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/first-try-software/liberty-web/blob/main/CODE_OF_CONDUCT.md).
