require_relative "../google"

module AwsAuditor
	module Scripts
		class Export
			extend GoogleWrapper
			extend AWSWrapper

			def self.execute(environment, options = nil)
				aws(environment)
				file = GoogleSheet.new(Google.file[:name], Google.file[:path], environment)
				file.write_header(get_all_keys)
				write_opsworks_stacks(file)
				write_rds(file)
				write_cache(file)
				write_totals(file)
				`open #{file.sheet.human_url}`
			end

			def self.write_opsworks_stacks(file)
				file.write_row({name: "EC2"})
				opsworks_stacks.each do |stack|
					next if stack.instances.empty?
					value_hash = EC2Instance.instance_count_hash(stack.instances)
					value_hash[:name] = stack.name
					file.write_row(value_hash)
				end
			end

			def self.write_rds(file)
				file.write_row({name: "RDS"})
				rds_instances.each do |db|
					value_hash = Hash({:name => db.name, :"#{db.to_s}" => '1'})
					file.write_row(value_hash)
				end
			end

			def self.write_cache(file)
				file.write_row({name: "CACHE"})
				cache_instances.each do |cache|
					value_hash = Hash({:name => cache.name, :"#{cache.to_s}" => '1'})
				 	file.write_row(value_hash)
				end
			end

			def self.write_totals(file)
				file.write_row({name: "TOTALS"})
				instance_counts = get_all_instance_counts.merge({name: "Running Instances"})
				file.write_row(instance_counts)
				reserved_counts = get_all_reserved_counts.merge({name: "Reserved Instances"})
				file.write_row(reserved_counts)
				differences = get_difference_counts.merge({name: "Differences"})
				file.write_row(differences)
			end

			def self.get_all_keys
				ec2 = EC2Instance.instance_hash.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase }
				rds = RDSInstance.instance_hash.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase }
				cache = CacheInstance.instance_hash.values.map{ |x| x.to_s }.uniq.sort! { |a,b| a.downcase <=> b.downcase }
				ec2.concat(rds).concat(cache).compact
			end

			def self.get_all_instance_counts
				ec2 = EC2Instance.instance_count_hash(EC2Instance.get_instances)
				rds = RDSInstance.instance_count_hash(RDSInstance.get_instances)
				cache = CacheInstance.instance_count_hash(CacheInstance.get_instances)
				ec2.merge(rds).merge(cache)
			end

			def self.get_all_reserved_counts
				ec2 = EC2Instance.instance_count_hash(EC2Instance.get_reserved_instances)
				rds = RDSInstance.instance_count_hash(RDSInstance.get_reserved_instances)
				cache = CacheInstance.instance_count_hash(CacheInstance.get_reserved_instances)
				ec2.merge(rds).merge(cache)
			end

			def self.get_difference_counts
				ec2 = EC2Instance.compare
				rds = RDSInstance.compare
				cache = CacheInstance.compare
				ec2.merge(rds).merge(cache)
			end

			def self.opsworks_stacks
				@opsworks_stacks ||= Stack.all
			end

			def self.rds_instances
				@rds_instances ||= RDSInstance.get_instances
			end

			def self.cache_instances
				@cache_instances ||= CacheInstance.get_instances
			end

		end
	end
end