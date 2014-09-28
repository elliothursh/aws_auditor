require_relative './instance_helper'

module AwsAuditor
  class CacheInstance
    extend InstanceHelper
    extend CacheWrapper

    attr_accessor :id, :name, :instance_type, :engine, :count
    def initialize(cache_instance)
      @id = cache_instance[:cache_cluster_id] || cache_instance[:reserved_cache_node_id]
      @name = cache_instance[:cache_cluster_id] || cache_instance[:reserved_cache_node_id]
      @instance_type = cache_instance[:cache_node_type]
      @engine = cache_instance[:engine] || cache_instance[:product_description]
      @count = cache_instance[:cache_node_count] || 1
    end

    def to_s
      "#{engine} #{instance_type}"
    end

    def self.get_instances
      instances = cache.describe_cache_clusters[:cache_clusters]
      instances.map do |instance|
        next unless instance[:cache_cluster_status].to_s == 'available'
        new(instance)
      end if instances
    end

    def self.get_reserved_instances
      instances = cache.describe_reserved_cache_nodes[:reserved_db_instances]
      instances.map do |instance|
        next unless instance[:state].to_s == 'active'
        new(instance)
      end if instances
    end

  end
end