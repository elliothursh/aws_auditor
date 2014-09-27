module AwsAuditor
	class Instance
		extend EC2Wrapper

		attr_accessor :id, :platform, :availability_zone, :instance_type, :count
		def initialize(aws_instance, count=1)
			@id = aws_instance.id
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

		def self.get_instances
			instances = ec2.instances
			instances.map do |instance|
				next unless instance.status.to_s == 'running'
				Instance.new(instance)
			end if instances
		end

		def self.get_reserved_instances
			reserved_instances = ec2.reserved_instances
			reserved_instances.map do |ri|
				next unless ri.state == 'active'
				Instance.new(ri, ri.instance_count)
			end if reserved_instances
		end

		def self.instance_hash
			Hash[get_instances.map {|instance| [instance.id, instance]}]
		end
	end
end