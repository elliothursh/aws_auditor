require 'highline/import'

module AwsAuditor
  class Stack
    extend OpsWorksWrapper
    extend EC2Wrapper

    class <<self
      attr_accessor :instances, :stacks
    end

    attr_accessor :id, :name, :instances
    def initialize(aws_stack)
      @id = aws_stack[:stack_id]
      @name = aws_stack[:name]
      @instances = get_instances.compact
    end

    def get_instances
      return @instances if @instances
      @instances = self.class.opsworks.describe_instances({stack_id: id})[:instances].map do |instance|
        next unless instance[:status].to_s == 'online'
        self.class.all_instances[instance[:ec2_instance_id]].stack_id = id
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
      return @stacks if @stacks 
      @stacks = opsworks.describe_stacks.data[:stacks].map do |stack|
        new(stack)
      end.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    end

    def self.all_instances
      @all_instances ||= EC2Instance.instance_hash
    end

    def self.instances_without_stack 
      all #simply getting all stacks to make sure instance stack_ids is set
      all_instances.map do |id, instance|
        next if instance.stack_id 
        instance
      end.compact
    end

  end
end

