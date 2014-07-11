source 'http://rubygems.org'
ruby '2.0.0'

gem 'rack-contrib', :git => 'git://github.com/rack/rack-contrib.git'
gem 'sinatra'
gem 'unicorn'
gem 'rack-cache'

# The host app should specify its own versions of Sass and Compass
# gem 'sass'
# gem 'compass'

group :development, :test do
  gem 'rake'
  gem 'pry-remote'
  gem 'thor'
  gem 'rack-test'
end

group :production do
  gem 'newrelic_rpm'
end

group :application do
  # Sass library gems go here
end
