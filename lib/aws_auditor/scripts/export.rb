require 'csv'
require_relative "../google"

module AwsAuditor
  module Scripts
    class Export
      extend GoogleWrapper
      extend AWSWrapper

      class <<self
        attr_accessor :ec2_instances, :rds_instances, :cache_instances, :options, :file, :keys_hash, :environment
      end

      CLASS_TYPES = %w[EC2Instance RDSInstance CacheInstance]

      def self.execute(environment, options = nil)
        @environment = environment
        (puts "Must specify either --drive or --csv"; exit) unless options[:csv] || options[:drive]
        aws(environment)
        print "Gathering info, please wait..."
        all_keys = get_all_keys
        all_info = prepare
        print "\r" + " " * 50 + "\r"

        create_csv(all_keys,all_info) if options[:csv]
        upload_to_drive(all_keys,all_info) if options[:drive]
      end

      def self.create_csv(keys, info)
        CSV.open("#{environment}.csv", "wb") do |csv|
          csv << ["name",keys].flatten
          info.each do |hash|
            csv << all_keys_hash.merge(hash).values
          end
        end

        `open "#{environment}.csv"`
      end

      def self.upload_to_drive(keys, info)
        @file = GoogleSheet.new(Google.file[:name], Google.file[:path], environment)
        file.write_header(keys)
        info.each do |value_hash|
          response = file.worksheet.list.push(value_hash)
          puts response unless response.is_a? GoogleDrive::ListRow
        end
        file.worksheet.save

        `open #{file.sheet.human_url}`
      end

      def self.prepare
        [get_all_arrays,get_all_counts].flatten
      end

      def self.get_all_keys
        return @keys if @keys
        @keys = [
          ec2_instances.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase },
          rds_instances.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase },
          cache_instances.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase }
        ].flatten
      end

      def self.all_keys_hash(name = nil, value = nil)
        return @keys_hash if @keys_hash && @keys_hash[:name] == name
        @keys_hash = {:name => name}
        get_all_keys.each{ |key| @keys_hash[key] = value }
        @keys_hash
      end

      def self.get_all_arrays
        return @all_array if @all_array
        @all_array = [ec2_array,rds_array,cache_array].flatten
      end

      def self.ec2_array
        instance_array = [{name: "OPSWORKS"}]
        EC2Instance.bucketize.map do |stack_name, stack_instances|
          instance_array << {:name => stack_name}.merge(EC2Instance.instance_count_hash(stack_instances))
        end
        instance_array
      end

      def self.rds_array
        instance_array = [{name: "RDS"}]
        rds_instances.each do |db_name, db|
          instance_array << Hash({:name => db_name, "#{db.to_s}" => "#{db.count}"})
        end
        instance_array
      end

      def self.cache_array
        instance_array = [{name: "CACHE"}]
        cache_instances.each do |cache_name, cache|
          instance_array << Hash({:name => cache_name, "#{cache.to_s}" => "#{cache.count}"})
        end
        instance_array
      end

      def self.get_all_counts
        total_array = [{:name => "TOTALS"}]
        total_array << all_keys_hash("Running Instances").merge(counts(:instance => true))
        total_array << all_keys_hash("Reserved Instances", 0).merge(counts(:reserved => true))
        total_array << all_keys_hash("Differences").merge(counts(:compare => true))
      end

      def self.counts(options = {:instance => false, :reserved => false, :compare => false })
        CLASS_TYPES.map do |class_type|
          klass = AwsAuditor.const_get(class_type)
          instances = klass.instance_count_hash(klass.get_instances) if options[:instance]
          instances = klass.instance_count_hash(klass.get_reserved_instances) if options[:reserved]
          instances = klass.compare if options[:compare]
          instances
        end.inject(:merge)
      end

      def self.ec2_instances
        @ec2_instances ||= EC2Instance.instance_hash
      end

      def self.rds_instances
        @rds_instances ||= RDSInstance.instance_hash
      end

      def self.cache_instances
        @cache_instances ||= CacheInstance.instance_hash
      end

    end
  end
end