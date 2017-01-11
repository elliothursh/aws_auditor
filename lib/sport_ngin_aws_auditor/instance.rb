require_relative './instance_helper'

module SportNginAwsAuditor
  class Instance
    extend InstanceHelper

    attr_accessor :type, :count, :category, :tag_value, :reason, :name, :region_based, :replaced
    def initialize(type, data_hash, region, category=nil, count=nil)
      if category && count
        self.type = type
        self.category = category
        self.count = count
      else
        if type.include?(" with tag")
          gather_tagged_data(type, data_hash, region)
        elsif type.include?(" ignored")
          gather_ignored_data(type, data_hash, region)
        else
          gather_normal_data(type, data_hash, region)
        end

        self.count = data_hash[:count].abs
        self.replaced = false
      end
    end

    def gather_tagged_data(type, data_hash, region)
      type = type.dup # because type is a frozen string right now
      type.slice!(" with tag")
      self.type = type
      self.category = "tagged"
      self.name = data_hash[:name] || nil
      self.reason = data_hash[:tag_reason] || nil
      self.tag_value = data_hash[:tag_value] || nil
      self.region_based = data_hash[:region_based] || nil
    end

    def gather_ignored_data(type, data_hash, region)
      type = type.dup
      type.slice!(" ignored")
      self.type = type
      self.category = "ignored"
      self.name = data_hash[:name] || nil
      self.region_based = data_hash[:region_based] || nil
    end

    def gather_normal_data(type, data_hash, region)
      self.region_based = data_hash[:region_based] || nil

      if data_hash[:count] < 0
        self.category = "running"
      elsif data_hash[:count] == 0
        self.category = "matched"
      elsif data_hash[:count] > 0
        self.category = "reserved"
      end

      if region_based?
        # if type = 'Linux VPC  t2.small'...
        my_match = type.match(/(\w*\s*\w*\s{1})\s*(\s*\S*)/)

        # then platform = 'Linux VPC '...
        platform = my_match[1] if my_match

        # and size = 't2.small'
        size = my_match[2] if my_match

        self.type = platform << region << ' ' << size
      else
        self.type = type
      end
    end

    def region_based?
      self.region_based
    end

    def tagged?
      self.category == "tagged"
    end

    def ignored?
      self.category == "ignored"
    end

    def reserved?
      self.category == "reserved"
    end

    def running?
      self.category == "running"
    end

    def matched?
      self.category == "matched"
    end
  end
end
