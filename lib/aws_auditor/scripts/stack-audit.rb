module AwsAuditor
  module Scripts
    class StackAudit
      extend AWSWrapper
      extend EC2Wrapper
      extend OpsWorksWrapper

      def self.execute(environment)
        aws(environment)
        get_stacks
      end

      def self.get_stacks
        stacks = opsworks.describe_stacks
        stacks.data[:stacks].map do |stack|
          stck = Stack.new(stack)
          stck.pretty_print
          stck
        end if stacks
      end

    end
  end
end