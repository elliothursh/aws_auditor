require_relative './instance_helper'
require_relative './convenience_wrappers'

module SportNginAwsAuditor
  class AuditData
    extend EC2Wrapper
    extend RDSWrapper
    extend CacheWrapper

    attr_accessor :data, :retired_tags, :retired_ris, :selected_audit_type, :klass, :tag_name, :region, :ignore_instances_regexes, :client
    def initialize(info)
      self.selected_audit_type = (!info[:instances] && !info[:reserved]) ? "all" : (info[:instances] ? "instances" : "reserved")
      self.klass = SportNginAwsAuditor.const_get(info[:class])
      self.tag_name = info[:tag_name]
      self.ignore_instances_regexes = info[:regexes]
      self.region = info[:region].match(/(\w{2}-\w{4,})/)[0] if info[:region].match(/(\w{2}-\w{4,})/)
      
      if info[:class] == "EC2Instance"
        self.client = EC2Wrapper.ec2(info[:region])
      elsif info[:class] == "RDSInstance"
        self.client = RDSWrapper.rds(info[:region])
      elsif info[:class] == "CacheInstance"
        self.client = CacheWrapper.cache(info[:region])
      end
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
        retired_ris = nil
      elsif reserved?
        instance_hash = self.klass.instance_count_hash(self.klass.get_reserved_instances(self.client))
        retired_tags, retired_ris = nil
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
      instances = self.klass.get_instances(self.client, tag_name)
      retired_tags = self.klass.get_retired_tags(instances)
      instances_with_tag = self.klass.filter_instances_with_tags(instances)
      instances_without_tag = self.klass.filter_instances_without_tags(instances)
      instance_hash = self.klass.instance_count_hash(instances_without_tag)
      self.klass.add_additional_instances_to_hash(instances_with_tag, instance_hash, " with tag (")

      return instance_hash, retired_tags
    end

    def gather_all_data
      instances = self.klass.get_instances(self.client, tag_name)
      retired_tags = self.klass.get_retired_tags(instances)
      instance_hash = self.klass.compare(instances, ignore_instances_regexes, self.client)
      retired_ris = self.klass.get_recent_retired_reserved_instances(self.client)

      return instance_hash, retired_tags, retired_ris
    end
  end
end
