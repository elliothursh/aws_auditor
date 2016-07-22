require 'highline/import'
require_relative "../notify_slack"

module SportNginAwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      class << self
        attr_accessor :options
      end

      def self.execute(environment, options=nil, global_options=nil)
        aws(environment, global_options[:aws_roles])
        @options = options
        slack = options[:slack]
        no_selection = !(options[:ec2] || options[:rds] || options[:cache])

        if options[:no_tag]
          tag_name = nil
        else
          tag_name = options[:tag]
        end

        if !slack
          print "Gathering info, please wait..."; print "\r"
        else
          puts "Condensed results from this audit will print into Slack instead of directly to an output."
        end

        data = gather_data("EC2Instance", tag_name) if options[:ec2] || no_selection
        print_data(slack, environment, data, "EC2Instance") if options[:ec2] || no_selection

        data = gather_data("RDSInstance", tag_name) if options[:rds] || no_selection
        print_data(slack, environment, data, "RDSInstance") if options[:rds] || no_selection

        data = gather_data("CacheInstance", tag_name) if options[:cache] || no_selection
        print_data(slack, environment, data, "CacheInstance") if options[:cache] || no_selection
      end

      def self.gather_data(class_type, tag_name)
        klass = SportNginAwsAuditor.const_get(class_type)

        if options[:instances]
          instances = klass.get_instances(tag_name)
          instances_with_tag = klass.filter_instances_with_tags(instances)
          instances_without_tag = klass.filter_instance_without_tags(instances)
          instance_hash = klass.instance_count_hash(instances_without_tag)
          klass.add_instances_with_tag_to_hash(instances_with_tag, instance_hash)
          return instance_hash
        elsif options[:reserved]
          return klass.instance_count_hash(klass.get_reserved_instances)
        else
          return klass.compare(tag_name)
        end
      end

      def self.print_data(slack, environment, data, class_type)
        updated_data = modify_data(data)

        if slack
          print_to_slack(updated_data, class_type, environment)
        elsif options[:reserved] || options[:instances]
          puts header(class_type)
          updated_data.each{ |key, value| say "<%= color('#{key}: #{value}', :white) %>" }
        else
          puts header(class_type)
          updated_data.each{ |key, value| colorize(key, value) }
        end
      end

      def self.modify_data(data)
        updated_data = []
        data.each do |key, value|
          if key.include?(" with tag")
            k, v = modify_tag_prints(key, value)
            updated_data.push([k, v])
          else
            if value > 0
              value = '+' << value.to_s
            end
            updated_data.push([key, value.to_s])
          end
        end

        return updated_data.sort_by { |key, value| [value, key] }
      end

      def self.colorize(key, value)
        if value.include?("*")
          say "<%= color('#{key}: #{value}', :blue) %>"
        elsif value.include?("-")
          say "<%= color('#{key}: #{value}', :yellow) %>"
        elsif value == "0"
          say "<%= color('#{key}: #{value}', :green) %>"
        elsif value.include?("+")
          say "<%= color('#{key}: #{value}', :red) %>"
        end
      end

      def self.print_to_slack(instances_array, class_type, environment)
        discrepancy_array = []
        instances_array.each do |key, value|
          if value != "0"
            discrepancy_array.push([key, value])
          end
        end

        true_discrepancies = discrepancy_array.select{ |key, value| !value.include?("*")}

        unless true_discrepancies.empty?
          print_discrepancies(discrepancy_array, class_type, environment)
        end
      end

      def self.print_discrepancies(discrepancy_array, class_type, environment)
        title = "Some #{class_type} discrepancies for #{environment} exist:\n"
        slack_job = NotifySlack.new(title)

        discrepancy_array.each do |key, value|
          color = "#FFFFFF"
          if value[0] == "+"
            color = "#BF1616"
          elsif value[0] == "-"
            color = "#FFD700"
          elsif value[0] == "*"
            color = "#0000CC"
          end
          slack_job.attachments.push({"color" => color, "text" => "#{key}: #{value}", "mrkdwn_in" => ["text"]})
        end

        slack_job.perform
      end

      def self.modify_tag_prints(key, value)
        key = key.dup # because key is a frozen string right now
        key.slice!(" with tag")
        return key, "*" << value.to_s
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
