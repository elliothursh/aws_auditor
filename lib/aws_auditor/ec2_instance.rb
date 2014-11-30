require_relative './instance_helper'

module AwsAuditor
  class EC2Instance
    extend InstanceHelper
    extend EC2Wrapper

    class <<self
      attr_accessor :instances, :reserved_instances
    end

    attr_accessor :id, :name, :platform, :availability_zone, :instance_type, :count, :stack_name
    def initialize(ec2_instance, count=1)
      @id = ec2_instance.id
      @name = nil
      @platform = platform_helper(ec2_instance)
      @availability_zone = ec2_instance.availability_zone
      @instance_type = ec2_instance.instance_type
      @count = count
      @stack_name = nil
    end

    def to_s
      "#{@platform} #{@availability_zone} #{@instance_type}"
    end

    def self.get_instances
      return @instances if @instances
      @instances = ec2.instances.map do |instance|
        next unless instance.status.to_s == 'running'
        new(instance)
      end.compact
      get_more_info
    end

    def self.get_reserved_instances
      return @reserved_instances if @reserved_instances
      @reserved_instances = ec2.reserved_instances.map do |ri|
        next unless ri.state == 'active'
        new(ri, ri.instance_count)
      end.compact
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
    private :platform_helper

    def self.get_more_info
      get_instances.each do |instance|
        tags = ec2.client.describe_tags(:filters => [{:name => "resource-id", :values => [instance.id]}])[:tag_set]
        tags = Hash[tags.map { |tag| [tag[:key], tag[:value]]}.compact]
        instance.name = tags["Name"]
        instance.stack_name = tags["opsworks:stack"]
      end
    end
    private_class_method :get_more_info

    def self.bucketize
      buckets = {}
      get_instances.map do |instance|
        name = instance.stack_name || instance.name
        buckets[name] = [] unless buckets.has_key? name
        buckets[name] << instance
      end
      buckets.sort_by{|k,v| k }
    end

  end
end