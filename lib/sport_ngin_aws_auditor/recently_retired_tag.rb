require_relative './instance_helper'

module SportNginAwsAuditor
  class RecentlyRetiredTag

    attr_accessor :value, :instance_name
    def initialize(tag_value, instance_name)
      self.value = tag_value
      self.instance_name = instance_name
    end
  end
end
