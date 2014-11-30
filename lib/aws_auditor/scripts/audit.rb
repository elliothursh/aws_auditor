require 'highline/import'

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class <<self
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
        if options[:instances]
          instances = klass.instance_count_hash(klass.get_instances)
          puts header(class_type)
          instances.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        elsif options[:reserved]
          reserved = klass.instance_count_hash(klass.get_reserved_instances)
          puts header(class_type)
          reserved.each{ |key,value| say "<%= color('#{key}: #{value}', :white) %>" }
        else
          compared = klass.compare
          puts header(class_type)
          compared.each{ |key,value| colorize(key,value) }
        end
      end

      def self.colorize(key,value)
        if value < 0
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