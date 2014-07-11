$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  # Release Specific Information
  s.version     = '0.0.1'
  s.date = "2014-05-06"

  # Gem Details
  s.name = "sassmeister"
  s.authors = ["Jed Foster"]
  s.summary = %q{Sass compiler and Sinatra routing for SassMeister.com}
  s.description = %q{Sass compiler and Sinatra routing for SassMeister.com}
  s.email = "jed@jedfoster.com"
  s.homepage = "https://github.com/jedfoster/SassMeister"

  # Gem Files
  
  s.files = Dir.glob("./*")
  s.require_paths = ["."]

  # Gem Bookkeeping
  s.rubygems_version = %q{1.3.6}
  s.add_dependency("dalli", ["~> 2.6.4"])
  s.add_dependency("memcachier", ["~> 0.0.2"])
  s.add_dependency("rack-cache", ["~> 1.2"])
end

