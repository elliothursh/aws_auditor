require 'aws-sdk'
require 'yaml'
require 'hashie'

module AwsAuditor
  class AwsConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class AWSSDK
    def self.authenticate(environment)
      aws = Aws::SharedCredentials.new(profile_name: environment)
      Aws.config.update({region: 'us-east-1', credentials: aws})
    end
  end
end
