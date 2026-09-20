# frozen_string_literal: true

RSpec.describe Liberty::Web::Endpoint do
  def build(endpoint_class, session: {})
    env = Rack::MockRequest.env_for("/", "rack.session" => session)
    endpoint_class.new.tap { |endpoint| endpoint.inject(request: Liberty::Adapters::Request.new(env)) }
  end

  def csrf_check(session, token)
    env = Rack::MockRequest.env_for("/", method: "POST", params: {"authenticity_token" => token}).merge("rack.session" => session)
    status, _headers, _body = Rack::Protection::AuthenticityToken.new(->(_env) { [200, {}, []] }).call(env)
    status
  end

  it "is a Liberty endpoint" do
    expect(described_class.superclass).to be(Liberty::Endpoint)
  end

  describe "#session" do
    it "is the request's rack session" do
      endpoint_class = Class.new(described_class) do
        def text = session[:name]
      end

      endpoint = build(endpoint_class, session: {name: "Alan"})

      expect(endpoint.text).to eq("Alan")
    end
  end

  describe "#csrf_token" do
    it "is a token the CSRF middleware accepts for this session" do
      session = {}
      endpoint_class = Class.new(described_class) do
        def text = csrf_token
      end

      token = build(endpoint_class, session: session).text

      expect(csrf_check(session, token)).to eq(200)
      expect(csrf_check(session, "not-it")).to eq(403)
    end
  end

  describe "#location" do
    it "is the header hash for a redirect" do
      endpoint_class = Class.new(described_class) do
        def headers = location("/journal")
      end

      endpoint = build(endpoint_class)

      expect(endpoint.headers).to eq({"location" => "/journal"})
    end
  end
end
