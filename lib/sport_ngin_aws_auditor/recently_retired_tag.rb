require_relative './instance_helper'

module SportNginAwsAuditor
  class RecentlyRetiredTag

    attr_accessor :value, :instance_type, :instance_name, :reason
    def initialize(tag_value, instance_type, instance_name, reason=nil)
      self.value = tag_value
      self.instance_type = instance_type
      self.instance_name = instance_name
      self.reason = reason
    end
  end
end
