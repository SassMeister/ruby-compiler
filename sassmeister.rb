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

    params[:syntax].downcase! unless params[:syntax].nil?
    params[:original_syntax].downcase! unless params[:original_syntax].nil?

    content_type 'application/json'
  end

  post '/compile' do

    css = ''

    time = Benchmark.realtime do
      css = sass_compile(params[:input], params[:syntax], params[:output_style])
    end

    JSON.generate({
      css: css,
      dependencies: get_build_dependencies(params[:input]),
      time: time.round(3)
    })
  end

  post '/convert' do

    css = ''

    time = Benchmark.realtime do
      css = sass_convert(params[:original_syntax], params[:syntax], params[:input])
    end

    JSON.generate({
      css: css,
      dependencies: get_build_dependencies(params[:input]),
      time: time.round(3)
    })
  end

  get '/extensions' do
    last_modified app_last_modified.httpdate

    cache_control :public, max_age: 2592000 # 30 days, in seconds


    list = plugins.merge(plugins) do |plugin, info|
      info.reject {|key, value| key.to_s.match /gem|bower|paths|fingerprint/ }
    end

    list.to_json.to_s
  end

  get %r{/([\w]+)/(css|text)} do |path, ext|
    send_file File.join settings.public_folder, "#{path}.#{ext}"
  end

  run! if app_file == $0
end
