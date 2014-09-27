module AwsAuditor
  module Scripts
    class Audit
      extend AWSWrapper
      extend EC2Wrapper

      def self.execute(environment)
        aws(environment)
        compare.each do |key,value|
          puts "#{key}: #{value}"
        end
      end

      def self.create_instance_hash(instance_type)
        instance_hash = Hash.new()
        instance_type.each do |instance|
          next if instance.nil?
          instance_hash[instance.to_s] = instance_hash.has_key?(instance.to_s) ? instance_hash[instance.to_s] + instance.count : instance.count
        end
        instance_hash
      end

      def self.compare
        differences = Hash.new()
        instances = create_instance_hash(Instance.get_instances)
        ris = create_instance_hash(Instance.get_reserved_instances)
        instances.keys.concat(ris.keys).uniq.each do |key|
          instance_count = instances.has_key?(key) ? instances[key] : 0
          ris_count = ris.has_key?(key) ? ris[key] : 0
          differences[key] = ris_count - instance_count
        end
        differences
      end
    end
  end
end