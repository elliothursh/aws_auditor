require 'aws-sdk'
require 'yaml'
require 'hashie'

module AwsAuditor
  class AwsConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class AWSSDK
    FILE_NAMES = %w[.aws.yml .fog]

    def self.configuration(environment)
      @environment = environment
      load_config
      if @config[:mfa_serial_number]
        creds = get_session(@config).credentials
      else
        creds = { access_key_id: access_key_id(@config), secret_access_key: secret_access_key(@config) }
      end
      AWS.config(creds)
    end

    def self.access_key_id(config)
      config[:access_key_id] || config[:aws_access_key_id]
    end


    def self.secret_access_key(config)
      config[:secret_access_key] || config[:aws_secret_access_key]
    end

    def self.region(config)
      config[:region] || 'us-east-1'
    end

    def self.load_config
      return @config if @config
      @config = AwsConfig[YAML.load_file(config_path)]
      if @config.has_key? @environment
        @config = @config[@environment]
      else
        raise MissingEnvironment, "Could not find AWS credentials for #{@environment} environment"
      end
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
          puts "Could not find #{FILE_NAMES.join(' or ')}"; exit
        end
      end
    end

    def self.get_mfa_token
      Output.ask("Enter MFA token: "){ |q|  q.validate = /^\d{6}$/ }
    end

    def self.get_session(config)
      return @session if @session
      sts = AWS::STS.new(access_key_id: access_key_id(config),
                         secret_access_key: secret_access_key(config))
      @session = sts.new_session(serial_number: config[:mfa_serial_number], token_code: get_mfa_token)
    end

    MissingEnvironment = Class.new(StandardError)
  end
end
