require_relative './instance_helper'

module AwsAuditor
  class RDSInstance
    extend InstanceHelper
    extend RDSWrapper

    class << self
      attr_accessor :instances, :reserved_instances
    end

<<<<<<< HEAD
    attr_accessor :id, :name, :multi_az, :instance_type, :engine, :count, :tag_value
    def initialize(rds_instance)
      @id = rds_instance[:db_instance_identifier] || rds_instance[:reserved_db_instances_offering_id]
      @name = rds_instance[:db_instance_identifier] || rds_instance[:db_name]
      @multi_az = rds_instance[:multi_az] ? "Multi-AZ" : "Single-AZ"
      @instance_type = rds_instance[:db_instance_class]
      @engine = rds_instance[:engine] || rds_instance[:product_description]
      @count = rds_instance[:db_instance_count] || 1
=======
    attr_accessor :id, :name, :multi_az, :instance_type, :engine, :count
    def initialize(rds_instance, reserved)
      if reserved
        self.id = rds_instance.reserved_db_instances_offering_id
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = rds_instance.product_description
        self.count = 1
      else
        self.id = rds_instance.db_instance_identifier
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = rds_instance.engine
        self.count = 1
      end
>>>>>>> updating-aws-sdk-v2
    end

    def to_s
      "#{engine_helper} #{multi_az} #{instance_type}"
    end

    def self.get_instances(tag_name)
      return @instances if @instances
      @instances = rds.describe_db_instances.db_instances.map do |instance|
        next unless instance.db_instance_status.to_s == 'available'
        new(instance, false)
      end.compact
    end

    def no_reserved_instance_tag_value
      @tag_value
    end

    def self.get_reserved_instances(tag_name)
      return @reserved_instances if @reserved_instances
      @reserved_instances = rds.describe_reserved_db_instances.reserved_db_instances.map do |instance|
        next unless instance.state.to_s == 'active'
        new(instance, true)
      end.compact
    end

    def engine_helper
      if engine.downcase.include? "post"
        return "PostgreSQL"
      elsif engine.downcase.include? "mysql"
        return "MySQL"
      end
    end
    private :engine_helper

  end
end
