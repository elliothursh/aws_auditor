require 'highline/import'

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class << self
        attr_accessor :options
      end

      def self.execute(environment, options=nil)
        aws(environment)
        @options = options
        no_selection = options.values.uniq == [false]
        output("EC2Instance") if options[:ec2] || no_selection
        output("RDSInstance") if options[:rds] || no_selection 
        output("CacheInstance") if options[:cache] || no_selection
      end

      def self.output(class_type)
        klass = AwsAuditor.const_get(class_type)
        print "Gathering info, please wait..."; print "\r"
        if options[:instances] # logic here for when we only want to get instances
          instances = klass.get_instances
          # instances_with_tag = klass.filter_instances_with_tags(instances).first
          # instances_without_tag = klass.filter_instances_with_tags(instances).last
          # instances_hash = klass.instance_count_hash(instances_without_tag)
          instance_hash = klass.instance_count_hash(instances)
          # add_instances_with_tag_to_hash(instances_with_tag, instances_hash)
          puts header(class_type)
          puts "options[:instances]"
          instance_hash.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        elsif options[:reserved] # reserved won't have any tags that we care about
          reserved = klass.instance_count_hash(klass.get_reserved_instances)
          puts header(class_type)
          puts "options[:reserved]"
          reserved.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        else # for when we want both instances and reserved; we need logic
          compared = klass.compare
          puts header(class_type)
          compared.each{ |key,value| colorize(key,value) }
        end
      end

      def self.colorize(key,value)
        if key.include?(" with tag")
          k = key.dup # because key is a frozen string right now
          k.slice!(" with tag")
          say "<%= color('#{k}: #{"*" << value.to_s}', :blue) %>"
        elsif value < 0
          say "<%= color('#{key}: #{value}', :yellow) %>"
        elsif value == 0
          say "<%= color('#{key}: #{value}', :green) %>"
        elsif value > 0 
          say "<%= color('#{key}: #{value}', :red) %>"
        end
      end

      def self.header(type, length = 50)
        type.upcase!.slice! "INSTANCE"
        half_length = (length - type.length)/2.0 - 1
        [
          "*" * length,
          "*" * half_length.floor + " #{type} " + "*" * half_length.ceil,
          "*" * length
        ].join("\n")
      end

    end
  end
end
