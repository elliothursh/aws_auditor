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
  end
end
