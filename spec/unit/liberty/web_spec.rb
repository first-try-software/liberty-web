# frozen_string_literal: true

RSpec.describe Liberty::Web do
  it "has a version" do
    expect(Liberty::Web::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".app" do
    it "refuses a config with errors, naming every one" do
      config = Liberty::Web::Config.new

      expect { described_class.app(config) }.to raise_error(Liberty::Web::ConfigurationError) do |error|
        expect(error).to be_a(Liberty::Error)
        expect(error.message).to include("session_secrets", "permitted_hosts", "secure_cookies")
      end
    end

    it "returns a Rack application for a complete config" do
      config = Liberty::Web::Config.new(session_secrets: ["s" * 64], permitted_hosts: ["example.org"], secure_cookies: false)

      app = described_class.app(config)

      expect(app).to respond_to(:call)
    end
  end
end
