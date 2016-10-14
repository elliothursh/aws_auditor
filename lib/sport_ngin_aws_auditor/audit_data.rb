require_relative './instance_helper'

module SportNginAwsAuditor
  class AuditData

    attr_accessor :data, :retired_tags, :retired_ris, :selected_audit_type, :klass, :tag_name, :region
    def initialize(instances, reserved, class_type, tag_name)
      self.selected_audit_type = (!instances && !reserved) ? "all" : (instances ? "instances" : "reserved")
      self.klass = SportNginAwsAuditor.const_get(class_type)
      self.tag_name = tag_name
    end

    def instances?
      self.selected_audit_type == "instances"
    end

    def reserved?
      self.selected_audit_type == "reserved"
    end

    def all?
      self.selected_audit_type == "all"
    end

    def gather_data
      if instances?
        instance_hash, retired_tags = gather_instances_data
      elsif reserved?
        instance_hash = self.klass.instance_count_hash(self.klass.get_reserved_instances)
      elsif all?
        instance_hash, retired_tags, retired_ris = gather_all_data
      end

      compared_array = []
      instance_hash.each do |key, value|
        compared_array.push(Instance.new(key, value, self.region))
      end

      self.data = compared_array
      self.retired_ris = retired_ris
      self.retired_tags = retired_tags
    end

    def gather_instances_data
      instances = self.klass.get_instances(tag_name)
      gather_region(instances)
      retired_tags = self.klass.get_retired_tags(instances)
      instances_with_tag = self.klass.filter_instances_with_tags(instances)
      instances_without_tag = self.klass.filter_instance_without_tags(instances)
      instance_hash = self.klass.instance_count_hash(instances_without_tag)
      self.klass.add_instances_with_tag_to_hash(instances_with_tag, instance_hash)

      return instance_hash, retired_tags
    end

    def gather_all_data
      instances = self.klass.get_instances(tag_name)
      gather_region(instances)
      retired_tags = self.klass.get_retired_tags(instances)
      instance_hash = self.klass.compare(instances)
      retired_ris = self.klass.get_recent_retired_reserved_instances

      return instance_hash, retired_tags, retired_ris
    end

    def gather_region(instances)
      if self.klass == SportNginAwsAuditor.const_get('EC2Instance')
        match = instances.first.availability_zone.match(/(\w{2}-\w{4,})/)
        self.region = match[0] unless match.nil?
      end
    end
  end
end
