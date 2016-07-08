require 'aws-sdk'
require 'yaml'
require 'hashie'

module SportNginAwsAuditor
  class AwsConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class AWSSDK
    def self.authenticate(environment)
      shared_credentials = Aws::SharedCredentials.new(profile_name: environment)
      Aws.config.update({region: 'us-east-1', credentials: shared_credentials})

      iam = Aws::IAM::Client.new

       # this will be an array of 0 or 1 because iam.list_mfa_devices.mfa_devices will only return 0 or 1 device per user;
       # if user doesn't have MFA enabled, then this loop won't even execute
      iam.list_mfa_devices.mfa_devices.each do |mfadevice|
        mfa_serial_number = mfadevice.serial_number
        mfa_token = Output.ask("Enter MFA token: "){ |q|  q.validate = /^\d{6}$/ }
        session_credentials_hash = get_session(mfa_token,
                                               mfa_serial_number,
                                               shared_credentials.credentials.access_key_id,
                                               shared_credentials.credentials.secret_access_key).credentials

        session_credentials = Aws::Credentials.new(session_credentials_hash.access_key_id,
                                                   session_credentials_hash.secret_access_key,
                                                   session_credentials_hash.session_token)
        Aws.config.update({region: 'us-east-1', credentials: session_credentials})
      end
    end

    def self.get_session(mfa_token, mfa_serial_number, access_key_id, secret_access_key)
      return @session if @session
      sts = Aws::STS::Client.new(access_key_id: access_key_id,
                                 secret_access_key: secret_access_key,
                                 region: 'us-east-1')
      @session = sts.get_session_token(duration_seconds: 3600,
                                       serial_number: mfa_serial_number,
                                       token_code: mfa_token)
    end

    def self.authenticate_with_roles(environment)
        Aws.config.update({region: 'us-east-1'})
    end
  end
end
