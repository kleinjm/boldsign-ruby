require_relative "lib/boldsign/version"

Gem::Specification.new do |spec|
  spec.name        = "boldsign"
  spec.version     = Boldsign::VERSION
  spec.authors     = ["James Klein"]
  spec.email       = ["kleinjm007@gmail.com"]

  spec.summary     = "Ruby client for the BoldSign e-signature API"
  spec.description = "A Ruby wrapper for the BoldSign REST API (documents, templates, " \
                     "contacts, teams, brands, webhooks, and more)."
  spec.homepage    = "https://github.com/escrowsafe/boldsign-ruby"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://developers.boldsign.com"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "boldsign.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 2.0"
  spec.add_dependency "faraday-multipart", ">= 1.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
end
