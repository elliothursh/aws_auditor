module SportNginAwsAuditor
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
        instance_hash[key] = instance_hash.has_key?(key) ? instance_hash[key] + 1 : 1
      end if instances_to_add
      instance_hash
    end

    def compare(tag_name)
      puts "comparing"
      differences = Hash.new()
      instances = get_instances(tag_name)
      instances_with_tag = filter_instances_with_tags(instances)
      instances_without_tag = filter_instance_without_tags(instances)
      instance_hash = instance_count_hash(instances_without_tag)
      ris = instance_count_hash(get_reserved_instances)
      
      instance_hash.keys.concat(ris.keys).uniq.each do |key|
        instance_count = instance_hash.has_key?(key) ? instance_hash[key] : 0
        ris_count = ris.has_key?(key) ? ris[key] : 0
        differences[key] = ris_count - instance_count
      end
      
      add_instances_with_tag_to_hash(instances_with_tag, differences)
      differences
    end

    # assuming the value of the tag is in the form: 01/01/2000 like a date
    def filter_instances_with_tags(instances)
      instances.select do |instance|
        value = gather_instance_tag_date(instance)
        value && (Date.today.to_s < value.to_s)
      end
    end

    # assuming the value of the tag is in the form: 01/01/2000 like a date
    def filter_instance_without_tags(instances)
      instances.select do |instance|
        value = gather_instance_tag_date(instance)
        value.nil? || (Date.today.to_s >= value.to_s)
      end
    end

    def gather_instance_tag_date(instance)
      value = instance.no_reserved_instance_tag_value
      unless value.nil?
        date_hash = Date._strptime(value, '%m/%d/%Y')
        value = Date.new(date_hash[:year], date_hash[:mon], date_hash[:mday]) if date_hash
      end
      value
    end
	end
end
