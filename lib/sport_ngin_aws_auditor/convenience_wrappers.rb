require_relative './aws'
require_relative './google'

module SportNginAwsAuditor
  attr_accessor :assume_role_creds

  module AWSWrapper
    attr_accessor :aws, :account_id

    def aws(environment, global_options)
      if global_options[:aws_roles]
        SportNginAwsAuditor::AWSSDK.update_aws_config({region: 'us-east-1'})
      elsif global_options[:assume_roles]
        @assume_role_creds = SportNginAwsAuditor::AWSSDK.authenticate_with_assumed_roles(environment,
                                                                                         global_options[:arn_id],
                                                                                         global_options[:role_name])
      else
        SportNginAwsAuditor::AWSSDK.authenticate_with_iam(environment)
      end
    end

    def get_account_id
      @account_id ||= Aws::STS::Client.new.get_caller_identity.account
    end
  end

  module EC2Wrapper
    def self.ec2(region=nil)
      if @assume_role_creds && region 
        @ec2 = Aws::EC2::Client.new(credentials: @assume_role_creds, region: region)
      elsif @assume_role_creds && !region
        @ec2 = Aws::EC2::Client.new(credentials: @assume_role_creds)
      elsif @assume_role_creds.nil? && region
        @ec2 = Aws::EC2::Client.new(region: region)
      else
        @ec2 = Aws::EC2::Client.new
      end
    end
  end

  module OpsWorksWrapper
    attr_accessor :opsworks

    def opsworks
      return @opsworks if @opsworks
      if @assume_role_creds
        @opsworks = Aws::Opsworks::Client.new(credentials: @assume_role_creds)
      else
        @opsworks = Aws::OpsWorks::Client.new
      end
    end
  end

  module RDSWrapper
    def self.rds(region=nil)
      if @assume_role_creds && region
        @rds = Aws::RDS::Client.new(credentials: @assume_role_creds, region: region)
      elsif @assume_role_creds && !region
        @rds = Aws::RDS::Client.new(credentials: @assume_role_creds)
      elsif @assume_role_creds.nil? && region
        @rds = Aws::RDS::Client.new(region: region)
      else
        @rds = Aws::RDS::Client.new
      end
    end
  end
    
  module CacheWrapper
    def self.cache(region=nil)
      if @assume_role_creds && region
        @cache = Aws::ElastiCache::Client.new(credentials: @assume_role_creds, region: region)
      elsif @assume_role_creds && !region
        @cache = Aws::ElastiCache::Client.new(credentials: @assume_role_creds)
      elsif @assume_role_creds.nil? && region
        @cache = Aws::ElastiCache::Client.new(region: region)
      else
        @cache = Aws::ElastiCache::Client.new
      end
    end
  end

  module GoogleWrapper
    attr_accessor :google

    def google
      @google ||= SportNginAwsAuditor::Google.configuration
    end
  end
  
end
