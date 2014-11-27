$LOAD_PATH.unshift(File.join(File.dirname(File.realpath(__FILE__)), 'lib'))
$LOAD_PATH.unshift(File.join(Dir.pwd, 'lib'))

require 'rubygems'
require 'bundler'
Bundler.setup :default, :application, ENV['RACK_ENV']

require 'sinatra/base'
require 'sassmeister_utilities'
require 'yaml'
require 'benchmark'
require 'json'

class SassMeisterApp < Sinatra::Base
  helpers SassMeisterUtilities

  configure :production do
    require 'newrelic_rpm'
  end

  before do
    @plugins = plugins

    request.body.rewind

    unless (@payload = request.body.read).empty?
      @payload = JSON.parse @payload, symbolize_names: true
      @payload[:syntax].downcase!
    end

    content_type 'application/json'
  end


  get '/' do
    JSON.generate({
      sass: Gem.loaded_specs['sass'].version,
      engine: 'Ruby'
    })
  end


  post '/compile' do
    css = ''

    time = Benchmark.realtime do
      css = sass_compile @payload[:input], @payload[:syntax], @payload[:output_style]
    end

    json_response css, time
  end


  post '/convert' do
    css = ''

    time = Benchmark.realtime do
      css = sass_convert @payload[:original_syntax], @payload[:syntax], @payload[:input]
    end

    json_response css, time
  end


  get %r{/extensions(?:\.json)} do
    last_modified app_last_modified.httpdate

    cache_control :public, max_age: 2592000 # 30 days, in seconds

    list = plugins.merge(plugins) do |plugin, info|
      info.reject {|key, value| key.to_s.match /gem|bower|paths|fingerprint/ }
    end

    list.to_json.to_s
  end

  run! if app_file == $0
end

