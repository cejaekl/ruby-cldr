require 'i18n'
require 'i18n/locale/fallbacks'
require 'core_ext/string/camelize'
require 'core_ext/string/underscore'
require 'core_ext/hash/deep_stringify_keys'

class Cldr
  module Export
    autoload :Ruby, 'cldr/export/ruby'
    autoload :Yaml, 'cldr/export/yaml'

    class << self
      def base_path
        @@base_path ||= File.expand_path('./data')
      end

      def base_path=(base_path)
        @@base_path = base_path
      end

      def export(options = {}, &block)
        locales        = options[:locales]    || Data.locales
        components     = options[:components] || Data.components
        self.base_path = options[:target] if options[:target]

        locales.each do |locale|
          components.each do |component|
            exporter(component, options[:format]).export(locale, component, options, &block)
          end
        end
      end

      def fallbacks(locale)
        locale = locale.to_s.gsub('_', '-').to_sym
        I18n::Locale::Fallbacks.new(:root)[locale] # TODO should have default_fallbacks in I18n
      end

      def exporter(component, format)
        name = format ? format : component.to_s == 'Plurals' ? 'ruby' : 'yaml'
        const_get(name.to_s.camelize).new
      end

      def data(component, locale, options = {})
        if options[:merge] && component.to_s != 'Plurals'
          fallbacks(locale).inject({}) do |result, locale|
            data = Data.const_get(component.to_s.camelize).new(locale)
            data ? data.deep_merge(result) : result
          end
        else
          Data.const_get(component.to_s.camelize).new(locale)
        end
      end

      def write(path, data)
        FileUtils.rm(path) if File.exists?(path)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w+') { |f| f.write(data) }
      end

      def path(locale, component, extension)
        "#{Export.base_path}/#{locale.to_s.gsub('_', '-')}/#{component.to_s.underscore}.#{extension}"
      end
    end
  end
end