require_relative './instance_helper'

module SportNginAwsAuditor
  class Instance
    extend InstanceHelper

    attr_accessor :name, :count, :type
    def initialize(name, count)
      if name.include?(" with tag")
        name = name.dup # because name is a frozen string right now
        name.slice!(" with tag")
        self.name = name
        self.type = "tagged"
      else
        self.name = name
        if count < 0
          self.type = "running"
        elsif count == 0
          self.type = "matched"
        elsif count > 0 
          self.type = "reserved"
        end
      end

      self.count = count.abs
    end

    def tagged?
      self.type == "tagged"
    end

    def reserved?
      self.type == "reserved"
    end

    def running?
      self.type == "running"
    end

    def matched?
      self.type == "matched"
    end
  end
end
