require "aws_auditor"

module AwsAuditor
  describe AWSSDK do
    it "should raise error on no config for environment" do
      allow(YAML).to receive(:load_file).and_return({})
      expect{ AWSSDK::load_config }.to raise_error(AWSSDK::MissingEnvironment)
    end

    it "should get config" do
      config = {"staging" => {}}
      allow(YAML).to receive(:load_file).and_return(config)
      expect(AWSSDK::load_config).to eq(config["staging"])
    end

    it "should aws config for given environemnt" do
      config = {"staging" => {access_key_id: "foo", secret_access_key: "bar", region: "us-east-1"}}
      allow(YAML).to receive(:load_file).and_return(config)
      expect(AWSSDK::configuration('staging')).to be_an_instance_of(AWS::Core::Configuration)
    end
  end
end
