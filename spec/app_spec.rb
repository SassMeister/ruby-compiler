require 'yaml'
require 'json'
require_relative 'spec_helper.rb'

class AppTest < MiniTest::Spec
  include Rack::Test::Methods

  register_spec_type(/.+$/, self)

  def app
    SassMeisterApp
  end

  def is_valid?(css)
    css.strip!
    return ! (css.nil? || css.empty? || css.include?('Undefined') || css.include?('Invalid') || css.include?('unreadable'))
  end

  describe "Routes" do
    describe "GET /" do
      before do
        # using the rack::test:methods, call into the sinatra app and request the following url
        get "/"
      end

      it "responds not found" do
        # Ensure the request we just made gives us a  status code
        last_response.status.must_equal 404
      end
    end

    #describe "GET /extensions" do
    #  before do
    #    get "/extensions"
    #  end

    #  it "responds with extension list JSON" do
    #    file = File.read(File.join(Dir.pwd, 'public', 'extensions.json')).to_s
    #    assert_equal last_response.body, file
    #  end
    #end

    describe "POST /compile" do
      before do
        post '/compile', {input: "$color: #f00;\n\n.box {\n  background: $color;\n}", syntax: "scss", output_style: "compact"}
      end

      it "responds with a JSON object containing compiled CSS" do
        json = JSON.parse(last_response.body)
        assert_equal json['css'].strip, '.box { background: red; }'
      end
    end

    describe "POST /convert with SCSS input" do
      before do
        post '/convert', {input: "$color: #f00;\n\n.box {\n  background: $color;\n}", syntax: "sass", original_syntax: "scss"}
      end

      it "responds with a JSON object containing Sass" do
        json = JSON.parse(last_response.body)
        assert_equal json['css'].strip, "$color: red\n\n.box\n  background: $color"
      end
    end

  end


  describe "Extensions" do
    plugins = YAML.load_file('config/plugins.yml')

    plugins.each do |plugin, info|
      describe "Sass input with #{plugin} selected" do
        before do
          post '/compile', {input: File.read(File.expand_path "spec/fixtures/#{plugin}.scss"), syntax: "scss", output_style: "compact"}
        end

        it "should return valid CSS" do
          is_valid?(JSON.parse(last_response.body)['css']).must_equal true
        end
      end
    end
  end

end
