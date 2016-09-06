require 'highline/import'
require_relative "../notify_slack"
require_relative "../instance"

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

        cycle = [["EC2Instance", options[:ec2]],
                 ["RDSInstance", options[:rds]],
                 ["CacheInstance", options[:cache]]]

        if !slack
          print "Gathering info, please wait..."; print "\r"
        else
          puts "Condensed results from this audit will print into Slack instead of directly to an output."
        end

        cycle.each do |c|
          all_data = gather_data(c.first, tag_name) if (c.last || no_selection)
          data = all_data[0] unless all_data.nil?
          retired_tags = all_data[1] if (all_data.length >= 2 && !all_data.nil?)
          retired_ris = all_data[2] if (all_data.length >= 3 && !all_data.nil?)
          print_data(slack, environment, data, retired_ris, retired_tags, c.first) if (c.last || no_selection)
        end
      end

      def self.gather_data(class_type, tag_name)
        klass = SportNginAwsAuditor.const_get(class_type)

        if options[:instances]
          instances = klass.get_instances(tag_name)
          retired_tags = klass.get_retired_tags(instances)
          instances_with_tag = klass.filter_instances_with_tags(instances)
          instances_without_tag = klass.filter_instance_without_tags(instances)
          instance_hash = klass.instance_count_hash(instances_without_tag)
          klass.add_instances_with_tag_to_hash(instances_with_tag, instance_hash)
        elsif options[:reserved]
          instance_hash = klass.instance_count_hash(klass.get_reserved_instances)
        else
          instance_hash, retired_tags = klass.compare(tag_name)
          retired_ris = klass.get_recent_retired_reserved_instances
        end

        compared_array = []
        instance_hash.each do |key, value|
          compared_array.push(Instance.new(key, value))
        end

        [compared_array, retired_tags, retired_ris]
      end

      def self.print_data(slack, environment, data, retired_ris, retired_tags, class_type)
        data.sort_by! { |instance| [instance.type, instance.name] }

        if slack
          print_to_slack(data, retired_ris, retired_tags, class_type, environment)
        elsif options[:reserved] || options[:instances]
          puts header(class_type)
          data.each{ |instance| say "<%= color('#{instance.name}: #{instance.count}', :white) %>" }
        else
          puts header(class_type)
          data.each{ |instance| colorize(instance) }

          say_retired_ris(retired_ris, class_type, environment) unless retired_ris.empty?
          say_retired_tags(retired_tags, class_type, environment) unless retired_tags.empty?
        end
      end

      def self.say_retired_ris(retired_ris, class_type, environment)
        say "The following reserved #{class_type}Instances have recently expired in #{environment}:"
        retired_ris.each { |ri| say "#{ri.to_s} (#{ri.count}) on #{ri.expiration_date}" }
      end

      def self.say_retired_tags(retired_tags, class_type, environment)
        say "The following #{class_type}Instance tags have recently expired in #{environment}:"
        retired_tags.each { |name, value| say "#{name} on #{value}" }
      end

      def self.colorize(instance)
        name = instance.name
        count = instance.count
        color, rgb = color_chooser(instance)
        say "<%= color('#{name}: #{count}', :#{color}) %>"
      end

      def self.print_to_slack(instances_array, retired_ris, retired_tags, class_type, environment)
        discrepancy_array = []

        instances_array.each do |instance|
          unless instance.matched?
            discrepancy_array.push(instance)
          end
        end

        true_discrepancies = discrepancy_array.reject{ |instance| instance.tagged? }

        unless true_discrepancies.empty?
          print_discrepancies(discrepancy_array, retired_ris, retired_tags, class_type, environment)
        end
      end

      def self.print_discrepancies(discrepancy_array, retired_ris, retired_tags, class_type, environment)
        title = "Some #{class_type} discrepancies for #{environment} exist:\n"
        slack_instances = NotifySlack.new(title)

        discrepancy_array.each do |discrepancy|
          name = discrepancy.name
          count = discrepancy.count
          color, rgb = color_chooser(discrepancy)
          slack_instances.attachments.push({"color" => rgb, "text" => "#{name}: #{count}", "mrkdwn_in" => ["text"]})
        end

        slack_instances.perform

        print_retired_ris(retired_ris, class_type, environment) unless retired_ris.empty?
        print_retired_tags(retired_tags, class_type, environment) unless retired_tags.empty?
      end

      def self.print_retired_ris(retired_ris, class_type, environment)
        message = "The following reserved #{class_type}s have recently expired in #{environment}:\n"

        retired_ris.each do |ri|
          name = ri.to_s
          count = ri.count
          expiration_date = ri.expiration_date
          message << "*#{name}* (#{count}) on *#{expiration_date}*\n"
        end
          
        slack_retired_ris = NotifySlack.new(message)
        slack_retired_ris.perform
      end

      def self.print_retired_tags(retired_tags, class_type, environment)
        message = "The following #{class_type} tags have recently expired in #{environment}:\n"

        retired_tags.each do |name, value|
          message << "*#{name}* on *#{value}*\n"
        end

        slack_retired_tags = NotifySlack.new(message)
        slack_retired_tags.perform
      end

      def self.color_chooser(instance)
        if instance.tagged?
          return "blue", "#0000CC"
        elsif instance.running?
          return "yellow", "#FFD700"
        elsif instance.matched?
          return "green", "#32CD32"
        elsif instance.reserved?
          return "red", "#BF1616"
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
