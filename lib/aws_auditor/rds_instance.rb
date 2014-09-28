require_relative './instance_helper'

module AwsAuditor
  class RDSInstance
    extend InstanceHelper
    extend RDSWrapper

    attr_accessor :id, :name, :multi_az, :instance_type, :engine, :count
    def initialize(rds_instance)
      @id = rds_instance[:db_instance_identifier] || rds_instance[:reserved_db_instances_offering_id]
      @name = rds_instance[:db_instance_identifier] || rds_instance[:db_name]
      @multi_az = rds_instance[:multi_az]
      @instance_type = rds_instance[:db_instance_class]
      @engine = rds_instance[:engine] || rds_instance[:product_description]
      @count = rds_instance[:db_instance_count] || 1
    end

    def to_s
      "#{engine_helper} #{multi_az?} #{instance_type}"
    end

    def multi_az?
      multi_az ? "Multi-AZ" : "Single-AZ"
    end

    def engine_helper
      if engine.downcase.include? "post"
        return "PostgreSQL"
      elsif engine.downcase.include? "mysql"
        return "MySQL"
      end
    end

    def self.get_instances
      instances = rds.describe_db_instances[:db_instances]
      instances.map do |instance|
        next unless instance[:db_instance_status].to_s == 'available'
        new(instance)
      end
    end

    def self.get_reserved_instances
      instances = rds.describe_reserved_db_instances[:reserved_db_instances]
      instances.map do |instance|
        next unless instance[:state].to_s == 'active'
        new(instance)
      end
    end

  end
end