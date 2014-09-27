require_relative './aws'

module AwsAuditor
	module AWSWrapper
		attr_accessor :aws

		def aws(environment)
			@aws ||= AwsAuditor::AWSSDK.configuration(environment)
		end
	end

	module EC2Wrapper
		attr_accessor :ec2

		def ec2
			@ec2 ||= AWS::EC2.new()
		end
	end

	
end