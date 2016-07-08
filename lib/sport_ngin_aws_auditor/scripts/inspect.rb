module SportNginAwsAuditor
  module Scripts
    class Inspect
      extend AWSWrapper
      extend OpsWorksWrapper

      def self.execute(environment, options=nil, global_options=nil)
        aws(environment, global_options[:aws_roles])
        no_selection = options.values.uniq == [false]
        output("EC2Instance") if options[:ec2] || no_selection
        output("RDSInstance") if options[:rds] || no_selection 
        output("CacheInstance") if options[:cache] || no_selection
      end

      def self.output(class_type)
        klass = SportNginAwsAuditor.const_get(class_type)
        print "Gathering info, please wait..."; print "\r"
        instances = class_type == "EC2Instance" ? klass.bucketize : klass.instance_hash
        say "<%= color('#{header(class_type)}', :white) %>"
        instances.each do |key, value|
          pretty_print(key, klass.instance_count_hash(Array(value)))
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

      def self.pretty_print(title, body)
        puts "======================================="
        puts "#{title}"
        puts "======================================="
        body.each{ |key, value| say "<%= color('#{key}: #{value}', :white) %>" }
        puts "\n"
      end
    end
  end
end
