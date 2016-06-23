require 'aws-sdk'
require 'yaml'
require 'hashie'

module AwsAuditor
  class AwsConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class AWSSDK
    FILE_NAMES = %w[.aws.yml .fog]

    def self.authenticate(environment)
      Aws::SharedCredentials.new(profile_name: environment)
    end

  #   def self.configuration(environment)
  #     @environment = environment
  #     # load_config
  #     # if @config[:mfa_serial_number]
  #     #   creds = get_session(@config).credentials
  #     #   aws_config = { access_key_id: creds.access_key_id, secret_access_key: creds.secret_access_key, session_token: creds.session_token }
  #     # else
  #     #   aws_config = { access_key_id: access_key_id(@config), secret_access_key: secret_access_key(@config) }
  #     # end
  #     # Aws::Credentials.new(aws_config[:access_key_id], aws_config[:secret_access_key], aws_config[:session_token])
  #     Aws::SharedCredentials.new(profile_name: environment.to_s)
  #   end

  #   def self.access_key_id(config)
  #     config[:access_key_id] || config[:aws_access_key_id]
  #   end


  #   def self.secret_access_key(config)
  #     config[:secret_access_key] || config[:aws_secret_access_key]
  #   end

  #   def self.mfa_serial_number(config)
  #     config[:mfa_serial_number]
  #   end

  #   def self.region(config)
  #     config[:region] || 'us-east-1'
  #   end

  #   def self.load_config
  #     return @config if @config
  #     @config = AwsConfig[YAML.load_file(config_path)]
  #     if @config.has_key? @environment
  #       @config = @config[@environment]
  #     else
  #       raise MissingEnvironment, "Could not find AWS credentials for #{@environment} environment"
  #     end
  #     @config
  #   end

  #   def self.config_path
  #     if filepath = FILE_NAMES.detect {|filename| File.exists?(filename)}
  #       File.join(Dir.pwd, filepath)
  #     else
  #       old_dir = Dir.pwd
  #       Dir.chdir('..')
  #       if old_dir != Dir.pwd
  #         config_path
  #       else
  #         puts "Could not find #{FILE_NAMES.join(' or ')}"; exit
  #       end
  #     end
  #   end3

  #   def self.get_mfa_token
  #     Output.ask("Enter MFA token: "){ |q|  q.validate = /^\d{6}$/ }
  #   end

  #   def self.get_session(config)
  #     return @session if @session
  #     sts = Aws::STS::Client.new(access_key_id: access_key_id(config),
  #                                secret_access_key: secret_access_key(config),
  #                                region: 'us-east-1')
  #     @session = sts.get_session_token(duration_seconds: session_duration,
  #                                      serial_number: mfa_serial_number(config),
  #                                      token_code: get_mfa_token)
  #   end

  #   MissingEnvironment = Class.new(StandardError)
  end
end
