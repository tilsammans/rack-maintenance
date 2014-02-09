$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rack/maintenance/version"

Gem::Specification.new do |s|
  s.name          = "rack-maintenance"
  s.version       = Rack::Maintenance::VERSION
  s.authors       = ["David Dollar", "Joost Baaij"]
  s.email         = ["ddollar@gmail.com", "joost@spacebabies.nl"]
  s.homepage      = "http://github.com/tilsammans/rack-maintenance"
  s.summary       = "Detect and show a maintenance page"
  s.description   = "Detect and show a maintenance page"

  s.files         = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]
  s.test_files    = Dir["spec/**/*"]

  s.add_dependency              "rack", ">= 1.0"
  s.add_dependency              "json", ">= 1.0.0"
  s.add_development_dependency  "rspec", ">= 2.0"
end
