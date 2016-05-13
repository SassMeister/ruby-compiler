source 'http://rubygems.org'
ruby '2.3.0'

gem 'rack-contrib', '~> 1.4.0'
gem 'sinatra'
gem 'unicorn'

# The host app should specify its own versions of Sass and Compass
# gem 'sass'
# gem 'compass'

group :development, :test do
  gem 'rake'
  gem 'pry-remote'
  gem 'thor'
  gem 'rack-test'
end

group :test do
  gem 'fakeredis'
end

group :development, :production do
  gem 'redis'
end

group :production do
  gem 'newrelic_rpm'
end

group :application do
  # Sass library gems go here
end
