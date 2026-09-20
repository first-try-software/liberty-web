# frozen_string_literal: true

RSpec.describe Liberty::Web::Redirect do
  describe ".to" do
    it "answers 303 and the location" do
      endpoint = described_class.to("/login").new

      expect(endpoint.status).to eq(303)
      expect(endpoint.headers).to eq({"location" => "/login"})
    end

    it "takes another status" do
      endpoint = described_class.to("/moved", status: 301).new

      expect(endpoint.status).to eq(301)
    end

    it "is a web endpoint, so Liberty builds it like any other" do
      endpoint_class = described_class.to("/login")

      expect(endpoint_class.superclass).to be(Liberty::Web::Endpoint)
    end

    it "returns the same class for the same path and status" do
      expect(described_class.to("/login")).to be(described_class.to("/login"))
    end

    it "returns another class for another path or status" do
      expect(described_class.to("/login")).not_to be(described_class.to("/elsewhere"))
      expect(described_class.to("/login")).not_to be(described_class.to("/login", status: 302))
    end
  end
end
