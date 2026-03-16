# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/removable_authorizations/version"

Gem::Specification.new do |s|
  s.version = Decidim::RemovableAuthorizations::VERSION
  s.authors = ["Eduardo Martinez Echevarria"]
  s.email = ["eduardomech@gmail.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-removable_authorizations"
  s.required_ruby_version = ">= 3.3"

  s.name = "decidim-removable_authorizations"
  s.summary = "A decidim removable_authorizations module"
  s.description = "This module allows admin to search authorizations and remove them."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::RemovableAuthorizations::DECIDIM_VERSION
end
