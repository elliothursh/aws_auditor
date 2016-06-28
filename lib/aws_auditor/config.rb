require 'yaml'

module AwsAuditor

  module PrivateAttrAccessor
    def private_attr_accessor(*names)
      private
      attr_accessor *names
    end
  end

  class DefaultPaths
    class << self
      def config
        File.join(self.home,'.aws_auditor.yml')
      end

      def home
        ENV['HOME'] ? ENV['HOME'] : "."
      end
    end
  end

  class Config

    CONFIG_DEFAULTS = {}

    class << self
      extend PrivateAttrAccessor
      private_attr_accessor :config_data

      def config
        CONFIG_DEFAULTS.merge data
      end

      def load(path)
        load_config(path)
        config
      end

      def set_config_options(opts = {})
        data.merge! opts
        config
      end

      def data
        self.config_data ||= {}
      end
      private :data

      def default_value(key)
        CONFIG_DEFAULTS[key.to_sym]
      end
      private :default_value

      def method_missing(method, args=false)
        return data[method] if data[method]
        return default_value(method) if default_value(method)
        nil
      end
      private :method_missing

      def load_config(file)
        raise MissingConfig, "Missing configuration file: #{file}" unless File.exist?(file)
        self.config_data = symbolize_keys(YAML.load_file(file)) rescue {}
      end
      private :load_config

      # We want all ouf our YAML loaded keys to be symbols
      # taken from http://devblog.avdi.org/2009/07/14/recursively-symbolize-keys/
      def symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|
          new_key = case key
                      when String then key.to_sym
                      else key
                    end
          new_value = case value
                        when Hash then symbolize_keys(value)
                        else value
                      end
          result[new_key] = new_value
          result
        }
      end
      private :symbolize_keys

    end

    MissingConfig = Class.new(StandardError)
  end
end
