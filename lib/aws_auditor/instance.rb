module AwsAuditor
	class Instance

		attr_accessor :platform, :availability_zone, :instance_type, :count
		def initialize(aws_instance, count=1)
			@platform = platform_helper(aws_instance)
			@availability_zone = aws_instance.availability_zone
			@instance_type = aws_instance.instance_type
			@count = count
		end

		def to_s
			"#{@platform} #{@availability_zone} #{@instance_type}"
		end

		def platform_helper(aws_instance)
			if aws_instance.class.to_s == 'AWS::EC2::Instance'
				if aws_instance.vpc? 
					return 'VPC'
				elsif aws_instance.platform
					if aws_instance.platform.downcase.include? 'windows' 
						return 'Windows'
					else
						return 'Linux'
					end
				else
					return 'Linux'
				end
			elsif aws_instance.class.to_s == 'AWS::EC2::ReservedInstances'
				if aws_instance.product_description.downcase.include? 'vpc' 
					return 'VPC'
				elsif aws_instance.product_description.downcase.include? 'windows'
					return 'Windows'
				else
					return 'Linux'
				end
			end
		end

	end
end