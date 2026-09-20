## [0.1.0] - 2026-09-19

The first release. Liberty Web is the browser stack for a Liberty application, kept out of Liberty itself so an API never carries sessions it did not ask for.

### Added

- `Liberty::Web::Config`, a value the application fills in: `session_secrets`, `permitted_hosts`, `secure_cookies`, and optionally `static` and `logger`. Building one never raises; `errors` names what is missing or wrong, one sentence each, and `valid?` says whether there are any.
- `Liberty::Web.app(config)`, which wraps `Liberty.rack_app` in the browser middleware in the order a browser needs: static files, a request logger, method override, an encrypted cookie session, host authorization, the CSRF token check, the origin check, frame options, and `x-content-type-options: nosniff`. It raises `Liberty::Web::ConfigurationError` for a config with errors, naming every one, and builds nothing.
- `Liberty::Web::Endpoint`, a `Liberty::Endpoint` with three private helpers: `session`, `csrf_token`, and `location(path)`. Templates are the application's; the gem never sees its renderer.
- `Liberty::Web::Redirect.to(path, status: 303)`, an endpoint class that only redirects, for an authenticator's `challenge_endpoint_class`. One class per path and status.
- `Liberty::Web::RequestLogger`, the default logger: INFO on the request's own error stream, so rack-protection's per-request debug output stays out of the log and a spec can read what was warned. An injected logger replaces it.
- `Liberty::Web::ContentTypeOptions`, the useful half of rack-protection's `XSSHeader`. The obsolete `x-xss-protection` header is not sent.
- `Liberty::Web::Testing`, required separately, with `lint(app)` for a Rack::Lint-wrapped app and `csrf_token_in(html)` for posting forms back in request specs.
- `Liberty::Web::Error`, a `Liberty::Error`, and `Liberty::Web::ConfigurationError` beneath it.
