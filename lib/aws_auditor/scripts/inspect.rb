module AwsAuditor
  module Scripts
    class Inspect
      extend AWSWrapper
      extend OpsWorksWrapper

      def self.execute(environment, options=nil)
        aws(environment)
        if options[:ec2]
          inspect_stacks
        elsif options[:rds]
          inspect_dbs
        elsif options[:cache]
          inspect_caches
        else
          puts "You must use a switch. See `aws-auditor inspect --help` for more info."
        end
      end

      def self.inspect_stacks
        Stack.all.each do |stack|
          stack.pretty_print
        end
      end

      def self.inspect_dbs
        RDSInstance.get_instances.each do |db|
          puts "========================"
          puts "#{db.name}"
          puts "========================"
          puts db.to_s
          puts "\n"
        end
      end

      def self.inspect_caches
        CacheInstance.get_instances.each do |cache|
          puts "========================"
          puts "#{cache.name}"
          puts "========================"
          puts cache.to_s
          puts "\n"
        end
      end

    end
  end
end