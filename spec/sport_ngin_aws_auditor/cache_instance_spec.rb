require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe CacheInstance do

    before :each do
      identity = double('identity', account: 123456789)
      client = double('client', get_caller_identity: identity)
      allow(Aws::STS::Client).to receive(:new).and_return(client)
    end

    after :each do
      CacheInstance.instance_variable_set("@instances", nil)
      CacheInstance.instance_variable_set("@reserved_instances", nil)
    end

    context "for normal cache_instances" do
      before :each do
        cache_instance1 = double('cache_instance', cache_cluster_id: "job-queue-cluster",
                                                   cache_node_type: "cache.t2.small",
                                                   engine: "redis",
                                                   cache_cluster_status: "available",
                                                   num_cache_nodes: 1,
                                                   preferred_availability_zone: "us-east-1d",
                                                   class: "Aws::ElastiCache::Types::CacheCluster")
        cache_instance2 = double('cache_instance', cache_cluster_id: "job-queue-cluster",
                                                   cache_node_type: "cache.t2.medium",
                                                   engine: "mysql",
                                                   cache_cluster_status: "available",
                                                   num_cache_nodes: 1,
                                                   preferred_availability_zone: "us-east-1d",
                                                   class: "Aws::ElastiCache::Types::CacheCluster")
        cache_clusters = double('cache_cluster', cache_clusters: [cache_instance1, cache_instance2])
        tag1 = double('tag', key: "cookie", value: "chocolate chip")
        tag2 = double('tag', key: "ice cream", value: "oreo")
        tags = double('tags', tag_list: [tag1, tag2])
        cache_client = double('cache_client', describe_cache_clusters: cache_clusters, list_tags_for_resource: tags)
        allow(CacheInstance).to receive(:cache).and_return(cache_client)
      end

      it "should make a cache_instance for each instance" do
        instances = CacheInstance.get_instances("tag_name")
        expect(instances.first).to be_an_instance_of(CacheInstance)
        expect(instances.last).to be_an_instance_of(CacheInstance)
      end

      it "should return an array of cache_instances" do
        instances = CacheInstance.get_instances("tag_name")
        expect(instances).not_to be_empty
        expect(instances.length).to eq(2)
      end

      it "should have proper variables set" do
        instances = CacheInstance.get_instances("tag_name")
        instance = instances.first
        expect(instance.id).to eq("job-queue-cluster")
        expect(instance.name).to eq("job-queue-cluster")
        expect(instance.instance_type).to eq("cache.t2.small")
        expect(instance.engine).to eq("redis")
      end
    end

    context "for reserved_cache_instances" do
      before :each do
        reserved_cache_instance1 = double('reserved_cache_instance', reserved_cache_node_id: "job-queue-cluster",
                                                                     cache_node_type: "cache.t2.small",
                                                                     product_description: "redis",
                                                                     state: "active",
                                                                     cache_node_count: 1,
                                                                     class: "Aws::ElastiCache::Types::ReservedCacheNode")
        reserved_cache_instance2 = double('reserved_cache_instance', reserved_cache_node_id: "job-queue-cluster",
                                                                     cache_node_type: "cache.t2.medium",
                                                                     product_description: "mysql",
                                                                     state: "active",
                                                                     cache_node_count: 1,
                                                                     class: "Aws::ElastiCache::Types::ReservedCacheNode")
        reserved_cache_nodes = double('cache_cluster', reserved_cache_nodes: [reserved_cache_instance1, reserved_cache_instance2])
        cache_client = double('cache_client', describe_reserved_cache_nodes: reserved_cache_nodes)
        allow(CacheInstance).to receive(:cache).and_return(cache_client)
      end

      it "should make a reserved_cache_instance for each instance" do
        reserved_instances = CacheInstance.get_reserved_instances
        expect(reserved_instances.first).to be_an_instance_of(CacheInstance)
        expect(reserved_instances.last).to be_an_instance_of(CacheInstance)
      end

      it "should return an array of reserved_cache_instances" do
        reserved_instances = CacheInstance.get_reserved_instances
        expect(reserved_instances).not_to be_empty
        expect(reserved_instances.length).to eq(2)
      end

      it "should have proper variables set" do
        reserved_instances = CacheInstance.get_reserved_instances
        reserved_instance = reserved_instances.first
        expect(reserved_instance.id).to eq("job-queue-cluster")
        expect(reserved_instance.name).to eq("job-queue-cluster")
        expect(reserved_instance.instance_type).to eq("cache.t2.small")
        expect(reserved_instance.engine).to eq("redis")
      end
    end

    context "for returning pretty string formats" do
      it "should return a string version of the name of the cache_instance" do
        cache_instance = double('cache_instance', cache_cluster_id: "job-queue-cluster",
                                                  cache_node_type: "cache.t2.small",
                                                  engine: "redis",
                                                  cache_cluster_status: "available",
                                                  num_cache_nodes: 1,
                                                  preferred_availability_zone: "us-east-1d",
                                                  class: "Aws::ElastiCache::Types::CacheCluster")
        cache_clusters = double('cache_cluster', cache_clusters: [cache_instance])
        tag1 = double('tag', key: "cookie", value: "chocolate chip")
        tag2 = double('tag', key: "ice cream", value: "oreo")
        tags = double('tags', tag_list: [tag1, tag2])
        cache_client = double('cache_client', describe_cache_clusters: cache_clusters, list_tags_for_resource: tags)
        allow(CacheInstance).to receive(:cache).and_return(cache_client)
        instances = CacheInstance.get_instances("tag_name")
        instance = instances.first
        expect(instance.to_s).to eq("Redis cache.t2.small")
      end
    end
  end
end
