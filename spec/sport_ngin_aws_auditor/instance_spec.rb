require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe Instance do
    it "should make a reserved instance with proper attributes" do
      instance = Instance.new("Windows VPC us-east-1e m1.large", 4)
      expect(instance).to be_an_instance_of(Instance)
      expect(instance.type).to eq("reserved")
      expect(instance.count).to eq(4)
      expect(instance.tagged?).to eq(false)
      expect(instance.reserved?).to eq(true)
    end

    it "should make a running instance with proper attributes" do
      instance = Instance.new("Windows VPC us-east-1e m1.large", -1)
      expect(instance).to be_an_instance_of(Instance)
      expect(instance.type).to eq("running")
      expect(instance.count).to eq(-1.abs)
    end

    it "should make an instance with a tag with proper attributes" do
      instance = Instance.new("Windows VPC us-east-1e m1.large with tag", 4)
      expect(instance).to be_an_instance_of(Instance)
      expect(instance.type).to eq("tagged")
      expect(instance.count).to eq(4)
      expect(instance.tagged?).to eq(true)
      expect(instance.running?).to eq(false)
    end
  end
end
