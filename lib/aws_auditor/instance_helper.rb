module AwsAuditor
	module InstanceHelper

		def instance_hash
      Hash[get_instances.map { |instance| instance.nil? ? next : [instance.id, instance]}.compact]
    end

    def instance_count_hash(instances)
      instance_hash = Hash.new()
      instances.each do |instance|
        next if instance.nil?
        instance_hash[instance.to_s] = instance_hash.has_key?(instance.to_s) ? instance_hash[instance.to_s] + instance.count : instance.count
      end if instances
      instance_hash
    end

    def compare
      differences = Hash.new()
      instances = instance_count_hash(get_instances)
      ris = instance_count_hash(get_reserved_instances)
      instances.keys.concat(ris.keys).uniq.each do |key|
        instance_count = instances.has_key?(key) ? instances[key] : 0
        ris_count = ris.has_key?(key) ? ris[key] : 0
        differences[key] = ris_count - instance_count
      end
      differences
    end
	end
end