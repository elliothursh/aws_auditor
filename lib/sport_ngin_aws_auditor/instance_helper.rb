module SportNginAwsAuditor
  module InstanceHelper

    def instance_hash(client)
      Hash[get_instances(client).map { |instance| instance.nil? ? next : [instance.id, instance]}.compact]
    end

    def reserved_instance_hash(client)
      Hash[get_reserved_instances(client).map { |instance| instance.nil? ? next : [instance.id, instance]}.compact]
    end

    #################### ADDING DATA TO HASH ####################

    def instance_count_hash(instances)
      instance_hash = Hash.new()
      instances.each do |instance|
        next if instance.nil?
        instance_hash[instance.to_s] = instance_hash.has_key?(instance.to_s) ? instance_hash[instance.to_s] + instance.count : instance.count
      end if instances

      instance_hash.each do |key, value|
        instance_hash[key] = {:count => instance_hash[key], :region_based => false}
      end
      instance_hash
    end

    def add_region_ris_to_hash(ris_region, differences, klass)
      ris_region.each do |ri|
        differences.each do |key, value|
          # if key = 'Linux VPC us-east-1a t2.medium'...
          my_match = key.match(/(\w*\s*\w*\s*)\w{2}-\w{2,}-\w{2}(\s*\S*)/)

          # then platform = 'Linux VPC'...
          platform = my_match[1] if my_match
          platform[platform.length - 1] = ''

          # and size = 't2.medium'
          size = my_match[2] if my_match
          size[0] = ''

          if compare_platforms_based_on_klass(klass, platform, ri.platform) &&
             (size == ri.instance_type) &&
             (value[:count] < 0)
            until (ri.count == 0) || (value[:count] == 0)
              value[:count] = value[:count] + 1
              ri.count = ri.count - 1
            end
          end
        end
      end

      ris_region.each do |ri|
        differences[ri.to_s] = {:count => ri.count, :region_based => true}
      end
    end

    def add_additional_instances_to_hash(instances_to_add, instance_hash, extra_string)
      instances_to_add.each do |instance|
        next if instance.nil?
        key = "#{instance.to_s.dup}#{extra_string}#{instance.name})"
        instance_result = {}

        if instance_hash.has_key?(instance.to_s) && instance_hash[instance.to_s][:count] > 0
          current_val = instance_hash[instance.to_s][:count]
          val = current_val - instance.count
          new_val = val >= 0 ? val : 0
          instance_hash[instance.to_s][:count] = new_val

          val = instance.count - current_val
          new_val = val >= 0 ? val : 0
          instance_result[:count] = new_val
        else
          instance_result[:count] = instance.count
        end

        merged_hash = gather_hash(extra_string, instance)
        instance_result.merge!(merged_hash)

        instance_hash[key] = instance_result
      end if instances_to_add

      instance_hash
    end

    def gather_hash(extra_string, instance)
      if extra_string.include?("tag")
        {:name => instance.name, :tag_reason => instance.tag_reason,
         :tag_value => instance.tag_value, :region_based => false}
      elsif extra_string.include?("ignore")
        {:name => instance.name, :region_based => false}
      end
    end

    #################### PARSING AND COMPARING DATA ####################

    def sort_through_instances(instances, ignore_instances_regexes)
      ignored_instances, not_ignored_instances = filter_ignored_instances(instances, ignore_instances_regexes)
      instances_with_tag = filter_instances_with_tags(not_ignored_instances)
      instances_without_tag = filter_instances_without_tags(not_ignored_instances)
      instance_hash = instance_count_hash(instances_without_tag)
      return ignored_instances, instances_with_tag, instance_hash
    end

    def sort_through_RIs(client)
      ris = get_reserved_instances(client)
      ris_availability = filter_ris_availability_zone(ris)
      ris_region = filter_ris_region_based(ris)
      ris_hash = instance_count_hash(ris_availability)
      return ris_region, ris_hash
    end

    def measure_differences(instance_hash, ris_hash, ris_region, klass)
      differences = Hash.new()
      if /EC2/ =~ klass.name
        # Group all the same size RIs
        # Ex: ri_group_arr = [{ instance_type: "t2.medium", platform: "Linux VPC", count: 7 }, ...]
        ri_group_arr = []
        ris_region.each do |ec2_ri_obj|
          selected_ri_group = ri_group_arr.select { |ri_group| ri_group[:instance_type] == ec2_ri_obj.instance_type && ri_group[:platform] == ec2_ri_obj.platform  }
          if selected_ri_group.count == 1
            selected_ri_group = selected_ri_group.first
            selected_ri_group[:count] += ec2_ri_obj.count
          elsif selected_ri_group.empty?
            selected_ri_group = {
                                  instance_type: ec2_ri_obj.instance_type,
                                  platform: ec2_ri_obj.platform,
                                  count: ec2_ri_obj.count
                                }
            ri_group_arr << selected_ri_group
          else
            raise "More than one group with the same instance size and platform detected: #{selected_ri_group}"
          end
        end

        # Process each ri_group determined by instance_type and platform
        ri_group_arr.each do |ri_group|
          target_instance_type, target_platform, ri_count = ri_group[:instance_type], ri_group[:platform], ri_group[:count]
          actual_instances = instance_hash.select do |k,v|
            # Ex: k,v = "Linux VPC us-east-1d t2.small", {:count=>15, :region_based=>false}
            Regexp.new("^#{target_platform}.*#{target_instance_type}$") =~ k
          end

          actual_instances_count = actual_instances.reduce(0) do | previous_count, actual_instance |
            previous_count += actual_instance[1][:count]
          end

          actual_instances = {"#{target_platform} #{target_instance_type}" => {count: actual_instances_count, region_based: true}}

          # Three scenarios
          # 1. # of RIs > # of actual instances - unused RIs
          # 2. # of RIs == # of actual instances - matched
          # 3. # of RIs < # of actual instances - missing RIs
          actual_instances.values[0][:count] = ri_count - actual_instances.values[0][:count]
          differences.merge!(actual_instances)
        end
      else
        instance_hash.keys.concat(ris_hash.keys).uniq.each do |key|
          instance_count = instance_hash.has_key?(key) ? instance_hash[key][:count] : 0
          ris_count = ris_hash.has_key?(key) ? ris_hash[key][:count] : 0
          differences[key] = {:count => ris_count - instance_count, :region_based => false}
        end
      end
      differences
    end

    def add_additional_data(ris_region, instances_with_tag, ignored_instances, differences, klass)
      # EC2 region is processed in measure_differences
      add_region_ris_to_hash(ris_region, differences, klass) unless /EC2/ =~ klass.name
      add_additional_instances_to_hash(instances_with_tag, differences, " with tag (")
      add_additional_instances_to_hash(ignored_instances, differences, " ignored (")
      return differences
    end

    def compare(instances, ignore_instances_regexes, client, klass)
      ignored_instances, instances_with_tag, instance_hash = sort_through_instances(instances, ignore_instances_regexes)
      ris_region, ris_hash = sort_through_RIs(client)
      # TODO: Refactor this `measure_differences` method so that it uses ris_region for ec2
      # ris_region is empty for rds and cache, and ris_hash is empty for ec2
      differences = measure_differences(instance_hash, ris_hash, ris_region, klass)
      add_additional_data(ris_region, instances_with_tag, ignored_instances, differences, klass)
      differences
    end

    #################### FILTERING ACTIVE DATA ####################

    # assuming the value of the tag is in the form: 01/01/2000 like a date
    def filter_instances_with_tags(instances)
      instances.select do |instance|
        value = gather_instance_tag_date(instance)
        value && (Date.today.to_s < value.to_s)
      end
    end

    # assuming the value of the tag is in the form: 01/01/2000 like a date
    def filter_instances_without_tags(instances)
      instances.select do |instance|
        value = gather_instance_tag_date(instance)
        value.nil? || (Date.today.to_s >= value.to_s)
      end
    end

    # this gathers all RIs except the region-based RIs (For RDS and cache)
    def filter_ris_availability_zone(ris)
      ris.reject { |ri| ri.scope == 'Region' }
    end

    # this filters all of the region-based RIs (For EC2)
    def filter_ris_region_based(ris)
      ris.select { |ri| ri.scope == 'Region' }
    end

    # this breaks up the instances array into instances with any of the strings in the ignore_instances_regexes and
    # instances without
    def filter_ignored_instances(instances, ignore_instances_regexes)
      instances.partition { |instance|
        ignore_instances_regexes.any? { |regex|
          instance.name ? instance.name.match(regex) != nil : false
        }
      }
    end

    #################### GATHERING RETIRED DATA ####################

    # this gets all retired reserved instances and filters out only the ones that have expired
    # within the past week
    def get_recent_retired_reserved_instances(client)
      get_retired_reserved_instances(client).select do |ri|
        ri.expiration_date > (Time.now - 604800)
      end
    end

    # this returns a hash of all instances that have retired between 1 week ago and today
    def get_retired_tags(instances)
      return_array = []

      instances.select do |instance|
        value = gather_instance_tag_date(instance)
        one_week_ago = (Date.today - 7).to_s
        if (value && (one_week_ago < value.to_s) && (value.to_s <= Date.today.to_s))
          return_array << RecentlyRetiredTag.new(value.to_s, instance.to_s, instance.name, instance.tag_reason)
        end
      end

      return_array
    end

    def gather_instance_tag_date(instance)
      value = instance.no_reserved_instance_tag_value
      unless value.nil?
        date_hash = Date._strptime(value, '%m/%d/%Y')
        value = Date.new(date_hash[:year], date_hash[:mon], date_hash[:mday]) if date_hash
      end
      value
    end

    #################### HELPER METHODS ####################

    # If the klass is EC2, then just make sure the instance platform includes the RI platform because
    # classic RIs (non-VPC) are used on any instance.
    #
    # Instance  | RI        | Used?
    # ----------|-----------|------
    # Linux     | Linux     | Yes
    # Linux     | Linux VPC | No
    # Linux VPC | Linux     | Yes
    # Linux VPC | Linux VPC | Yes
    #
    # If the klass is not EC2, then the platforms must match as normal.
    def compare_platforms_based_on_klass(klass, platform, ri_platform)
      if klass =~ /EC2/
        platform.include?(ri_platform)
      else
        platform == ri_platform
      end
    end
  end
end
