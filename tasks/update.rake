desc 'Update bundled gems and bower packages. Use this in place of `bundle update` and `bower update`'
task "update" do
  require 'yaml'
  require 'json'
  require 'thor'

  class Utilities < Thor
    include Thor::Actions

    no_tasks do
      def append(file, string)
        gsub_file file, /^(gem .+?)(gem .+?)+$/, '\1' + "\n" + '\2'
        append_file file, string, {:verbose => false}
        gsub_file file, /^(gem .+?)(gem .+?)+$/, '\1' + "\n" + '\2'
      end

      def update_plugin_list(file, list)
        gsub_file file, /<ol>\s*(<li>.+?<\/li>\s*)+<\/ol>/, "<ol>\n    #{list.join("\n    ")}\n  </ol>"
      end
    end
  end

  utilities = Utilities.new

  plugins = YAML.load_file("config/plugins.yml")
  gemfile = File.new('Gemfile').read
  sass_input_list = []
  new_specs = []

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

  Rake::Task["test"].invoke

  plugins.sort.each do |plugin, info|
    if info[:gem]
      version = stdout.scan(/#{info[:gem]} (.+)/)[0][0].to_s
    else
      version = `bower info #{info[:bower]} version -jq`.chomp!
      version.gsub!(/"/, '') unless version.nil?

      if version.nil?
        version = JSON.parse(File.read("lib/sass_modules/#{info[:bower]}/.bower.json"))["_release"]
      end
    end

    sass_input_list.push "<li><a data-import=\"#{info[:import].to_s.gsub(/(\"|\[|\]|\s*)/, '')}\">#{plugin}</a>&nbsp;&nbsp;(v#{version})</li>"
  end

  utilities.update_plugin_list('public/extensions.html', sass_input_list)
end
