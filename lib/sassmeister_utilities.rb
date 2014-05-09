require 'yaml'
require 'sass'
require 'compass'

module SassMeisterUtilities
  def plugins
    @plugins ||= YAML.load_file("config/plugins.yml")
  end


  def require_plugins(sass)
    local_paths = ["lib/sass_modules/"]

    get_imports_from_sass(sass) do |name, plugin| 
      if plugin[:gem]
        require plugin[:gem]

      elsif plugin[:bower]
        if plugin[:paths] && plugin[:paths].any?
          plugin[:paths].each do |path| 
            local_paths << "lib/sass_modules/#{path}"
          end
        end
      end
    end

    Compass.configuration.asset_cache_buster { nil }

    Compass.sass_engine_options[:load_paths].each do |path|
      Sass.load_paths << path
    end

    local_paths.each do |path|
      Sass.load_paths << path
    end
  end


  def get_imports_from_sass(sass)
    imports = sass.scan(/^\s*@import[\s\"\']*(.+?)[\"\';]*$/)
    imports.map! {|i| i.first}

    plugins.each do |key, plugin|
      if ! imports.grep(/#{plugin[:fingerprint].gsub(/\*/, '.*?')}/).empty?
        yield key, plugin if block_given?
      end
    end
  end


  def get_build_dependencies(sass)
    dependencies = {
      'Sass' =>  Gem.loaded_specs["sass"].version.to_s,
      'Compass' => Gem.loaded_specs["compass"].version.to_s
    }

    get_imports_from_sass(sass) {|name, plugin| dependencies[name] = plugin[:version] }

    return dependencies
  end


  def unpack_dependencies(sass)
    frontmatter = sass.slice(/^\/\/ ---\n(?:\/\/ .+\n)*\/\/ ---\n/)

    if frontmatter.nil?
      frontmatter = sass.scan(/^\/\/ ([\w\s]+?) [\(\)v[:alnum:]\.]+?\s*$/).first
    else
      frontmatter = frontmatter.to_s.gsub(/(\/\/ |---|\(.+$)/, '').strip.split(/\n/)
    end

    frontmatter.delete_if do |x|
      ! plugins.key?(x.to_s.strip)
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
      Sass::Engine.new(sass.chomp, :syntax => syntax.to_sym, :style => :"#{output_style}", :quiet => true).render

    rescue Sass::SyntaxError => e
      status 200
      e.to_s
    end
  end


  def sass_convert(from_syntax, to_syntax, sass)
    begin
      Sass::Engine.new(sass, {:from => from_syntax.to_sym, :to => to_syntax.to_sym, :syntax => from_syntax.to_sym}).to_tree.send("to_#{to_syntax}").chomp
    rescue Sass::SyntaxError => e
      sass
    end
  end
end
