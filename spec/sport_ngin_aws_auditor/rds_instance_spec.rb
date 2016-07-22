require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe RDSInstance do

    before :each do
      identity = double('identity', account: 123456789)
      client = double('client', get_caller_identity: identity)
      allow(Aws::STS::Client).to receive(:new).and_return(client)
    end

    after :each do
      RDSInstance.instance_variable_set("@instances", nil)
      RDSInstance.instance_variable_set("@reserved_instances", nil)
    end

    context "for normal rds_instances" do
      before :each do
        rds_instance1 = double('rds_instance', db_instance_identifier: "our-service",
                                               multi_az: false,
                                               db_instance_class: "db.t2.small",
                                               db_instance_status: "available",
                                               engine: "mysql",
                                               availability_zone: "us-east-1a",
                                               class: "Aws::RDS::Types::DBInstance")
        rds_instance2 = double('rds_instance', db_instance_identifier: "our-service",
                                               multi_az: false,
                                               db_instance_class: "db.m3.large",
                                               db_instance_status: "available",
                                               engine: "mysql",
                                               availability_zone: "us-east-1a",
                                               class: "Aws::RDS::Types::DBInstance")
        db_instances = double('db_instances', db_instances: [rds_instance1, rds_instance2])
        tag1 = double('tag', key: "cookie", value: "chocolate chip")
        tag2 = double('tag', key: "ice cream", value: "oreo")
        tags = double('tags', tag_list: [tag1, tag2])
        rds_client = double('rds_client', describe_db_instances: db_instances, list_tags_for_resource: tags)
        allow(RDSInstance).to receive(:rds).and_return(rds_client)
      end

      it "should make a rds_instance for each instance" do
        instances = RDSInstance.get_instances("tag_name")
        expect(instances.first).to be_an_instance_of(RDSInstance)
        expect(instances.last).to be_an_instance_of(RDSInstance)
      end

      it "should return an array of rds_instances" do
        instances = RDSInstance.get_instances("tag_name")
        expect(instances).not_to be_empty
        expect(instances.length).to eq(2)
      end

      it "should have proper variables set" do
        instances = RDSInstance.get_instances("tag_name")
        instance = instances.first
        expect(instance.id).to eq("our-service")
        expect(instance.multi_az).to eq("Single-AZ")
        expect(instance.instance_type).to eq("db.t2.small")
        expect(instance.engine).to eq("MySQL")
      end
    end

    context "for reserved_rds_instances" do
      before :each do
        reserved_rds_instance1 = double('reserved_rds_instance', reserved_db_instances_offering_id: "555te4yy-1234-555c-5678-thisisafake!!",
                                                                 multi_az: false,
                                                                 db_instance_class: "db.t2.small",
                                                                 state: "active",
                                                                 product_description: "oracle-se2 (byol)",
                                                                 db_instance_count: 1,
                                                                 class: "Aws::RDS::Types::ReservedDBInstance")
        reserved_rds_instance2 = double('reserved_rds_instance', reserved_db_instances_offering_id: "555te4yy-1234-555c-5678-thisisafake!!",
                                                                 multi_az: false,
                                                                 db_instance_class: "db.m3.large",
                                                                 state: "active",
                                                                 product_description: "postgresql",
                                                                 db_instance_count: 2,
                                                                 class: "Aws::RDS::Types::ReservedDBInstance")
        reserved_db_instances = double('db_instances', reserved_db_instances: [reserved_rds_instance1, reserved_rds_instance2])
        rds_client = double('rds_client', describe_reserved_db_instances: reserved_db_instances)
        allow(RDSInstance).to receive(:rds).and_return(rds_client)
      end

      it "should make a reserved_rds_instance for each instance" do
        reserved_instances = RDSInstance.get_reserved_instances
        expect(reserved_instances.first).to be_an_instance_of(RDSInstance)
        expect(reserved_instances.last).to be_an_instance_of(RDSInstance)
      end

      it "should return an array of reserved_rds_instances" do
        reserved_instances = RDSInstance.get_reserved_instances
        expect(reserved_instances).not_to be_empty
        expect(reserved_instances.length).to eq(2)
      end

      it "should have proper variables set" do
        reserved_instances = RDSInstance.get_reserved_instances
        reserved_instance = reserved_instances.first
        expect(reserved_instance.id).to eq("555te4yy-1234-555c-5678-thisisafake!!")
        expect(reserved_instance.multi_az).to eq("Single-AZ")
        expect(reserved_instance.instance_type).to eq("db.t2.small")
        expect(reserved_instance.engine).to eq("Oracle SE Two")
      end
    end

    context "for returning pretty string formats" do
      it "should return a string version of the name of the reserved_rds_instance" do
        reserved_rds_instance = double('reserved_rds_instance', reserved_db_instances_offering_id: "555te4yy-1234-555c-5678-thisisafake!!",
                                                                multi_az: false,
                                                                db_instance_class: "db.t2.small",
                                                                state: "active",
                                                                product_description: "mysql",
                                                                db_instance_count: 3,
                                                                class: "Aws::RDS::Types::ReservedDBInstance")
        reserved_db_instances = double('db_instances', reserved_db_instances: [reserved_rds_instance])
        rds_client = double('rds_client', describe_reserved_db_instances: reserved_db_instances)
        allow(RDSInstance).to receive(:rds).and_return(rds_client)
        reserved_instances = RDSInstance.get_reserved_instances
        reserved_instance = reserved_instances.first
        expect(reserved_instance.to_s).to eq("MySQL Single-AZ db.t2.small")
      end

      it "should return a string version of the name of the rds_instance" do
        rds_instance = double('rds_instance', db_instance_identifier: "our-service",
                                              multi_az: false,
                                              db_instance_class: "db.t2.small",
                                              db_instance_status: "available",
                                              engine: "postgres",
                                              availability_zone: "us-east-1a",
                                              class: "Aws::RDS::Types::DBInstance")
        db_instances = double('db_instances', db_instances: [rds_instance])
        tag1 = double('tag', key: "cookie", value: "chocolate chip")
        tag2 = double('tag', key: "ice cream", value: "oreo")
        tags = double('tags', tag_list: [tag1, tag2])
        rds_client = double('rds_client', describe_db_instances: db_instances, list_tags_for_resource: tags)
        allow(RDSInstance).to receive(:rds).and_return(rds_client)
        instances = RDSInstance.get_instances("tag_name")
        instance = instances.first
        expect(instance.to_s).to eq("PostgreSQL Single-AZ db.t2.small")
      end
    end
  end
end
