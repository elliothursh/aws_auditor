require_relative './aws'
require_relative './google'

module SportNginAwsAuditor
  attr_accessor :assume_role_creds

  module AWSWrapper
    attr_accessor :aws, :account_id

    def aws(environment, global_options)
      if global_options[:aws_roles]
        SportNginAwsAuditor::AWSSDK.authenticate_with_roles(environment, global_options[:region])
      elsif global_options[:assume_roles]
        @assume_role_creds = SportNginAwsAuditor::AWSSDK.authenticate_for_multiple_accounts(environment,
                                                                                            global_options[:arn_id],
                                                                                            global_options[:role_name],
                                                                                            global_options[:region])
      else
        SportNginAwsAuditor::AWSSDK.authenticate(environment, global_options[:region])
      end
    end

    def get_account_id
      @account_id ||= Aws::STS::Client.new.get_caller_identity.account
    end
  end

  module EC2Wrapper
    attr_accessor :ec2

    def ec2
      return @ec2 if @ec2
      if @assume_role_creds
        @ec2 = Aws::EC2::Client.new(credentials: @assume_role_creds)
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
    attr_accessor :rds

    def rds
      return @rds if @rds
      if @assume_role_creds
        @rds = Aws::RDS::Client.new(credentials: @assume_role_creds)
      else
        @rds = Aws::RDS::Client.new
      end
    end
  end
    
  module CacheWrapper
    attr_accessor :cache

    def cache
      return @cache if @cache
      if @assume_role_creds
        @cache = Aws::ElastiCache::Client.new(credentials: @assume_role_creds)
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
