# frozen_string_literal: true

RSpec.describe Liberty::Web::Config do
  def complete(**overrides)
    described_class.new(
      session_secrets: ["s" * 64],
      permitted_hosts: ["example.org"],
      secure_cookies: false,
      renderer: Object.new,
      **overrides
    )
  end

  describe ".new" do
    it "never raises, even with nothing given" do
      config = described_class.new

      expect(config.errors.size).to eq(4)
    end

    it "wraps one secret and one host in arrays" do
      config = complete(session_secrets: "s" * 64, permitted_hosts: "example.org")

      expect(config.session_secrets).to eq(["s" * 64])
      expect(config.permitted_hosts).to eq(["example.org"])
    end

    it "defaults static and logger to nil" do
      config = complete

      expect(config.static).to be_nil
      expect(config.logger).to be_nil
    end
  end

  describe "#errors" do
    it "is empty for a complete config" do
      expect(complete.errors).to eq([])
    end

    it "names a missing secret" do
      config = complete(session_secrets: [])

      expect(config.errors).to eq(["session_secrets must hold at least one secret"])
    end

    it "names a short secret, even among long ones" do
      config = complete(session_secrets: ["s" * 64, "short"])

      expect(config.errors).to eq(["session_secrets must each be at least 64 bytes"])
    end

    it "names an empty host list" do
      config = complete(permitted_hosts: [])

      expect(config.errors).to eq(["permitted_hosts must name at least one host"])
    end

    it "names secure_cookies left unset" do
      config = complete(secure_cookies: nil)

      expect(config.errors).to eq(["secure_cookies must be true or false"])
    end

    it "names a missing renderer" do
      config = complete(renderer: nil)

      expect(config.errors).to eq(["renderer must be set"])
    end

    it "names a static root that is not a directory" do
      config = complete(static: "/nowhere/public")

      expect(config.errors).to eq(["static must be an existing directory"])
    end

    it "accepts a static root that is a directory" do
      config = complete(static: File.expand_path("../../../fixtures/public", __dir__))

      expect(config.errors).to eq([])
    end
  end

  describe "#valid?" do
    it "is true with no errors" do
      expect(complete.valid?).to be(true)
    end

    it "is false with any" do
      expect(complete(renderer: nil).valid?).to be(false)
    end
  end
end
