require 'yaml'
require 'json'
require_relative 'spec_helper.rb'

class AppTest < MiniTest::Spec
  include Rack::Test::Methods

  register_spec_type /.+$/, self

  def app
    SassMeisterApp
  end


  def is_valid?(css)
    css.strip!
    return ! (css.nil? || css.empty? || css.include?('Undefined') || css.include?('Invalid CSS') || css.include?('unreadable') || css.include?('isn\'t a valid CSS value'))
  end


  def post_json(url, payload)
    post url, JSON.generate(payload), { "CONTENT_TYPE" => "application/json" }
  end


  describe 'Routes' do
    describe 'GET /' do
      before do
        # using the rack::test:methods, call into the sinatra app and request the following url
        get '/'
      end

      it "responds not found" do
        # Ensure the request we just made gives us a  status code
        last_response.status.must_equal 404
      end
    end


    describe 'GET /extensions' do
      before do
        get '/extensions.json'
      end

      it 'responds with JSON' do
        last_response.status.must_equal 200
        last_response.header['Content-Type'].must_equal 'application/json'
      end
    end


    describe 'POST /compile' do
      before do
        post_json '/compile', {input: "$size: 12px * 2;\n\n.box {\n  font-size: $size;\n}", syntax: 'scss', output_style: 'compact'}
      end

      it 'responds with a JSON object containing compiled CSS' do
        json = JSON.parse last_response.body
        assert_equal json['css'].strip, '.box { font-size: 24px; }'
      end
    end


    describe "POST /convert with SCSS input" do
      before do
        post_json '/convert', {input: "$size: 12px * 2;\n\n.box {\n  font-size: $size;\n}", syntax: 'sass', original_syntax: 'scss'}
      end

      it 'responds with a JSON object containing Sass' do
        json = JSON.parse last_response.body
        assert_equal json['css'].strip, "$size: 12px * 2\n\n.box\n  font-size: $size"
      end
    end
  end


  describe 'Extensions' do
    plugins = YAML.load_file('config/plugins.yml')

    plugins.each do |plugin, info|
      describe "Sass input with #{plugin} selected" do
        before do
          post_json '/compile', {input: File.read(File.expand_path "spec/fixtures/#{plugin}.scss"), syntax: 'scss', output_style: 'compact'}
        end

        it 'should return valid CSS' do
          is_valid?(JSON.parse(last_response.body)['css']).must_equal true
        end
      end
    end
  end
end

