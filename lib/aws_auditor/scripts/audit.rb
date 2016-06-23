require 'highline/import'

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class << self
        attr_accessor :options
      end

      def self.execute(args_array, options=nil)
        aws(args_array.delete_at(0))
        tag_name = args_array.delete_at(0) || "no-reserved-instance"
        @options = options
        no_selection = options.values.uniq == [false]
        output("EC2Instance", tag_name) if options[:ec2] || no_selection
        # output("RDSInstance") if options[:rds] || no_selection 
        # output("CacheInstance") if options[:cache] || no_selection
      end

      def self.output(class_type, tag_name)
        klass = AwsAuditor.const_get(class_type)
        print "Gathering info, please wait..."; print "\r"
        if options[:instances]
          date = klass.get_todays_date
          instances = klass.get_instances
          instances_with_tag = klass.filter_instances_with_tags(instances, date).first
          instances_without_tag = klass.filter_instances_with_tags(instances, date).last
          instance_hash = klass.instance_count_hash(instances_without_tag)
          klass.add_instances_with_tag_to_hash(instances_with_tag, instance_hash)
          puts header(class_type)
          instance_hash.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        elsif options[:reserved]
          reserved = klass.instance_count_hash(klass.get_reserved_instances)
          puts header(class_type)
          reserved.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        else
          compared = klass.compare(tag_name)
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
