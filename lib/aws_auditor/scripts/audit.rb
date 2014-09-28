require 'highline/import'

module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper

      def self.execute(environment, options=nil)
        aws(environment)
        if options[:ec2]
          audit_ec2(options)
        elsif options[:rds]
          audit_rds(options)
        elsif options[:cache]
          audit_cache(options)
        else
          audit_ec2(options)
          audit_rds(options)
          audit_cache(options)
        end

      end

      def self.audit_rds(options)
        puts "=============== RDS ==============="
        if options[:instances]
          RDSInstance.instance_count_hash(RDSInstance.get_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        elsif options[:reserved]
          RDSInstance.instance_count_hash(RDSInstance.get_reserved_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        else
          RDSInstance.compare.each do |key, value|
            colorize(key,value)
          end
        end
      end

      def self.audit_ec2(options)
        puts "=============== EC2 ==============="
        if options[:instances]
          EC2Instance.instance_count_hash(EC2Instance.get_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        elsif options[:reserved]
          EC2Instance.instance_count_hash(EC2Instance.get_reserved_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        else
          EC2Instance.compare.each do |key,value|
            colorize(key,value)
          end
        end
      end

      def self.audit_cache(options)
        puts "============== CACHE =============="
        if options[:instances]
          CacheInstance.instance_count_hash(CacheInstance.get_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        elsif options[:reserved]
          CacheInstance.instance_count_hash(CacheInstance.get_reserved_instances).each do |key,value|
            say "<%= color('#{key}: #{value}', :white) %>"
          end
        else
          CacheInstance.compare.each do |key,value|
            colorize(key,value)
          end
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