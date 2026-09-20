# frozen_string_literal: true

# The whole stack, through Rack::Lint, with endpoints the way an application writes them.
RSpec.describe Liberty::Web do
  include Rack::Test::Methods

  attr_reader :app

  def secret = "s" * 64

  def public_dir = File.expand_path("../../fixtures/public", __dir__)

  def renderer
    Object.new.tap do |renderer|
      renderer.define_singleton_method(:render) { |template, **locals| "#{template}: Hello, #{locals[:name]}" }
    end
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :get, "/web/form", authenticated_by: Liberty::Authenticators::Public

    def html = %(<form><input type="hidden" name="authenticity_token" value="#{csrf_token}"></form>)
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :post, "/web/form", authenticated_by: Liberty::Authenticators::Public

    def status = 201

    def text = "posted #{params[:name]}"
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :delete, "/web/form", authenticated_by: Liberty::Authenticators::Public

    def text = "deleted"
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :get, "/web/remember", authenticated_by: Liberty::Authenticators::Public

    def text
      session["seen"] = "yes"
      "remembered"
    end
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :get, "/web/recall", authenticated_by: Liberty::Authenticators::Public

    def text = session["seen"].to_s
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :get, "/web/page", authenticated_by: Liberty::Authenticators::Public

    def html = renderer.render("page", name: "Alan")
  end

  redirecting = Class.new(Liberty::Authenticator) do
    def principal = nil

    def challenge_endpoint_class = Liberty::Web::Redirect.to("/web/login")
  end

  Class.new(Liberty::Web::Endpoint) do
    responds_to :get, "/web/private", authenticated_by: redirecting

    def text = "never"
  end

  def build(**overrides)
    config = Liberty::Web::Config.new(
      session_secrets: [secret], permitted_hosts: ["example.org"], secure_cookies: false, renderer: renderer, static: public_dir,
      **overrides
    )
    Liberty::Web::Testing.lint(Liberty::Web.app(config))
  end

  def token
    get "/web/form", {}, {"HTTP_ACCEPT" => "text/html"}
    Liberty::Web::Testing.csrf_token_in(last_response.body)
  end

  before { @app = build }

  it "renders a token a form can post back" do
    post "/web/form", {name: "Alan", authenticity_token: token}, {"HTTP_ACCEPT" => "text/plain"}

    expect(last_response.status).to eq(201)
    expect(last_response.body).to eq("posted Alan")
  end

  it "refuses a POST without a token" do
    post "/web/form", {name: "Alan"}, {"HTTP_ACCEPT" => "text/plain"}

    expect(last_response.status).to eq(403)
  end

  it "refuses a host outside permitted_hosts and warns once on the request's error stream" do
    errors = StringIO.new

    get "/web/form", {}, {"HTTP_HOST" => "evil.example", "HTTP_ACCEPT" => "text/html", "rack.errors" => errors}

    expect(last_response.status).to eq(403)
    expect(errors.string.lines.grep(/attack prevented by Rack::Protection::HostAuthorization/).size).to eq(1)
  end

  it "refuses an unsafe request whose Origin is not its own" do
    post "/web/form", {name: "Alan", authenticity_token: token}, {"HTTP_ORIGIN" => "http://evil.example", "HTTP_ACCEPT" => "text/plain"}

    expect(last_response.status).to eq(403)
  end

  it "frames only itself and never lets a browser sniff, even a 404" do
    get "/web/form", {}, {"HTTP_ACCEPT" => "text/html"}
    expect(last_response.headers["x-frame-options"]).to eq("SAMEORIGIN")
    expect(last_response.headers["x-content-type-options"]).to eq("nosniff")

    get "/web/nowhere", {}, {"HTTP_ACCEPT" => "text/html"}
    expect(last_response.status).to eq(404)
    expect(last_response.headers["x-content-type-options"]).to eq("nosniff")
  end

  it "lets a form delete through _method on a POST, and not on a GET" do
    post "/web/form", {_method: "delete", authenticity_token: token}, {"HTTP_ACCEPT" => "text/plain"}
    expect(last_response.body).to eq("deleted")

    get "/web/form", {_method: "delete"}, {"HTTP_ACCEPT" => "text/html"}
    expect(last_response.body).to include("<form>")
  end

  it "carries the session from one request to the next" do
    get "/web/remember", {}, {"HTTP_ACCEPT" => "text/plain"}
    get "/web/recall", {}, {"HTTP_ACCEPT" => "text/plain"}

    expect(last_response.body).to eq("yes")
  end

  it "writes no cookie to a plain request when cookies are secure" do
    @app = build(secure_cookies: true)

    get "/web/remember", {}, {"HTTP_ACCEPT" => "text/plain"}

    expect(last_response.headers["set-cookie"]).to be_nil
  end

  it "serves static files from the root" do
    get "/css/site.css"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["content-type"]).to eq("text/css")
    expect(last_response.body).to include("--green")
  end

  it "keeps the error stream quiet for an ordinary request" do
    errors = StringIO.new

    get "/web/form", {}, {"HTTP_ACCEPT" => "text/html", "rack.errors" => errors}

    expect(errors.string).to eq("")
  end

  it "warns through an injected logger instead of the error stream" do
    log = StringIO.new
    errors = StringIO.new
    @app = build(logger: Logger.new(log))

    get "/web/form", {}, {"HTTP_HOST" => "evil.example", "HTTP_ACCEPT" => "text/html", "rack.errors" => errors}

    expect(log.string).to include("attack prevented by Rack::Protection::HostAuthorization")
    expect(errors.string).to eq("")
  end

  it "renders through the injected renderer" do
    get "/web/page", {}, {"HTTP_ACCEPT" => "text/html"}

    expect(last_response.body).to eq("page: Hello, Alan")
  end

  it "answers a challenge from Redirect.to" do
    get "/web/private", {}, {"HTTP_ACCEPT" => "text/plain"}

    expect(last_response.status).to eq(303)
    expect(last_response.headers["location"]).to eq("/web/login")
  end
end
