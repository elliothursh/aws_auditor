require_relative './instance_helper'

module AwsAuditor
  class EC2Instance
    extend InstanceHelper
    extend EC2Wrapper

    attr_accessor :id, :platform, :availability_zone, :instance_type, :count
    def initialize(ec2_instance, count=1)
      @id = ec2_instance.id
      @platform = platform_helper(ec2_instance)
      @availability_zone = ec2_instance.availability_zone
      @instance_type = ec2_instance.instance_type
      @count = count
    end

    def to_s
      "#{@platform} #{@availability_zone} #{@instance_type}"
    end

    def platform_helper(ec2_instance)
      if ec2_instance.class.to_s == 'AWS::EC2::Instance'
        if ec2_instance.vpc? 
          return 'VPC'
        elsif ec2_instance.platform
          if ec2_instance.platform.downcase.include? 'windows' 
            return 'Windows'
          else
            return 'Linux'
          end
        else
          return 'Linux'
        end
      elsif ec2_instance.class.to_s == 'AWS::EC2::ReservedInstances'
        if ec2_instance.product_description.downcase.include? 'vpc' 
          return 'VPC'
        elsif ec2_instance.product_description.downcase.include? 'windows'
          return 'Windows'
        else
          return 'Linux'
        end
      end
    end

    def self.get_instances
      instances = ec2.instances
      instances.map do |instance|
        next unless instance.status.to_s == 'running'
        new(instance)
      end if instances
    end

    def self.get_reserved_instances
      reserved_instances = ec2.reserved_instances
      reserved_instances.map do |ri|
        next unless ri.state == 'active'
        new(ri, ri.instance_count)
      end if reserved_instances
    end

  end
end