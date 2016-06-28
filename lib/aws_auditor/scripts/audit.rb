require 'highline/import'
require_relative "../notify_slack"

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class << self
        attr_accessor :options
      end

      def self.execute(args_array, options=nil)
        environment = args_array.delete_at(0)
        aws(environment)
        slack = args_array.delete_at(0) == "slack=true"
        tag_name = args_array.delete_at(0) || "no-reserved-instance"
        @options = options
        no_selection = options.values.uniq == [false]
        puts "Condensed results from this audit will print into Slack instead of directly to an output." if slack
        output("EC2Instance", tag_name, slack, environment) if options[:ec2] || no_selection
        output("RDSInstance", tag_name, slack, environment) if options[:rds] || no_selection
        output("CacheInstance", tag_name, slack, environment) if options[:cache] || no_selection
      end

      def self.output(class_type, tag_name, slack, environment)
        klass = AwsAuditor.const_get(class_type)

        if !slack
          print "Gathering info, please wait..."; print "\r"
        end

        if options[:instances]
          date = klass.get_todays_date
          instances = klass.get_instances(tag_name)
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

          if slack
            print_to_slack(compared, class_type, environment)
          else
            puts header(class_type)
            compared.each{ |key,value| colorize(key,value) }
          end
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

      def self.print_to_slack(instances_hash, class_type, environment)
        discrepency_hash = Hash.new
        instances_hash.each do |key, value|
          if !(value == 0) && !(key.include?(" with tag"))
            discrepency_hash[key] = value
          end
        end

        if discrepency_hash.empty?
          slack_job = NotifySlack.new("All #{class_type} reserved instances and running instances for #{environment} are up to date.")
          slack_job.perform
        else
          print_discrepencies(discrepency_hash, class_type, environment)
        end
      end

      def self.print_discrepencies(discrepency_hash, class_type, environment)
        to_print = "Some #{class_type} reserved instances and running instances for #{environment} are out of sync:\n"
        to_print << "#{header(class_type)}\n"

        discrepency_hash.each do |key, value|
          to_print << "#{key}: #{value}\n"
        end

        slack_job = NotifySlack.new(to_print)
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
