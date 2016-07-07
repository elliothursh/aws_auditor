require 'spec_helper'
require 'sport_ngin_aws_auditor'

module SportNginAwsAuditor
  describe Config do

    context "config key methods" do
      it "should return nil when not set" do
        expect(SportNginAwsAuditor::Config.doesnt_exist).to eql(nil)
        expect(SportNginAwsAuditor::Config.doesnt_exist?).to eql(false)
      end
      it "should return the config value when set" do
        SportNginAwsAuditor::Config.new_value = "testing"
        expect(SportNginAwsAuditor::Config.new_value).to eql("testing")
      end
    end

    context "after loading a config file" do
      before do
        config_file = {"domain" => "example_domain",
                       "slack" => {"slack_option" => true,
                                   "username" => "Rspec Tester",
                                   "icon_url" => "http://fake.url",
                                   "channel" => "#test-channel",
                                   "webhook" => "https://slack.web.hook"}}
        allow(YAML).to receive(:load_file).and_return(config_file)
        allow(File).to receive(:exist?).and_return(true)
        SportNginAwsAuditor::Config.load("dummy/path")
      end

      it "calling a method corresponding to a key in the file should return the value" do
        expect(SportNginAwsAuditor::Config.domain).to eql("example_domain")
        expect(SportNginAwsAuditor::Config.slack).to be_kind_of(Hash)
        expect(SportNginAwsAuditor::Config.slack[:slack_option]).to eql(true)
      end

      it "overwriting values should work" do
        expect(SportNginAwsAuditor::Config.slack).to be_kind_of(Hash)
        SportNginAwsAuditor::Config.slack = "this is a string now"
        expect(SportNginAwsAuditor::Config.slack).to eql("this is a string now")
      end
    end
  end
end
