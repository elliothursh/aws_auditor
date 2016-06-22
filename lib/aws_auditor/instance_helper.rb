module AwsAuditor
	module InstanceHelper

		def instance_hash
      Hash[get_instances.map { |instance| instance.nil? ? next : [instance.id, instance]}.compact]
    end

    def reserved_instance_hash
      Hash[get_reserved_instances.map { |instance| instance.nil? ? next : [instance.id, instance]}.compact]
    end

    def instance_count_hash(instances)
      instance_hash = Hash.new()
      instances.each do |instance|
        next if instance.nil?
        instance_hash[instance.to_s] = instance_hash.has_key?(instance.to_s) ? instance_hash[instance.to_s] + instance.count : instance.count
      end if instances
      instance_hash
    end

    def add_instances_with_tag_to_hash(instances_to_add, instance_hash)
      instances_to_add.each do |instance|
        next if instance.nil?
        key = instance.to_s << " with tag"
        instance_hash[key] = instance_hash.has_key?(key) ? instance_hash[key] + instances_to_add.count : instances_to_add.count
      end if instances_to_add
      instance_hash
    end

    def compare
      differences = Hash.new()
      instances = get_instances
      # instances_with_tag = filter_instances_with_tags(instances).first
      # instances_without_tag = filter_instances_with_tags(instances).last
      # instance_hash = instance_count_hash(instances_without_tag)
      instance_hash = instance_count_hash(instances)
      # add_instances_with_tag_to_hash(instances_with_tag, instance_hash)
      ris = instance_count_hash(get_reserved_instances)
      instance_hash.keys.concat(ris.keys).uniq.each do |key|
        instance_count = instance_hash.has_key?(key) ? instance_hash[key] : 0
        ris_count = ris.has_key?(key) ? ris[key] : 0
        differences[key] = ris_count - instance_count
      end
      differences
    end

    def filter_instances_with_tags(instances)
      instances_with_tag = instances.select do |instance|
        # instance has tag && tag < Date.today
      end

      instances_without_tag = instances.select do |instance|
        # instance does not have tag || tag >= Date.today
      end

      [instances_with_tag, instances_without_tag]
    end
	end
end
