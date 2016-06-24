require "aws_auditor"

module AwsAuditor
  describe AWSSDK do
    it "should be a hash that contains a region" do
      expect(AWSSDK::authenticate('staging')).to include(:region)
    end

    it "should be a hash that contains credentials" do
      expect(AWSSDK::authenticate('staging')).to include(:credentials)
    end

    it "should receive new Aws::SharedCredentials" do
      expect(Aws::SharedCredentials).to receive(:new).with(profile_name: 'staging')
      AWSSDK::authenticate('staging')
    end

    it "should update configs" do
      coffee_types = {:coffee => "cappuccino", :beans => "arabica"}
      allow(Aws::SharedCredentials).to receive(:new).and_return(coffee_types)
      expect(Aws.config).to receive(:update).with({region: 'us-east-1', credentials: coffee_types})
      AWSSDK::authenticate('staging')
    end
  end
end
