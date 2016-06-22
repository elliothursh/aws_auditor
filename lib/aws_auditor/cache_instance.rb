require_relative './instance_helper'

module AwsAuditor
  class CacheInstance
    extend InstanceHelper
    extend CacheWrapper

    class <<self
      attr_accessor :instances, :reserved_instances
    end

    attr_accessor :id, :name, :instance_type, :engine, :count
    def initialize(cache_instance)
      @id = cache_instance[:cache_cluster_id] || cache_instance[:reserved_cache_node_id]
      @name = cache_instance[:cache_cluster_id] || cache_instance[:reserved_cache_node_id]
      @instance_type = cache_instance[:cache_node_type]
      @engine = cache_instance[:engine] || cache_instance[:product_description]
      @count = cache_instance[:num_cache_nodes] || cache_instance[:cache_node_count]
    end

    def to_s
      "#{engine} #{instance_type}"
    end

    def self.get_instances
      return @instances if @instances
      @instances = cache.describe_cache_clusters[:cache_clusters].map do |instance|
        next unless instance[:cache_cluster_status].to_s == 'available'
        new(instance)
      end.compact
    end

    def self.get_reserved_instances
      return @reserved_instances if @reserved_instances
      @reserved_instances = cache.describe_reserved_cache_nodes[:reserved_cache_nodes].map do |instance|
        next unless instance[:state].to_s == 'active'
        new(instance)
      end.compact
    end

  end
end
