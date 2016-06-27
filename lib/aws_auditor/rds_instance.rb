require_relative './instance_helper'

module AwsAuditor
  class RDSInstance
    extend InstanceHelper
    extend RDSWrapper
    extend AWSWrapper

    class << self
      attr_accessor :instances, :reserved_instances
    end

    attr_accessor :id, :name, :multi_az, :instance_type, :engine, :count, :tag_value
    def initialize(rds_instance, account_id=nil, tag_name=nil, rds=nil)
      if rds_instance.class.to_s == "Aws::RDS::Types::ReservedDBInstance"
        self.id = rds_instance.reserved_db_instances_offering_id
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = rds_instance.product_description
        self.count = 1
      elsif rds_instance.class.to_s == "Aws::RDS::Types::DBInstance"
        self.id = rds_instance.db_instance_identifier
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = rds_instance.engine
        self.count = 1

        if tag_name
          region = rds_instance.availability_zone.split(//).first(9).join
          region = "us-east-1" if region == "Multiple"
          arn = "arn:aws:rds:#{region}:#{account_id}:db:#{self.id}"

          rds.list_tags_for_resource(resource_name: arn).tag_list.each do |tag| # go through to see if the tag we're looking for is one of them
            if tag.key == tag_name
              self.tag_value = tag.value
            end
          end
        end
      end
    end

    def to_s
      "#{engine_helper} #{multi_az} #{instance_type}"
    end

    def self.get_instances(tag_name=nil)
      return @instances if @instances
      account_id = get_account_id
      @instances = rds.describe_db_instances.db_instances.map do |instance|
        next unless instance.db_instance_status.to_s == 'available'
        new(instance, account_id, tag_name, rds)
      end.compact
    end

    def self.get_reserved_instances
      return @reserved_instances if @reserved_instances
      @reserved_instances = rds.describe_reserved_db_instances.reserved_db_instances.map do |instance|
        next unless instance.state.to_s == 'active'
        new(instance)
      end.compact
    end

    def no_reserved_instance_tag_value
      @tag_value
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
