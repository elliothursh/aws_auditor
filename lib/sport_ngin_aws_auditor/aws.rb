require 'aws-sdk'

module SportNginAwsAuditor
  class AWS
    DEFAULT_REGION = 'us-east-1'

    @environment = nil
    @aws_roles = false
    @assume_roles = false
    @credentials = nil

    class << self
      attr_reader :environment, :aws_roles, :assume_roles, :credentials
    end

    def self.configure(environment, global_options)
      @environment = environment

      if global_options[:aws_roles]
        puts "Authenticating with AWS using server roles."
        @credentials = nil # Auth using server role.
      elsif global_options[:assume_roles]
        puts "Authenticating with AWS by assuming roles."
        auth_with_assumed_roles(global_options[:arn_id], global_options[:role_name])
      else
        puts "Authenticating with AWS using credentials file."
        auth_with_iam
      end
    end

    def self.reset
      @environment = @credentials = nil
      @aws_roles = @assume_roles = nil
    end

    def self.client_options(region=DEFAULT_REGION, auth_required=true)
      if auth_required && @credentials.nil? && @aws_roles == false
        raise "Unable to set AWS SDK client options because credentials not set and not flagged to use server role."
      end
      opts = { region: region }
      opts[:credentials] = @credentials unless @credentials.nil?
      opts
    end

    def self.get_account_id
      sts.get_caller_identity.account
    end

    def self.sts
      Aws::STS::Client.new(client_options(DEFAULT_REGION, false))
    end

    def self.ec2(region=DEFAULT_REGION)
      Aws::EC2::Client.new(client_options(region))
    end

    def self.rds(region=DEFAULT_REGION)
      Aws::RDS::Client.new(client_options(region))
    end

    def self.cache(region=DEFAULT_REGION)
      Aws::ElastiCache::Client.new(client_options(region))
    end


    def self.auth_with_iam
      @credentials = Aws::SharedCredentials.new(profile_name: @environment)
      iam = Aws::IAM::Client.new(client_options)

      # this will be an array of 0 or 1 because iam.list_mfa_devices.mfa_devices will only return 0 or 1 device per user;
      # if user doesn't have MFA enabled, then this loop won't even execute
      iam.list_mfa_devices.mfa_devices.each do |mfadevice|
        auth_with_mfa(mfadevice)
      end
    end

    def self.auth_with_mfa(mfadevice)
      mfa_serial_number = mfadevice.serial_number
      mfa_token = Output.ask("Enter MFA token: "){ |q|  q.validate = /^\d{6}$/ }
      session_credentials_hash = get_session(mfa_token, mfa_serial_number).credentials

      @credentials = Aws::Credentials.new(session_credentials_hash.access_key_id,
                                                 session_credentials_hash.secret_access_key,
                                                 session_credentials_hash.session_token)
    end

    def self.auth_with_assumed_roles(arn_id, role_name)
      role_arn = "arn:aws:iam::#{arn_id}:role/#{role_name}"
      session_name = "auditor#{Time.now.to_i}"
      @credentials = Aws::AssumeRoleCredentials.new(client: sts, role_arn: role_arn, role_session_name: session_name)
    end

    def self.get_session(mfa_token, mfa_serial_number)
      return @session if @session
      @session = sts.get_session_token(duration_seconds: 3600, serial_number: mfa_serial_number, token_code: mfa_token)
    end

  end
end
