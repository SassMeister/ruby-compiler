$LOAD_PATH.unshift(File.join(File.dirname(File.realpath(__FILE__)), 'lib'))
$LOAD_PATH.unshift(File.join(Dir.pwd, 'lib'))

require 'rubygems'
require 'bundler'
Bundler.setup :default, :application, ENV['RACK_ENV']

require 'sinatra/base'
require 'sassmeister/utilities'
require 'yaml'
require 'benchmark'
require 'json'

class SassMeisterApp < Sinatra::Base
  helpers SassMeister::Utilities

  configure :production do
    require 'newrelic_rpm'
  end

  before do
    @plugins = plugins

    request.body.rewind

    if request.post?
      @payload = request.body.read
      @payload = JSON.parse @payload, symbolize_names: true
      @payload[:syntax].downcase! if @payload[:syntax]
      @payload[:original_syntax].downcase! if @payload[:original_syntax]
    end

    content_type 'application/json'

    if request.get?
      last_modified app_last_modified.httpdate

      cache_control :public, max_age: 2592000 # 30 days, in seconds
    end
  end


  get '/' do
    JSON.generate({
      sass: Gem.loaded_specs['sass'].version,
      engine: 'Ruby'
    })
  end


  get %r{/extensions(?:\.json)*} do
    extension_list.to_json.to_s
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


  run! if app_file == $0
end

