$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  # Release Specific Information
  s.version     = '0.0.4'
  s.date = '2017-03-06'

  # Gem Details
  s.name = 'sassmeister'
  s.authors = ["Jed Foster"]
  s.summary = %q{Sass compiler and Sinatra routing for SassMeister.com}
  s.description = %q{Sass compiler and Sinatra routing for SassMeister.com}
  s.email = 'jed@jedfoster.com'
  s.homepage = 'https://github.com/jedfoster/SassMeister'

  # Gem Files
  
  s.files = Dir.glob("./*")
  s.require_paths = ["."]

  # Gem Bookkeeping
  s.rubygems_version = %q{1.3.6}
  s.add_dependency('dalli', ['~> 2.6.4'])
  s.add_dependency('memcachier', ['~> 0.0.2'])
  s.add_dependency('rack-cache', ['~> 1.4'])
  s.add_dependency('minitest', ['~> 5.10'])
end

