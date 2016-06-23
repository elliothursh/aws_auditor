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
        instance_hash[key] = instance_hash.has_key?(key) ? instance_hash[key] + 1 : 1
      end if instances_to_add
      instance_hash
    end

    def compare(tag_name)
      date = get_todays_date
      differences = Hash.new()
      instances = get_instances(tag_name)
      instances_with_tag = filter_instances_with_tags(instances, date).first
      instances_without_tag = filter_instances_with_tags(instances, date).last
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

    def filter_instances_with_tags(instances, date)
      instances_with_tag = instances.select do |instance|
        value = instance.no_reserved_instance_tag_value
        value && (date < value)
      end

      instances_without_tag = instances.select do |instance|
        value = instance.no_reserved_instance_tag_value
        !value || (date <= value)
      end

      [instances_with_tag, instances_without_tag]
    end

    def get_todays_date
      time = Time.new
      month = time.month.to_s.length == 1 ? "0" << time.month.to_s : time.month.to_s
      day = time.day.to_s.length == 1 ? "0" << time.day.to_s : time.day.to_s
      year = time.year.to_s
      date = month << "/" << day << "/" << year
      date
    end
	end
end
