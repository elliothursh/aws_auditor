require 'highline/import'

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      def self.execute(environment, options=nil)
        aws(environment)
        if options[:ec2]
          puts "=============== EC2 ==============="
          audit_ec2
        elsif options[:rds]
          puts "=============== RDS ==============="
          audit_rds
        elsif options[:cache]
          puts "============== CACHE =============="
          audit_cache
        else
          puts "=============== EC2 ==============="
          audit_ec2
          puts "=============== RDS ==============="
          audit_rds
          puts "============== CACHE =============="
          audit_cache
        end

      end

      def self.audit_rds
        RDSInstance.compare.each do |key, value|
          colorize(key,value)
        end
      end

      def self.audit_ec2
        EC2Instance.compare.each do |key,value|
          colorize(key,value)
        end
      end

      def self.audit_cache
        CacheInstance.compare.each do |key,value|
          colorize(key,value)
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

    end
  end
end