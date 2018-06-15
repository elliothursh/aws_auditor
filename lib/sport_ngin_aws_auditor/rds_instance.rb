module SportNginAwsAuditor
  class RDSInstance
    extend InstanceHelper

    class << self
      def get_instances(client=AWS.rds, tag_name=nil)
        account_id = AWS.get_account_id
        client.describe_db_instances.db_instances.map do |instance|
          next unless instance.db_instance_status.to_s == 'available'
          new(instance, account_id, tag_name, client)
        end.compact
      end

      def get_reserved_instances(client=AWS.rds)
        client.describe_reserved_db_instances.reserved_db_instances.map do |instance|
          next unless instance.state.to_s == 'active'
          new(instance)
        end.compact
      end

      def get_retired_reserved_instances(client)
        client.describe_reserved_db_instances.reserved_db_instances.map do |instance|
          next unless instance.state == 'retired'
          new(instance)
        end.compact
      end
    end

    attr_accessor :id, :name, :multi_az, :scope, :instance_type, :engine, :count, :tag_value, :tag_reason, :expiration_date, :availability_zone
    def initialize(rds_instance, account_id=nil, tag_name=nil, client=nil)
      if rds_instance.class.to_s == "Aws::RDS::Types::ReservedDBInstance"
        self.id = rds_instance.reserved_db_instances_offering_id
        self.scope = nil
        self.availability_zone = nil
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = engine_helper(rds_instance.product_description)
        self.count = rds_instance.db_instance_count
        self.expiration_date = rds_instance.start_time + rds_instance.duration if rds_instance.state == 'retired'
      elsif rds_instance.class.to_s == "Aws::RDS::Types::DBInstance"
        self.id = rds_instance.db_instance_identifier
        self.name = rds_instance.db_name
        self.scope = nil
        self.availability_zone = rds_instance.availability_zone
        self.multi_az = rds_instance.multi_az ? "Multi-AZ" : "Single-AZ"
        self.instance_type = rds_instance.db_instance_class
        self.engine = engine_helper(rds_instance.engine)
        self.count = 1

        if tag_name
          region = get_region
          arn = "arn:aws:rds:#{region}:#{account_id}:db:#{self.id}"

           # go through to see if the tag we're looking for is one of them
          client.list_tags_for_resource(resource_name: arn).tag_list.each do |tag|
            if tag.key == tag_name
              self.tag_value = tag.value
            elsif tag.key == 'no-reserved-instance-reason'
              self.tag_reason = tag.value
            end
          end
        end
      end
    end

    def to_s
      "#{engine} #{multi_az} #{instance_type}"
    end

    def get_region
      region = self.availability_zone.split(//)
      region.pop
      region = region.join
      region == "Multiple" ? "us-east-1" : region
    end

    def no_reserved_instance_tag_value
      tag_value
    end

    # Generates a name based on the RDS engine or product description
    def engine_helper(engine)
      case
      when engine.downcase.include?('aurora')
        'Aurora'
      when engine.downcase.include?('mariadb')
        'MariaDB'
      when engine.downcase.include?('mysql')
        'MySQL'
      when engine.downcase.include?('oracle-ee')
        'Oracle EE'
      when engine.downcase.include?('oracle-se1')
        'Oracle SE One'
      when engine.downcase.include?('oracle-se2')
        'Oracle SE Two'
      when engine.downcase.include?('oracle-se')
        'Oracle SE'
      when engine.downcase.include?('postgres')
        'PostgreSQL'
      when engine.downcase.include?('sqlserver-ee')
        'SQL Server EE'
      when engine.downcase.include?('sqlserver-ex')
        'SQL Server EX'
      when engine.downcase.include?('sqlserver-se')
        'SQL Server SE'
      when engine.downcase.include?('sqlserver-web')
        'SQL Server Web'
      else
        'Unknown DB Engine'
      end
    end
    private :engine_helper
  end
end
