require 'aws_auditor'

module AwsAuditor
  describe Config do
    context "Before loading a config file" do
      it "unset config key methods should return nil" do
        expect(AwsAuditor::Config.something).to eql(nil)
      end

      it "manually setting a key should create a corresponding method that returns the value" do
        AwsAuditor::Config.set_config_options(test: "something")
        expect(AwsAuditor::Config.test).to eql("something")
      end
    end

    context "after loading a config file" do
      before do
        config_file = {"domain"=>"example_domain", "slack"=>{"slack_option"=>true, "username"=>"Rspec Tester", "icon_url"=>"http://fake.url", "channel"=>"#test-channel", "webhook"=>"https://slack.web.hook"}}
        allow(YAML).to receive(:load_file).and_return(config_file)
        allow(File).to receive(:exist?).and_return(true)
        AwsAuditor::Config.load("dummy/path")
      end

      it "calling a method corresponding to a key in the file should return the value" do
        expect(AwsAuditor::Config.domain).to eql("example_domain")
        expect(AwsAuditor::Config.slack).to be_kind_of(Hash)
        expect(AwsAuditor::Config.slack[:slack_option]).to eql(true)
      end

      it "overwriting values should work" do
        expect(AwsAuditor::Config.slack).to be_kind_of(Hash)
        AwsAuditor::Config.set_config_options(slack: "this is a string now")
        expect(AwsAuditor::Config.slack).to eql("this is a string now")
      end
    end
  end
end
