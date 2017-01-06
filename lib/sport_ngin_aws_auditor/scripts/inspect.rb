module SportNginAwsAuditor
  module Scripts
    class Inspect
      extend AWSWrapper
      extend OpsWorksWrapper
      extend EC2Wrapper
      extend RDSWrapper
      extend CacheWrapper

      def self.execute(environment, options=nil, global_options=nil)
        aws(environment, global_options)
        region = (global_options[:region].split(', ') if global_options[:region]) || 'us-east-1'
        no_selection = options.values.uniq == [false]
        output("EC2Instance", region) if options[:ec2] || no_selection
        output("RDSInstance", region) if options[:rds] || no_selection
        output("CacheInstance", region) if options[:cache] || no_selection
      end

      def self.output(class_type, region)
        klass = SportNginAwsAuditor.const_get(class_type)

        if class_type == "EC2Instance"
          client = EC2Wrapper.ec2(region)
        elsif class_type == "RDSInstance"
          client = RDSWrapper.rds(region)
        elsif class_type == "CacheInstance"
          client = CacheWrapper.cache(region)
        end

        print "Gathering info, please wait..."; print "\r"
        instances = class_type == "EC2Instance" ? klass.bucketize(client) : klass.instance_hash(client)
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
        body.each{ |key, value| say "<%= color('#{key}: #{value[:count]}', :white) %>" }
        puts "\n"
      end
    end
  end
end
