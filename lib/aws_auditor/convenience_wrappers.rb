require_relative './aws'
require_relative './google'

module AwsAuditor
  module AWSWrapper
    attr_accessor :aws

    def aws(environment)
      @aws ||= AwsAuditor::AWSSDK.configuration(environment)
    end
  end

  module EC2Wrapper
    attr_accessor :ec2

    def ec2
      @ec2 ||= AWS::EC2.new
    end
  end

  module OpsWorksWrapper
    attr_accessor :opsworks

    def opsworks
      @opsworks ||= AWS::OpsWorks.new.client
    end
  end

  module RDSWrapper
    attr_accessor :rds

    def rds
      @rds ||= AWS::RDS.new.client
    end
  end
    
  module CacheWrapper
    attr_accessor :cache

    def cache
      @cache ||= AWS::ElastiCache.new.client
    end
  end

  module GoogleWrapper
    attr_accessor :google

    def google
      @google ||= AwsAuditor::Google.configuration
    end
  end
  
end