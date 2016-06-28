require 'highline/import'
require_relative "../notify_slack"

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class <<self
        attr_accessor :options
      end

      def self.execute(args_array, options=nil)
        aws(args_array.delete_at(0))
        slack = args_array.delete_at(0) == "slack=true"
        tag_name = args_array.delete_at(0) || "no-reserved-instance"
        @options = options
        no_selection = options.values.uniq == [false]
        # output("EC2Instance", tag_name) if options[:ec2] || no_selection
        # output("RDSInstance", tag_name) if options[:rds] || no_selection
        # output("CacheInstance", tag_name) if options[:cache] || no_selection
      end

      def self.output(class_type, slack)
        klass = AwsAuditor.const_get(class_type)
        print "Gathering info, please wait..."; print "\r" if !slack
        puts "The results from this will print into slack instead of directly to an output." if slack
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
          compared.each{ |key,value| colorize(key,value) } if !slack
          print_to_slack(compared) if slack
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

      def self.print_to_slack(instances_hash)
        discrepency_hash = Hash.new
        instances_hash.each do |key, value|
          if !(value == 0) && !(key.include?(" with tag"))
            discrepency_hash[:key] = value
          end
        end

        if discrepency_hash.empty?
          slack_job = NotifySlack.new("All reserved instances and running instances are up to date.")
          slack_job.perform
        else
          print_discrepencies.(discrepency_hash)
        end
      end

      def self.print_discrepencies(discrepency_hash)
        to_print = "Some reserved instances and running instances are out of sync:\n"

        discrepency_hash.each do |key, value|
          to_print << "#{key}: #{value}\n"
        end

        slack_job = NotifySlack.new("All reserved instances and running instances are up to date.")
        slack_job.perform
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
