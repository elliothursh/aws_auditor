require_relative './instance_helper'

module SportNginAwsAuditor
  class Instance
    extend InstanceHelper

    attr_accessor :type, :count, :category, :tag_value, :reason, :name, :region_based
    def initialize(type, data_array, region)
      if type.include?(" with tag")
        type = type.dup # because type is a frozen string right now
        type.slice!(" with tag")
        self.type = type
        self.category = "tagged"
        self.name = data_array[1] || nil
        self.reason = data_array[2] || nil
        self.tag_value = data_array[3] || nil
        self.region_based = false
      else
        self.region_based = data_array[1] || nil

        if data_array[0] < 0
          self.category = "running"
        elsif data_array[0] == 0
          self.category = "matched"
        elsif data_array[0] > 0
          self.category = "reserved"
        end

        if region_based?
          my_match = type.match(/(\w*\s*\w*\s{1})\s*(\s*\S*)/)
          part1 = my_match[1] if my_match
          part2 = my_match[2] if my_match

          self.type = part1 << region << ' ' << part2
        else
          self.type = type
        end
      end

      self.count = data_array[0].abs
    end

    def region_based?
      self.region_based
    end

    def tagged?
      self.category == "tagged"
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
