# frozen_string_literal: true

RSpec.describe Liberty::Web::RequestLogger do
  def logger_seen_by(middleware, errors)
    seen = nil
    app = ->(env) {
      seen = env["rack.logger"]
      [200, {}, []]
    }

    middleware.new(app).call(Rack::MockRequest.env_for("/", "rack.errors" => errors))

    seen
  end

  describe "#call" do
    it "gives the request an INFO logger on its own error stream" do
      errors = StringIO.new

      logger = logger_seen_by(described_class, errors)

      logger.warn("careful")
      logger.debug("chatter")
      expect(errors.string).to include("careful")
      expect(errors.string).not_to include("chatter")
    end

    it "hands every request the injected logger instead" do
      injected = Logger.new(StringIO.new)
      seen = nil
      app = ->(env) {
        seen = env["rack.logger"]
        [200, {}, []]
      }

      described_class.new(app, injected).call(Rack::MockRequest.env_for("/"))

      expect(seen).to be(injected)
    end
  end
end
