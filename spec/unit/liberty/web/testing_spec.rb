# frozen_string_literal: true

RSpec.describe Liberty::Web::Testing do
  describe ".lint" do
    it "wraps the app so every request and response is checked against the Rack spec" do
      app = ->(_env) { [200, {"content-type" => "text/plain"}, ["ok"]] }

      linted = described_class.lint(app)

      expect(linted).to be_a(Rack::Lint)
    end
  end

  describe ".csrf_token_in" do
    it "reads the hidden field's value" do
      html = %(<form><input type="hidden" name="authenticity_token" value="abc123"></form>)

      expect(described_class.csrf_token_in(html)).to eq("abc123")
    end

    it "is nil when there is no field" do
      expect(described_class.csrf_token_in("<form></form>")).to be_nil
    end
  end
end
