desc 'Update bundled gems and bower packages. Use this in place of `bundle update` and `bower update`'
task "update" do
  require 'yaml'
  require 'json'
  require 'thor'

  class Utilities < Thor
    include Thor::Actions
  end

  utilities = Utilities.new

  plugins = YAML.load_file("config/plugins.yml")
  gemfile = File.new('Gemfile').read
  new_specs = []
  extensions = {}

  plugins.each do |plugin, info|
    if ! gemfile.match(/^\s*gem '#{info[:gem]}'/) && !info[:gem].nil?
      puts "Adding #{info[:gem]} to Gemfile..."

      utilities.inject_into_file('Gemfile', "  gem '#{info[:gem]}'\n", :after => "group :application do\n")
    end

    unless File.exists? "spec/fixtures/#{plugin}.scss"
      utilities.create_file "spec/fixtures/#{plugin}.scss"

      new_specs.push "spec/fixtures/#{plugin}.scss"
    end
  end

  stdout = `bundle update`
  puts stdout

  puts `bower update`

  unless new_specs.empty?
    utilities.say_status('stopped', 'Populate the following new spec fixtures before continuing.', :red)
    new_specs.each {|spec| utilities.say_status('new', spec, :blue)}
    raise
  end

  plugins.sort.each do |plugin, info|
    if info[:gem]
      version = stdout.scan(/#{info[:gem]} ([\d\w\._-]+)/)[0][0].to_s
      homepage = Gem.latest_spec_for(info[:gem]).homepage
      extensions[plugin] = {gem: info[:gem]}
    else
      version = `bower info #{info[:bower]} version -jq`.chomp!
      version.gsub!(/"/, '') unless version.nil?

      homepage = `bower info #{info[:bower]} homepage -jq`.chomp!
      homepage.gsub!(/"/, '') unless homepage.nil?

      if version.nil?
        version = JSON.parse(File.read("lib/sass_modules/#{info[:bower]}/.bower.json"))["_release"]
      end

      extensions[plugin] = {bower: info[:bower], paths: info[:paths]}
    end

    extensions[plugin].merge!({version: version, import: info[:import], fingerprint: info[:fingerprint], homepage: homepage})

  end

  utilities.create_file 'config/extensions.yml', extensions.to_yaml.to_s, {force: true}

  Rake::Task["test"].invoke
end

