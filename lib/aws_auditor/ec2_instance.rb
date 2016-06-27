require_relative './instance_helper'

module AwsAuditor
  class EC2Instance
    extend InstanceHelper
    extend EC2Wrapper

    class << self
      attr_accessor :instances, :reserved_instances
    end

    attr_accessor :id, :name, :platform, :availability_zone, :instance_type, :count, :stack_name, :tag_value
    def initialize(ec2_instance, tag_name, count=1)
      if ec2_instance.class.to_s == "Aws::EC2::Types::ReservedInstances"
        self.id = ec2_instance.reserved_instances_id
        self.name = nil
        self.platform = platform_helper(ec2_instance)
        self.availability_zone = ec2_instance.availability_zone
        self.instance_type = ec2_instance.instance_type
        self.count = count
        self.stack_name = nil
      elsif ec2_instance.class.to_s == "Aws::EC2::Types::Instance"
        self.id = ec2_instance.instance_id
        self.name = nil
        self.platform = platform_helper(ec2_instance)
        self.availability_zone = ec2_instance.placement.availability_zone
        self.instance_type = ec2_instance.instance_type
        self.count = count
        self.stack_name = nil

        if tag_name
          ec2_instance.tags.each do |tag| # go through to see if the tag we're looking for is one of them
            if tag.key == tag_name
              self.tag_value = tag.value
            end
          end
        end
      end
    end

    def to_s
      "#{platform} #{availability_zone} #{instance_type}"
    end

    def self.get_instances(tag_name=nil)
      return @instances if @instances
      @instances = ec2.describe_instances.reservations.map do |reservation|
        reservation.instances.map do |instance|
          next unless instance.state.name == 'running'
          new(instance, tag_name)
        end.compact
      end.flatten.compact
      get_more_info(tag_name)
    end

    def self.get_reserved_instances
      return @reserved_instances if @reserved_instances
      @reserved_instances = ec2.describe_reserved_instances.reserved_instances.map do |ri|
        next unless ri.state == 'active'
        new(ri, nil, ri.instance_count)
      end.compact
    end

    def no_reserved_instance_tag_value
      @tag_value
    end

    def platform_helper(ec2_instance)
      if ec2_instance.class.to_s == "Aws::EC2::Types::Instance"
        if ec2_instance.vpc_id
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
      elsif ec2_instance.class.to_s == "Aws::EC2::Types::ReservedInstances"
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

    def self.get_more_info(tag_name)
      get_instances(tag_name).each do |instance|
        tags = ec2.describe_tags(:filters => [{:name => "resource-id", :values => [instance.id]}]).tags
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
        if name
          buckets[name] = [] unless buckets.has_key? name
          buckets[name] << instance
        else
          puts "Could not sort #{instance.id}, as it has no stack_name or name"
        end
      end
      buckets.sort_by{|k,v| k }
    end

  end
end
