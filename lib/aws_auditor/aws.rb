require 'aws-sdk'
require 'yaml'
require 'hashie'

module AwsAuditor
  class AwsConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

	class AWSSDK
		FILE_NAMES = %w[.aws.yml]

		def self.configuration(environment)
      @environment = environment
      load_config
      AWS.config({
        :access_key_id => @config[:access_key_id],
        :secret_access_key => @config[:secret_access_key],
        :region => @config[:region]
      })
		end

    def self.load_config
      return @config if @config
      @config = AwsConfig[YAML.load_file(config_path)]
      @config = @config[@environment] if @environment
      @config[:region] ||= 'us-east-1'
      @config
    end

		def self.config_path
			if filepath = FILE_NAMES.detect {|filename| File.exists?(filename)}
        File.join(Dir.pwd, filepath)
      else
        old_dir = Dir.pwd
        Dir.chdir('..')
        if old_dir != Dir.pwd
          config_path
        else
          puts "Could not find #{FILE_NAMES.join(' or ')}"
          exit
        end
      end
    end
	end
end