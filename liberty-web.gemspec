# frozen_string_literal: true

require_relative "lib/liberty/web/version"

Gem::Specification.new do |spec|
  spec.name = "liberty-web"
  spec.version = Liberty::Web::VERSION
  spec.authors = ["Alan Ridlehoover", "Fito von Zastrow"]
  spec.email = ["liberty@firsttry.software"]

  spec.summary = "The browser stack for Liberty applications"
  spec.description = "Sessions, CSRF, host and origin checks, security headers, redirects, and a renderer seam " \
    "for Liberty applications that serve browsers. Liberty itself stays free of them."
  spec.homepage = "https://github.com/first-try-software/liberty-web"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/first-try-software/liberty-web/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "liberty", "~> 0.5"
  spec.add_dependency "rack", "~> 3.1"
  spec.add_dependency "rack-protection", "~> 4.2"
  spec.add_dependency "rack-session", "~> 2.1"
end
