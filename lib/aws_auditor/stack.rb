require 'highline/import'

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
        self.class.all_instances[instance[:ec2_instance_id]]
      end
    end

    def print_instances
      EC2Instance.instance_count_hash(self.instances).each do |key,value|
        say "<%= color('#{key}: #{value}', :white) %>"
      end
    end

    def pretty_print
      puts "----------------------------------"
      puts "#{@name}"
      puts "----------------------------------"
      print_instances
      puts "\n"
    end
    
    def self.all
      stacks = opsworks.describe_stacks
      stacks.data[:stacks].map do |stack|
        new(stack)
      end.sort! { |a,b| a.name.downcase <=> b.name.downcase } if stacks
    end

    def self.all_instances
      @all_instances ||= EC2Instance.instance_hash
    end

  end
end

