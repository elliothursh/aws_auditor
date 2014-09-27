module AwsAuditor
	class Stack
		extend OpsWorksWrapper
		extend EC2Wrapper

		attr_accessor :id, :name, :instances
		def initialize(aws_stack)
			@id = aws_stack[:stack_id]
			@name = aws_stack[:name]
			@instances = get_instances.compact
		end

		def get_instances
			instances = self.class.opsworks.describe_instances({stack_id: id})[:instances]
			instances.map do |instance|
				next unless instance[:status].to_s == 'online'
				all_instances[instance[:ec2_instance_id]].to_s
			end
		end

		def pretty_print
			puts "----------------------------------"
			puts "#{@name}"
			puts "----------------------------------"
			instances.each do |instance|
				puts instance.to_s
			end
			puts "\n"
		end

		def all_instances
			@all_instances ||= Instance.instance_hash
		end

	end
end

