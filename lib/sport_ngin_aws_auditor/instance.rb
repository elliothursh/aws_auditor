require_relative './instance_helper'

module SportNginAwsAuditor
  class Instance
    extend InstanceHelper

    attr_accessor :type, :count, :category, :tag_value, :reason, :name
    def initialize(type, data_array)
      if type.include?(" with tag")
        type = type.dup # because type is a frozen string right now
        type.slice!(" with tag")
        self.type = type
        self.category = "tagged"
        self.name = data_array[1] || nil
        self.reason = data_array[2] || nil
        self.tag_value = data_array[3] || nil
      else
        self.type = type

        if data_array[0] < 0
          self.category = "running"
        elsif data_array[0] == 0
          self.category = "matched"
        elsif data_array[0] > 0
          self.category = "reserved"
        end
      end

      self.count = data_array[0].abs
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
