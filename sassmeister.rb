$LOAD_PATH.unshift(File.join(File.dirname(File.realpath(__FILE__)), 'lib'))
$LOAD_PATH.unshift(File.join(Dir.pwd, 'lib'))


require 'rubygems'
require 'bundler'
Bundler.setup(:default, :application, ENV['RACK_ENV'])

require 'sinatra/base'
require 'sassmeister_utilities'
require 'yaml'
require 'benchmark'

class SassMeisterApp < Sinatra::Base
  helpers SassMeisterUtilities

  configure :production do
    require 'newrelic_rpm'
  end

  helpers do
    def origin
      return request.env["HTTP_ORIGIN"] if origin_allowed? request.env["HTTP_ORIGIN"]

      return false
    end

    def origin_allowed?(uri)
      return false if uri.nil?

      return uri.match(/^http:\/\/(.+\.){0,1}sassmeister\.(com|dev|((\d+\.){4}xip\.io))/)
    end
  end

  before do
    @plugins = plugins

    params[:syntax].downcase! unless params[:syntax].nil?
    params[:original_syntax].downcase! unless params[:original_syntax].nil?

    headers 'Access-Control-Allow-Origin' => origin if origin
  end

  post '/compile' do
    content_type 'application/json'

    css = ''

    time = Benchmark.realtime do
      css = sass_compile(params[:input], params[:syntax], params[:output_style])
    end

    {
      css: css,
      dependencies: get_build_dependencies(params[:input]),
      time: time.round(3)
    }.to_json.to_s
  end

  post '/convert' do
    content_type 'application/json'

    css = ''

    time = Benchmark.realtime do
      css = sass_convert(params[:original_syntax], params[:syntax], params[:input])
    end

    {
      css: css,
      dependencies: get_build_dependencies(params[:input]),
      time: time.round(3)
    }.to_json.to_s
  end

  get '/extensions' do    
    last_modified app_last_modified.httpdate

    cache_control :public, max_age: 2592000 # 30 days, in seconds

    content_type 'application/json'

    list = plugins.merge(plugins) do |plugin, info|
      info.reject {|key, value| key.to_s.match(/gem|bower|paths|fingerprint/)  }
    end

    list.to_json.to_s
  end

  get %r{/([\w]+)/(css|text)} do |path, ext|
    send_file File.join(settings.public_folder, "#{path}.#{ext}")
  end

  run! if app_file == $0
end
