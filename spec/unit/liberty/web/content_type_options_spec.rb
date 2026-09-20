# frozen_string_literal: true

RSpec.describe Liberty::Web::ContentTypeOptions do
  describe "#call" do
    it "tells the browser not to sniff any response" do
      app = ->(_env) { [200, {"content-type" => "text/plain"}, ["ok"]] }

      _status, headers, _body = described_class.new(app).call(Rack::MockRequest.env_for("/"))

      expect(headers["x-content-type-options"]).to eq("nosniff")
    end

    it "leaves a value the application set" do
      app = ->(_env) { [200, {"x-content-type-options" => "custom"}, ["ok"]] }

      _status, headers, _body = described_class.new(app).call(Rack::MockRequest.env_for("/"))

      expect(headers["x-content-type-options"]).to eq("custom")
    end
  end
end
