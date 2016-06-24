require_relative './aws'
require_relative './google'

module AwsAuditor
  attr_accessor :creds

  module AWSWrapper
    attr_accessor :aws, :account_id

    def aws(environment)
      AwsAuditor::AWSSDK.authenticate(environment)
    end

    def get_account_id
      @account_id ||= Aws::STS::Client.new.get_caller_identity.account
      # puts @account_id
    end
  end

  module EC2Wrapper
    attr_accessor :ec2

    def ec2
      @ec2 ||= Aws::EC2::Client.new(region: 'us-east-1')
    end
  end

  module OpsWorksWrapper
    attr_accessor :opsworks

    def opsworks
      @opsworks ||= Aws::OpsWorks::Client.new(region: 'us-east-1')
    end
  end

  module RDSWrapper
    attr_accessor :rds

    def rds
      @rds ||= Aws::RDS::Client.new(region: 'us-east-1')
    end
  end
    
  module CacheWrapper
    attr_accessor :cache

    def cache
      @cache ||= Aws::ElastiCache::Client.new(region: 'us-east-1')
    end
  end

  module GoogleWrapper
    attr_accessor :google

    def google
      @google ||= AwsAuditor::Google.configuration
    end
  end
  
end
