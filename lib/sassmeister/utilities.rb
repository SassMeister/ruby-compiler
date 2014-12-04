require 'yaml'
require 'sass'
require 'compass'
require 'sassmeister/redis'

module SassMeister
  module Utilities
    def plugins
      @plugins ||= YAML.load_file 'config/extensions.yml'
    end


    def extension_list
      @list ||= begin
        plugins.merge(plugins) do |plugin, info|
          info.reject {|key, value| key.to_s.match /gem|bower|paths|fingerprint/ }
        end
      end
    end


    def app_last_modified
      return @mtime ||= File.mtime(__FILE__) if settings.environment == :production

      Time.now
    end


    def json_response(css, time)
      JSON.generate({
        css: css,
        dependencies: get_build_dependencies(@payload[:input]),
        time: time.round(3)
      })
    end


    def require_plugins(sass)
      load_paths = ['lib/sass_modules/']

      get_imports_from_sass(sass) do |name, plugin|
        if plugin[:gem]
          require plugin[:gem]

        elsif plugin[:bower]
          if plugin[:paths] && plugin[:paths].any?
            plugin[:paths].each do |path|
              load_paths << "lib/sass_modules/#{path}"
            end
          end
        end
      end

      Compass.configuration.asset_cache_buster { nil }

      Compass.sass_engine_options[:load_paths].each do |path|
        load_paths << path
      end

      load_paths.uniq!

      Sass.load_paths.concat load_paths
    end


    def get_imports_from_sass(sass)
      imports = sass.scan /^\s*@import[\s\"\']*(.+?)[\"\';]*$/
      imports.map! {|i| i.first}

      plugins.each do |key, plugin|
        unless imports.grep(/#{plugin[:fingerprint].gsub(/\*/, '.*?')}/).empty?
          yield key, plugin if block_given?
        end
      end
    end


    def get_build_dependencies(sass)
      dependencies = {
        'Sass' =>  Gem.loaded_specs['sass'].version.to_s,
        'Compass' => Gem.loaded_specs['compass'].version.to_s
      }

      get_imports_from_sass(sass) {|name, plugin| dependencies[name] = plugin[:version] }

      return dependencies
    end


    def unpack_dependencies(sass)
      frontmatter = sass.slice /^\/\/ ---\n(?:\/\/ .+\n)*\/\/ ---\n/

      if frontmatter.nil?
        frontmatter = sass.scan(/^\/\/ ([\w\s]+?) [\(\)v[:alnum:]\.]+?\s*$/).first
      else
        frontmatter = frontmatter.to_s.gsub(/(\/\/ |---|\(.+$)/, '').strip.split(/\n/)
      end

      frontmatter.delete_if do |x|
        ! plugins.key? x.to_s.strip
      end

      if frontmatter.empty?
        return nil
      else
        imports = []

        plugins[frontmatter.first.strip][:import].each do |import|
          imports << "@import \"#{import}\""
        end

        return imports
      end
    end


    def sass_compile(sass, syntax, output_style)
      imports = ''

      if ! sass.match(/^\/\/ ----\n/) && sass.match(/^\/\/ ([\w\s]+?) [\(\)v\d\.]+?\s*$/)
        imports = unpack_dependencies(sass)
        imports = imports.join("#{syntax == 'scss' ? ';' : ''}\n") + "#{syntax == 'scss' ? ';' : ''}\n" if ! imports.nil?
      end

      sass.slice!(/(^\/\/ [\-]{3,4}\n(?:\/\/ .+\n)*\/\/ [\-]{3,4}\s*)*/)

      sass = imports + sass if ! imports.nil?

      require_plugins(sass)

      begin
        Sass::Engine.new(sass.chomp, syntax: syntax.to_sym, style: :"#{output_style}", quiet: true).render

      rescue Sass::SyntaxError => e
        status 200
        e.to_s
      end
    end


    def sass_convert(from_syntax, to_syntax, sass)
      sass if from_syntax == to_syntax

      begin
        Sass::Engine.new(sass, {from: from_syntax.to_sym, to: to_syntax.to_sym, syntax: from_syntax.to_sym}).to_tree.send("to_#{to_syntax}").chomp

      rescue Sass::SyntaxError => e
        sass
      end
    end


    def set_metadata
      version = Gem.loaded_specs['sass'].version.to_s

      compiler = {
        sass: version,
        engine: 'Ruby'
      }
      
      compilers = SassMeister::Redis.new 'compilers'
      compilers.merge!({version[0..2].to_sym => compiler})

      extensions = SassMeister::Redis.new 'extensions'
      extensions.merge! extension_list
    end
  end
end

