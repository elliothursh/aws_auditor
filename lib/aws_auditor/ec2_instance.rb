require_relative './instance_helper'

module AwsAuditor
  class EC2Instance
    extend InstanceHelper
    extend EC2Wrapper

    class << self
      attr_accessor :instances, :reserved_instances
    end

    attr_accessor :id, :name, :platform, :availability_zone, :instance_type, :count, :stack_name
    def initialize(ec2_instance, reserved, count=1)
      if reserved
        self.id = ec2_instance.reserved_instances_id
        self.name = nil
        self.platform = platform_helper(ec2_instance, reserved)
        self.availability_zone = ec2_instance.availability_zone
        self.instance_type = ec2_instance.instance_type
        self.count = count
        self.stack_name = nil
      else
        self.id = ec2_instance.instance_id
        self.name = nil
        self.platform = platform_helper(ec2_instance, reserved)
        self.availability_zone = ec2_instance.placement.availability_zone
        self.instance_type = ec2_instance.instance_type
        self.count = count
        self.stack_name = nil
      end
    end

    def to_s
      "#{platform} #{availability_zone} #{instance_type}"
    end

    def self.get_instances
      return @instances if @instances
      @instances = ec2.describe_instances.reservations.map do |reservation|
        reservation.instances.map do |instance|
          next unless instance.state.name == 'running'
          new(instance, false)
        end.compact
      end.flatten.compact
      get_more_info
    end

    def self.get_reserved_instances
      return @reserved_instances if @reserved_instances
      @reserved_instances = ec2.describe_reserved_instances.reserved_instances.map do |ri|
        next unless ri.state == 'active'
        new(ri, true, ri.instance_count)
      end.compact
    end

    def platform_helper(ec2_instance, reserved)
      if !reserved
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
      elsif reserved
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
