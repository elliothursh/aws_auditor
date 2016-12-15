require 'highline/import'
require 'colorize'
require_relative "../notify_slack"
require_relative "../instance"
require_relative "../audit_data"

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

        ignore_instances_regexes = []
        if options[:ignore_instances_patterns]
          ignore_instances_patterns = options[:ignore_instances_patterns].split(', ')
          ignore_instances_patterns.each do |r|
            ignore_instances_regexes << Regexp.new(r)
          end
        end
        
        zone_output = options[:zone_output]

        cycle = [["EC2Instance", options[:ec2]],
                 ["RDSInstance", options[:rds]],
                 ["CacheInstance", options[:cache]]]

        if !slack
          print "Gathering info, please wait..."; print "\r"
        else
          puts "Condensed results from this audit will print into Slack instead of directly to an output."
        end

        cycle.each do |c|
          audit_results = AuditData.new(options[:instances], options[:reserved], c.first, tag_name, ignore_instances_regexes)
          audit_results.gather_data
          output_options = {:slack => slack, :class_type => c.first,
                            :environment => environment, :zone_output => zone_output}
          print_data(audit_results, output_options) if (c.last || no_selection)
        end
      end

      def self.print_data(audit_results, output_options)
        audit_results.data.sort_by! { |instance| [instance.category, instance.type] }

        if output_options[:slack]
          print_to_slack(audit_results, output_options)
        elsif options[:reserved] || options[:instances]
          puts header(output_options[:class_type])
          audit_results.data.each{ |instance| say "<%= color('#{instance.type}: #{instance.count}', :white) %>" }
        else
          puts header(output_options[:class_type])
          audit_results.data.each{ |instance| colorize(instance, output_options[:zone_output]) }

          say_retired_ris(audit_results, output_options) unless audit_results.retired_ris.empty?
          say_retired_tags(audit_results, output_options) unless audit_results.retired_tags.empty?
        end
      end

      def self.say_retired_ris(audit_results, output_options)
        retired_ris = audit_results.retired_ris
        say "The following reserved #{output_options[:class_type]}Instances have recently expired in #{output_options[:environment]}:"
        retired_ris.each do |ri|
          if ri.availability_zone.nil?
            # if ri.to_s = 'Linux VPC  t2.small'...
            my_match = ri.to_s.match(/(\w*\s*\w*\s{1})\s*(\s*\S*)/)

            # then platform = 'Linux VPC '...
            platform = my_match[1] if my_match

            # and size = 't2.small'
            size = my_match[2] if my_match

            n = platform << audit_results.region << ' ' << size
            say "#{n} (#{ri.count}) on #{ri.expiration_date}"
          else
            say "#{ri.to_s} (#{ri.count}) on #{ri.expiration_date}"
          end
        end
      end

      def self.say_retired_tags(audit_results, output_options)
        retired_tags = audit_results.retired_tags
        say "The following #{output_options[:class_type]}Instance tags have recently expired in #{output_options[:environment]}:"
        retired_tags.each do |tag|
          if tag.reason
            say "#{tag.instance_name} (#{tag.instance_type}) retired on #{tag.value} because of #{tag.reason}"
          else
            say "#{tag.instance_name} (#{tag.instance_type}) retired on #{tag.value}"
          end
        end
      end

      def self.colorize(instance, zone_output=nil)
        name = !zone_output && (instance.tagged? || instance.running?) ? print_without_zone(instance.type) : instance.type
        count = instance.count
        color, rgb, prefix = color_chooser(instance)
        
        if instance.tagged?
          if instance.reason
            puts "#{prefix} #{name}: (expiring on #{instance.tag_value} because of #{instance.reason})".blue
          else
            say "<%= color('#{prefix} #{name}: (expiring on #{instance.tag_value})', :#{color}) %>"
          end
        elsif instance.ignored?
          say "<%= color('#{prefix} #{name}', :#{color}) %>"
        else
          say "<%= color('#{prefix} #{name}: #{count}', :#{color}) %>"
        end
      end

      def self.print_to_slack(audit_results, output_options)
        discrepancy_array = []
        tagged_ignored_array = []

        audit_results.data.each do |instance|
          unless instance.matched? || instance.tagged? || instance.ignored?
            discrepancy_array.push(instance)
          end
        end

        unless discrepancy_array.empty?
          print_discrepancies(discrepancy_array, output_options)
        end

       audit_results.data.each do |instance|
          if instance.tagged? || instance.ignored?
            tagged_ignored_array.push(instance)
          end
        end

        unless tagged_ignored_array.empty?
          print_tagged(tagged_ignored_array, output_options)
        end

        print_retired_ris(audit_results, output_options) unless audit_results.retired_ris.empty?
        print_retired_tags(audit_results, output_options) unless audit_results.retired_tags.empty?
      end

      def self.print_discrepancies(discrepancy_array, output_options)
        title = "Some #{output_options[:class_type]} discrepancies for #{output_options[:environment]} exist:\n"
        slack_instances = NotifySlack.new(title, options[:config_json])

        discrepancy_array.each do |discrepancy|
          type = !output_options[:zone_output] && discrepancy.running? ? print_without_zone(discrepancy.type) : discrepancy.type
          count = discrepancy.count
          color, rgb, prefix = color_chooser(discrepancy)

          unless discrepancy.tagged?
            text = "#{prefix} #{type}: #{count}"
            slack_instances.attachments.push({"color" => rgb, "text" => text, "mrkdwn_in" => ["text"]})
          end
        end

        slack_instances.perform        
      end

      def self.print_tagged(tagged_ignored_array, output_options)
        title = "There are currently some tagged #{output_options[:class_type]}s in #{output_options[:environment]}:\n"
        slack_instances = NotifySlack.new(title, options[:config_json])

        tagged_ignored_array.each do |tagged_or_ignored|
          type = output_options[:zone_output] ? tagged_or_ignored.type : print_without_zone(tagged_or_ignored.type)
          count = tagged_or_ignored.count
          color, rgb, prefix = color_chooser(tagged_or_ignored)
          
          if tagged_or_ignored.tagged?
            if tagged_or_ignored.reason
              text = "#{prefix} #{tagged_or_ignored.name}: (expiring on #{tagged_or_ignored.tag_value} because of #{tagged_or_ignored.reason})"
            else
              text = "#{prefix} #{tagged_or_ignored.name}: (expiring on #{tagged_or_ignored.tag_value})"
            end
          elsif tagged_or_ignored.ignored?
            text = "#{prefix} #{tagged_or_ignored.name}"
          end

          slack_instances.attachments.push({"color" => rgb, "text" => text, "mrkdwn_in" => ["text"]})
        end

        slack_instances.perform
      end

      def self.print_retired_ris(audit_results, output_options)
        retired_ris = audit_results.retired_ris
        message = "The following reserved #{output_options[:class_type]}s have recently expired in #{output_options[:environment]}:\n"

        retired_ris.each do |ri|
          if ri.availability_zone.nil?
            # if ri.to_s = 'Linux VPC  t2.small'...
            my_match = ri.to_s.match(/(\w*\s*\w*\s{1})\s*(\s*\S*)/)

            # then platform = 'Linux VPC '...
            platform = my_match[1] if my_match

            # and size = 't2.small'
            size = my_match[2] if my_match

            name = platform << audit_results.region << ' ' << size
          else
            name = ri.to_s
          end
          
          count = ri.count
          expiration_date = ri.expiration_date
          message << "*#{name}* (#{count}) on *#{expiration_date}*\n"
        end
          
        slack_retired_ris = NotifySlack.new(message, options[:config_json])
        slack_retired_ris.perform
      end

      def self.print_retired_tags(audit_results, output_options)
        retired_tags = audit_results.retired_tags
        message = "The following #{output_options[:class_type]} tags have recently expired in #{output_options[:environment]}:\n"

        retired_tags.each do |tag|
          if tag.reason
            message << "*#{tag.instance_name}* (#{tag.instance_type}) retired on *#{tag.value}* because of #{tag.reason}\n"
          else
            message << "*#{tag.instance_name}* (#{tag.instance_type}) retired on *#{tag.value}*\n"
          end
        end

        slack_retired_tags = NotifySlack.new(message, options[:config_json])
        slack_retired_tags.perform
      end

      def self.print_without_zone(type)
        type.sub(/(-\d\w)/, '')
      end

      def self.color_chooser(instance)
        if instance.tagged?
          return "blue", "#0000CC", "TAGGED -"
        elsif instance.ignored?
          return "blue", "#0000CC", "IGNORED -"
        elsif instance.running?
          return "yellow", "#FFD700", "MISSING RI -"
        elsif instance.matched?
          return "green", "#32CD32", "MATCHED RI -"
        elsif instance.reserved?
          return "red", "#BF1616", "UNUSED RI -"
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
